defmodule Oli.Seeder do

  alias Oli.Publishing
  alias Oli.Repo
  alias Oli.Accounts.{SystemRole, ProjectRole, Institution, Author}
  alias Oli.Authoring.Authors.{AuthorProject, ProjectRole}
  alias Oli.Authoring.Course.{Project, Family}
  alias Oli.Authoring.Learning.{Objective, ObjectiveFamily, ObjectiveRevision}
  alias Oli.Authoring.Resources
  alias Oli.Authoring.Resources.{Resource, ResourceFamily, ResourceRevision}
  alias Oli.Publishing.Publication



  def base_project_with_resource() do

    {:ok, family} = Family.changeset(%Family{}, %{description: "description", slug: "slug", title: "title"}) |> Repo.insert
    {:ok, project} = Project.changeset(%Project{}, %{description: "description", slug: "slug", title: "title", version: "1", family_id: family.id}) |> Repo.insert
    {:ok, author} = Author.changeset(%Author{}, %{email: "test@test.com", first_name: "First", last_name: "Last", provider: "foo", system_role_id: SystemRole.role_id.author}) |> Repo.insert
    {:ok, _} = AuthorProject.changeset(%AuthorProject{}, %{author_id: author.id, project_id: project.id, project_role_id: ProjectRole.role_id.owner}) |> Repo.insert

    {:ok, institution} = Institution.changeset(%Institution{}, %{name: "CMU", country_code: "some country_code", institution_email: "some institution_email", institution_url: "some institution_url", timezone: "some timezone", consumer_key: "some key", shared_secret: "some secret", author_id: author.id}) |> Repo.insert

    # A single resource with a mapped revision
    {:ok, resource_family} = ResourceFamily.changeset(%ResourceFamily{}, %{}) |> Repo.insert
    {:ok, resource} = Resource.changeset(%Resource{}, %{project_id: project.id, family_id: resource_family.id}) |> Repo.insert
    resource_type = Resources.list_resource_types() |> hd
    {:ok, revision} = ResourceRevision.changeset(%ResourceRevision{}, %{author_id: author.id, objectives: [], resource_type_id: resource_type.id, children: [], content: [], deleted: false, slug: "some_title", title: "some title", resource_id: resource.id}) |> Repo.insert
    {:ok, publication} = Publication.changeset(%Publication{}, %{description: "description", published: false, root_resource_id: resource.id, project_id: project.id}) |> Repo.insert
    {:ok, mapping} = Publishing.create_resource_mapping(%{ publication_id: publication.id, resource_id: resource.id, revision_id: revision.id})
    {:ok, publication} = Publishing.update_publication(publication, %{root_resource_id: resource.id})

    Map.put(%{}, :family, family)
      |> Map.put(:project, project)
      |> Map.put(:publication, publication)
      |> Map.put(:author, author)
      |> Map.put(:institution, institution)
      |> Map.put(:resource_family, resource_family)
      |> Map.put(:resource, resource)
      |> Map.put(:resource_type, resource_type)
      |> Map.put(:revision, revision)
      |> Map.put(:mapping, mapping)
  end

  def add_objective(%{ project: project, publication: publication, author: author} = map, title) do
    {:ok, objective_family} = ObjectiveFamily.changeset(%ObjectiveFamily{}, %{}) |> Repo.insert
    {:ok, objective} = Objective.changeset(%Objective{}, %{project_id: project.id, family_id: objective_family.id}) |> Repo.insert
    {:ok, revision} = ObjectiveRevision.changeset(%ObjectiveRevision{}, %{author_id: author.id, children: [], title: title, deleted: false, objective_id: objective.id}) |> Repo.insert
    {:ok, _mapping} = Publishing.create_objective_mapping(%{ publication_id: publication.id, objective_id: objective.id, revision_id: revision.id})

    map
  end

  def add_author(%{ project: project} = map, author, atom) do
    {:ok, _} = AuthorProject.changeset(%AuthorProject{}, %{author_id: author.id, project_id: project.id, project_role_id: ProjectRole.role_id.owner}) |> Repo.insert
    Map.put(map, atom, author)
  end

end