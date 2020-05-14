defmodule Oli.Delivery.Page.PageContext do

  @moduledoc """
  Defines the context required to render a page in delivery mode.
  """

  @enforce_keys [:page, :progress_state, :activities, :objectives, :previous_page, :next_page]
  defstruct [:page, :progress_state, :activities, :objectives, :previous_page, :next_page]

  alias Oli.Delivery.Page.ActivityContext
  alias Oli.Delivery.Page.PageContext
  alias Oli.Resources.Revision
  alias Oli.Publishing.DeliveryResolver
  alias Oli.Activities.Realizer
  alias Oli.Delivery.Attempts

  @doc """
  Creates the page context required to render a page in delivery model, based
  off of the section context id, the slug of the page to render, and an
  optional id of the parent container that the page exists within. If not
  specified, the container is assumed to be the root resource of the publication.

  The key task performed here is the resolution of all referenced objectives
  and activities that may be present in the content of the page. This
  information is collected and then assembled in a fashion that can be given
  to a renderer.
  """
  @spec create_page_context(String.t, String.t, any) :: %PageContext{}
  def create_page_context(context_id, page_slug, user_id, container_id \\ nil) do

    # resolve the page revision per context_id
    page_revision = DeliveryResolver.from_revision_slug(context_id, page_slug)

    # track access to this resource
    Attempts.track_access(page_revision.resource_id, context_id, user_id)

    # this realizes and resolves activities that may be present in the page
    activity_provider = fn revision ->
      case Realizer.realize(revision) do
        [] -> []
        ids -> DeliveryResolver.from_resource_id(context_id, ids)
      end
    end

    {progress_state, activities} = case Attempts.determine_resource_attempt_state(page_revision, context_id, user_id, activity_provider) do
      {:in_progress, {_, latest_attempts}} -> {:in_progress, ActivityContext.create_context_map(latest_attempts)}
      {:not_started, _} -> {:not_started, nil}
    end

    {objectives, previous, next} =
      retrieve_objectives_previous_next(context_id, page_revision, container_id)

    %PageContext{
      page: page_revision,
      progress_state: progress_state,
      activities: activities,
      objectives: objectives,
      previous_page: previous,
      next_page: next
    }
  end

  # We combine retrieve objective titles and previous next page
  # information in one step so that we can do all their revision
  # resolution in one step.
  defp retrieve_objectives_previous_next(context_id,
    %Revision{objectives: %{"attached" => objective_ids}} = page_revision, container_id) do

    # if container_id is nil we assume it is the root
    container = case container_id do
      nil -> DeliveryResolver.root_resource(context_id)
      id -> DeliveryResolver.from_resource_id(context_id, id)
    end

    previous_next = determine_previous_next(container, page_revision.resource_id)

    # resolve all of these references, all at once, storing
    # them in a map based on their resource_id as the key
    all_resources = objective_ids ++ Enum.filter(previous_next, fn a -> a != nil end)

    revisions = DeliveryResolver.from_resource_id(context_id, all_resources)
    |> Enum.reduce(%{}, fn r, m -> Map.put(m, r.resource_id, r) end)

    objective_titles = Enum.map(objective_ids, fn id -> Map.get(revisions, id).title end)

    previous = Map.get(revisions, Enum.at(previous_next, 0))
    next = Map.get(revisions, Enum.at(previous_next, 1))

    {objective_titles, previous, next}
  end

  defp determine_previous_next(%{children: children}, page_resource_id) do

    index = Enum.find_index(children, fn id -> id == page_resource_id end)

    case {index, length(children) - 1} do
      {_, 0} -> [nil, nil]
      {0, _} -> [nil, Enum.at(children, 1)]
      {a, a} -> [Enum.at(children, a - 1), nil]
      {a, _} -> [Enum.at(children, a - 1), Enum.at(children, a + 1)]
    end
  end

end