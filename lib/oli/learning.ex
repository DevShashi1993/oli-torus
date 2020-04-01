defmodule Oli.Learning do
  @moduledoc """
  The Learning context.
  """

  import Ecto.Query, warn: false
  alias Oli.Repo

  alias Oli.Learning.Objective

  @doc """
  Returns the list of objectives.

  ## Examples

      iex> list_objectives()
      [%Objective{}, ...]

  """
  def list_objectives do
    Repo.all(Objective)
  end

  @doc """
  Gets a single objective.

  Raises `Ecto.NoResultsError` if the Objective does not exist.

  ## Examples

      iex> get_objective!(123)
      %Objective{}

      iex> get_objective!(456)
      ** (Ecto.NoResultsError)

  """
  def get_objective!(id), do: Repo.get!(Objective, id)

  @doc """
  Creates a objective.

  ## Examples

      iex> create_objective(%{field: value})
      {:ok, %Objective{}}

      iex> create_objective(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_objective(attrs \\ %{}) do
    Multi.new
    |> Multi.insert(:objective, do_create_objective(attrs))
    |> Multi.merge(fn %{objective: objective} ->
      Multi.new
      |> Multi.insert(:objective_revision, do_create_objective_revision(Map.get(attrs, :title), objective)) end)
    |> Repo.transaction
  end

  defp do_create_objective(attrs) do
    %Objective{}
    |> Objective.changeset(%{
      slug: slugify(Map.get(attrs, :title)),
      project_id: Map.get(attrs, :project_id)
    })
  end

  defp do_create_objective_revision(attr, objective) do
    %ObjectiveRevision{}
    |> ObjectiveRevision.changeset(%{
      title: Map.get(attrs, :title),
      project_id: project_id
    })
  end

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^\w-]+/u, "-")
  end

  @doc """
  Updates a objective.

  ## Examples

      iex> update_objective(objective, %{field: new_value})
      {:ok, %Objective{}}

      iex> update_objective(objective, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_objective(%Objective{} = objective, attrs) do
    objective
    |> Objective.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a objective.

  ## Examples

      iex> delete_objective(objective)
      {:ok, %Objective{}}

      iex> delete_objective(objective)
      {:error, %Ecto.Changeset{}}

  """
  def delete_objective(%Objective{} = objective) do
    Repo.delete(objective)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking objective changes.

  ## Examples

      iex> change_objective(objective)
      %Ecto.Changeset{source: %Objective{}}

  """
  def change_objective(%Objective{} = objective) do
    Objective.changeset(objective, %{})
  end

  alias Oli.Learning.ObjectiveRevision

  @doc """
  Returns the list of objective_revisions.

  ## Examples

      iex> list_objective_revisions()
      [%ObjectiveRevision{}, ...]

  """
  def list_objective_revisions do
    Repo.all(ObjectiveRevision)
  end

  @doc """
  Gets a single objective_revision.

  Raises `Ecto.NoResultsError` if the Objective revision does not exist.

  ## Examples

      iex> get_objective_revision!(123)
      %ObjectiveRevision{}

      iex> get_objective_revision!(456)
      ** (Ecto.NoResultsError)

  """
  def get_objective_revision!(id), do: Repo.get!(ObjectiveRevision, id)

  @doc """
  Creates a objective_revision.

  ## Examples

      iex> create_objective_revision(%{field: value})
      {:ok, %ObjectiveRevision{}}

      iex> create_objective_revision(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_objective_revision(attrs \\ %{}) do
    %ObjectiveRevision{}
    |> ObjectiveRevision.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a objective_revision.

  ## Examples

      iex> update_objective_revision(objective_revision, %{field: new_value})
      {:ok, %ObjectiveRevision{}}

      iex> update_objective_revision(objective_revision, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_objective_revision(%ObjectiveRevision{} = objective_revision, attrs) do
    objective_revision
    |> ObjectiveRevision.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a objective_revision.

  ## Examples

      iex> delete_objective_revision(objective_revision)
      {:ok, %ObjectiveRevision{}}

      iex> delete_objective_revision(objective_revision)
      {:error, %Ecto.Changeset{}}

  """
  def delete_objective_revision(%ObjectiveRevision{} = objective_revision) do
    Repo.delete(objective_revision)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking objective_revision changes.

  ## Examples

      iex> change_objective_revision(objective_revision)
      %Ecto.Changeset{source: %ObjectiveRevision{}}

  """
  def change_objective_revision(%ObjectiveRevision{} = objective_revision) do
    ObjectiveRevision.changeset(objective_revision, %{})
  end
end
