defmodule OliWeb.Curriculum.Container do
  @moduledoc """
  LiveView implementation of a container editor.
  """

  use Phoenix.LiveView, layout: {OliWeb.LayoutView, "live.html"}

  alias Oli.Authoring.Editing.ContainerEditor
  alias Oli.Authoring.Course
  alias OliWeb.Curriculum.{Rollup, ActivityDelta, DropTarget, Entry}
  alias Oli.Resources
  alias Oli.Resources.{ScoringStrategy, Revision}
  alias Oli.Publishing.AuthoringResolver
  alias Oli.Accounts.Author
  alias Oli.Repo
  alias Oli.Publishing
  alias Oli.Accounts
  alias Oli.Authoring.Broadcaster.Subscriber
  alias Oli.Resources.Numbering
  alias OliWeb.Router.Helpers, as: Routes

  # Resources currently being edited by an author (has a lock present)
  # : %{ resource_id => author }
  def get_resources_being_edited(resource_ids, project_id) do
    project_id
    |> Publishing.get_unpublished_publication_id!()
    |> (&Publishing.retrieve_lock_info(resource_ids, &1)).()
    |> Enum.map(fn published_resource ->
      {published_resource.resource_id, published_resource.author}
    end)
    |> Enum.into(%{})
  end

  def mount(
        %{"project_id" => project_slug, "container_slug" => container_slug},
        %{"current_author_id" => author_id},
        socket
      ) do
    project = Course.get_project_by_slug(project_slug)
    container = AuthoringResolver.from_revision_slug(project.slug, container_slug)
    children =
      ContainerEditor.list_all_container_children(container, project)
      |> Repo.preload([:resource, :author])

    {:ok, rollup} = Rollup.new(children, project.slug)

    subscriptions = subscribe(container, children, rollup, project.slug)

    {:ok,
     assign(socket,
       children: children,
       active: :curriculum,
       breadcrumbs: [{"Curriculum", nil}],
       rollup: rollup,
       changeset: Resources.change_revision(%Revision{}),
       container: container,
       project: project,
       subscriptions: subscriptions,
       author: Repo.get(Author, author_id),
       view: "Simple",
       selected: nil,
       resources_being_edited: get_resources_being_edited(container.children, project.id),
       numbering: Numbering.number_full_tree(
         AuthoringResolver.root_container(project_slug),
         Numbering.fetch_hierarchy(project_slug))
     )}
  end

  def handle_params(%{ "view" => view }, _, socket), do: {:noreply, assign(socket, view: view)}
  def handle_params(_, _, socket), do: {:noreply, socket}

  # spin up subscriptions for the container and for all of its children, activities and attached objectives
  defp subscribe(
         container,
         children,
         %Rollup{activity_map: activity_map, objective_map: objective_map},
         project_slug
       ) do
    Enum.each(children, fn child ->
      Subscriber.subscribe_to_locks_acquired(child.resource_id)
      Subscriber.subscribe_to_locks_released(child.resource_id)
    end)

    activity_ids = Enum.map(activity_map, fn {id, _} -> id end)
    objective_ids = Enum.map(objective_map, fn {id, _} -> id end)

    ids = [container.resource_id] ++ Enum.map(children, fn c -> c.resource_id end) ++ activity_ids ++ objective_ids

    Enum.each(ids, fn id ->
      Subscriber.subscribe_to_new_revisions_in_project(id, project_slug)
    end)

    Subscriber.subscribe_to_new_resources_of_type(Oli.Resources.ResourceType.get_id_by_type("objective"), project_slug)

    ids
  end

  # release a collection of subscriptions
  defp unsubscribe(ids, children, project_slug) do
    Subscriber.unsubscribe_to_new_resources_of_type(Oli.Resources.ResourceType.get_id_by_type("objective"), project_slug)
    Enum.each(ids, & Subscriber.unsubscribe_to_new_revisions_in_project(&1, project_slug))
    Enum.each(children, fn child ->
      Subscriber.unsubscribe_to_locks_acquired(child.resource_id)
      Subscriber.unsubscribe_to_locks_released(child.resource_id)
    end)
  end

  # handle change of selection
  def handle_event("select", %{"slug" => slug}, socket) do
    selected = Enum.find(socket.assigns.children, fn r -> r.slug == slug end)
    {:noreply, assign(socket, :selected, selected)}
  end

  # process form submission to save page settings
  def handle_event("save", params, socket) do
    IO.inspect("here")
    params =
      Enum.reduce(params, %{}, fn {k, v}, m ->
        case MapSet.member?(MapSet.new(["_csrf_token", "_target"]), k) do
          true -> m
          false -> Map.put(m, String.to_existing_atom(k), v)
        end
      end)

    socket =
      case ContainerEditor.edit_page(socket.assigns.project, socket.assigns.selected.slug, params) do
        {:ok, _} ->
          socket

        {:error, _} ->
          socket
          |> put_flash(:error, "Could not edit page")
      end

    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => key, "shiftKey" => shiftKeyPressed?} = params, socket) do
    focused_index =
      case params["index"] do
        nil -> nil
        stringIndex -> String.to_integer(stringIndex)
      end

    last_index = length(socket.assigns.children) - 1
    children = socket.assigns.children

    case {focused_index, key, shiftKeyPressed?} do
      {nil, _, _} ->
        {:noreply, socket}

      {^last_index, "ArrowDown", _} ->
        {:noreply, socket}

      {0, "ArrowUp", _} ->
        {:noreply, socket}

      # Each drop target has a corresponding entry after it with a matching index.
      # That means that the "drop index" is the index of where you'd like to place the item AHEAD OF
      # So to reorder an item below its current position, we add +2 ->
      # +1 would mean insert it BEFORE the next item, but +2 means insert it before the item after the next item.
      # See the logic in container editor that does the adjustment based on the positions of the drop targets.
      {focused_index, "ArrowDown", true} ->
        handle_event(
          "reorder",
          %{
            "sourceIndex" => Integer.to_string(focused_index),
            "dropIndex" => Integer.to_string(focused_index + 2)
          },
          socket
        )

      {focused_index, "ArrowUp", true} ->
        handle_event(
          "reorder",
          %{
            "sourceIndex" => Integer.to_string(focused_index),
            "dropIndex" => Integer.to_string(focused_index - 1)
          },
          socket
        )

      {focused_index, "Enter", _} ->
        {:noreply, assign(socket, :selected, Enum.at(children, focused_index))}

      {_, _, _} ->
        {:noreply, socket}
    end
  end

  # handle reordering event
  def handle_event("reorder", %{"sourceIndex" => source_index, "dropIndex" => index}, socket) do
    source = Enum.at(socket.assigns.children, String.to_integer(source_index))

    socket =
      case ContainerEditor.reorder_child(
             socket.assigns.project,
             socket.assigns.author,
             source.slug,
             String.to_integer(index)
           ) do
        {:ok, _} ->
          socket

        {:error, _} ->
          socket
          |> put_flash(:error, "Could not edit page")
      end

    {:noreply, socket}
  end

  # handle processing deletion of currently selected item
  def handle_event("delete", _, socket) do
    socket =
      case ContainerEditor.remove_child(
             socket.assigns.project,
             socket.assigns.author,
             socket.assigns.selected.slug
           ) do
        {:ok, _} ->
          socket

        {:error, _} ->
          socket
          |> put_flash(:error, "Could not remove page")
      end

    {:noreply, socket}
  end

  # handle clicking of the "Add Graded Assessment" or "Add Practice Page" buttons
  def handle_event("add", %{"type" => type}, socket) do
    attrs = %{
      objectives: %{"attached" => []},
      children: [],
      content: %{"model" => []},
      title:
        case type do
          "Scored" -> "New Assessment"
          "Unscored" -> "New Page"
          "Container" -> "New Grouping"
        end,
      graded:
        case type do
          "Scored" -> true
          "Unscored" -> false
          "Container" -> false
        end,
      max_attempts:
        case type do
          "Scored" -> 5
          "Unscored" -> 0
          "Container" -> nil
        end,
      recommended_attempts:
        case type do
          "Scored" -> 5
          "Unscored" -> 0
          "Container" -> nil
        end,
      scoring_strategy_id:
        case type do
          "Scored" -> ScoringStrategy.get_id_by_type("best")
          "Unscored" -> ScoringStrategy.get_id_by_type("best")
          "Container" -> nil
        end,
      resource_type_id:
        case type do
          "Scored" -> Oli.Resources.ResourceType.get_id_by_type("page")
          "Unscored" -> Oli.Resources.ResourceType.get_id_by_type("page")
          "Container" -> Oli.Resources.ResourceType.get_id_by_type("container")
        end
    }

    socket =
      case ContainerEditor.add_new(
             socket.assigns.container,
             attrs,
             socket.assigns.author,
             socket.assigns.project
           ) do
        {:ok, _} ->
          socket

        {:error, %Ecto.Changeset{} = _changeset} ->
          socket
          |> put_flash(:error, "Could not create new item")
      end

    {:noreply, assign(socket,
      numbering: Numbering.number_full_tree(
        AuthoringResolver.root_container(socket.assigns.project.slug),
        Numbering.fetch_hierarchy(socket.assigns.project.slug))
    )}
  end

  def handle_event("change-view", %{"view" => view}, socket) do
    {:noreply, push_patch(socket, to: Routes.live_path(
      socket,
      OliWeb.Curriculum.Container,
      socket.assigns.project.slug,
      socket.assigns.container.slug,
      %{ view: view }))}
  end

  def active_class(active_view, view) do
    if active_view == view do
      " active"
    else
      ""
    end
  end

  defp has_renderable_change?(page1, page2) do
    page1.title != page2.title or
      page1.graded != page2.graded or
      page1.max_attempts != page2.max_attempts or
      page1.scoring_strategy_id != page2.scoring_strategy_id
  end

  # We need to monitor for changes in the title of an objective
  defp handle_updated_objective(socket, revision) do
    assign(socket, rollup: Rollup.objective_updated(socket.assigns.rollup, revision))
  end

  # We need to monitor for changes in the title of an objective
  defp handle_updated_activity(socket, revision) do
    assign(socket,
      rollup:
        Rollup.activity_updated(socket.assigns.rollup, revision, socket.assigns.project.slug)
    )
  end

  defp handle_updated_page(socket, revision) do
    id = revision.resource_id

    old_page =
      Enum.find(socket.assigns.children, fn p -> p.resource_id == revision.resource_id end)

    # check to see if the activities in that page have changed since our last view of it
    {:ok, activities_delta} = ActivityDelta.new(revision, old_page)

    # We only track this update if it affects our rendering.  So we check to see if the
    # title or settings has changed of if the activities in this page haven't been added/removed
    if has_renderable_change?(old_page, revision) or
         ActivityDelta.have_activities_changed?(activities_delta) do
      # we splice that page into its location
      children =
        case Enum.find_index(socket.assigns.children, fn p -> p.resource_id == id end) do
          nil -> socket.assigns.children
          index -> List.replace_at(socket.assigns.children, index, revision)
        end

      # update our selection to reflect the latest model
      selected =
        case socket.assigns.selected do
          nil -> nil
          s -> Enum.find(children, fn r -> r.resource_id == s.resource_id end)
        end

      # update the relevant maps that allow us to show roll ups
      rollup =
        Rollup.page_updated(
          socket.assigns.rollup,
          revision,
          activities_delta,
          socket.assigns.project.slug
        )

      assign(socket, selected: selected, children: children, rollup: rollup)
    else
      socket
    end
  end

  defp handle_updated_container(socket, revision) do
    # in the case of a change to the container, we simplify by just pulling a new view of
    # the container and its contents. This handles addition, removal, reordering from the
    # local user as well as a collaborator
    IO.inspect(revision.children, label: "Revision children")
    children =
      ContainerEditor.list_all_container_children(revision, socket.assigns.project)
      |> Repo.preload([:resource, :author])
    IO.inspect(Enum.map(children, & {&1.resource_id, &1.title}), label: "new children")

    {:ok, rollup} = Rollup.new(children, socket.assigns.project.slug)

    numbering = Numbering.number_full_tree(
      AuthoringResolver.root_container(socket.assigns.project.slug),
      Numbering.fetch_hierarchy(socket.assigns.project.slug))

    selected =
      case socket.assigns.selected do
        nil -> nil
        s -> Enum.find(children, fn r -> r.resource_id == s.resource_id end)
      end

    assign(socket, selected: selected, container: revision, children: children, rollup: rollup, numbering: numbering)
  end

  # Here we respond to notifications for edits made
  # to the container or to its child children, contained activities and attached objectives
  def handle_info({:updated, revision, _}, socket) do
    socket =
      case Oli.Resources.ResourceType.get_type_by_id(revision.resource_type_id) do
        "activity" -> handle_updated_activity(socket, revision)
        "objective" -> handle_updated_objective(socket, revision)
        "page" -> handle_updated_page(socket, revision)
        "container" -> handle_updated_container(socket, revision)
      end

    # redo all subscriptions
    unsubscribe(socket.assigns.subscriptions, socket.assigns.children, socket.assigns.project.slug)

    subscriptions =
      subscribe(
        socket.assigns.container,
        socket.assigns.children,
        socket.assigns.rollup,
        socket.assigns.project.slug
      )

    {:noreply, assign(socket, subscriptions: subscriptions)}
  end

  # listens for creation of new objectives
  def handle_info({:new_resource, revision, _}, socket) do
    # include it in our objective map
    rollup = Rollup.objective_updated(socket.assigns.rollup, revision)

    # now listen to it for future edits
    Subscriber.subscribe_to_new_revisions_in_project(revision.resource_id, socket.assigns.project.slug)

    subscriptions = [revision.resource_id | socket.assigns.subscriptions]

    {:noreply, assign(socket, rollup: rollup, subscriptions: subscriptions)}
  end

  def handle_info(
        {:lock_acquired, resource_id, author_id},
        %{assigns: %{resources_being_edited: resources_being_edited}} = socket
      ) do
    author = Accounts.get_user!(author_id)
    new_resources_being_edited = Map.put(resources_being_edited, resource_id, author)
    {:noreply, assign(socket, resources_being_edited: new_resources_being_edited)}
  end

  def handle_info(
        {:lock_released, resource_id},
        %{assigns: %{resources_being_edited: resources_being_edited}} = socket
      ) do
    new_resources_being_edited = Map.delete(resources_being_edited, resource_id)
    {:noreply, assign(socket, resources_being_edited: new_resources_being_edited)}
  end
end
