defmodule Oli.Qa.Reviewers.Pedagogy do
  import Ecto.Query, warn: false
  alias Oli.Publishing
  alias Oli.Authoring.Course
  alias Oli.Resources.ResourceType
  alias Oli.Resources
  alias Oli.Qa.{Warnings, Reviews}

  def review(project_slug) do
    # helpers
    pages = Publishing.get_unpublished_revisions_by_type(project_slug, "page")
    activities = Publishing.get_unpublished_revisions_by_type(project_slug, "activity")

    # logic
    {:ok, review} = Reviews.create_review(Course.get_project_by_slug(project_slug), "pedagogy")
    review
    |> no_attached_objectives(pages)
    |> no_attached_objectives(activities)
    |> no_attached_activities(pages)
    |> Reviews.mark_review_done

    project_slug
  end

  def no_attached_objectives(review, revisions) do
    revisions
    |> Enum.filter(&no_attached_objectives?/1)
    |> Enum.each(&Warnings.create_warning(%{
      review_id: review.id,
      revision_id: &1.id,
      subtype: "no attached objectives"
    }))

    review
  end

  defp no_attached_objectives?(revision) do
    case ResourceType.get_type_by_id(revision.resource_type.id) do
      "page" -> Enum.empty?(revision.objectives["attached"])
      "activity" -> revision.objectives == %{}
      # Containers and objectives not handled
      _ -> true
    end
  end

  def no_attached_activities(review, pages) do
    pages
    |> Enum.filter(&no_attached_activities?/1)
    |> Enum.each(&Warnings.create_warning(%{
      review_id: review.id,
      revision_id: &1.id,
      subtype: "no practice opportunities"
    }))

    review
  end

  defp no_attached_activities?(page) do
    page
    |> Resources.activity_references
    |> Enum.empty?
  end
end