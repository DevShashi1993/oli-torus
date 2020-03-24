defmodule Oli.Publishing do
  @moduledoc """
  The Publishing context.
  """

  import Ecto.Query, warn: false
  alias Oli.Repo

  alias Oli.Publishing.Publication

  @doc """
  Returns the list of publications.

  ## Examples

      iex> list_publications()
      [%Publication{}, ...]

  """
  def list_publications do
    Repo.all(Publication)
  end

  @doc """
  Gets a single publication.

  Raises `Ecto.NoResultsError` if the Publication does not exist.

  ## Examples

      iex> get_publication!(123)
      %Publication{}

      iex> get_publication!(456)
      ** (Ecto.NoResultsError)

  """
  def get_publication!(id), do: Repo.get!(Publication, id)

  @doc """
  Creates a publication.

  ## Examples

      iex> create_publication(%{field: value})
      {:ok, %Publication{}}

      iex> create_publication(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_publication(attrs \\ %{}) do
    %Publication{}
    |> Publication.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a publication.

  ## Examples

      iex> update_publication(publication, %{field: new_value})
      {:ok, %Publication{}}

      iex> update_publication(publication, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_publication(%Publication{} = publication, attrs) do
    publication
    |> Publication.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a publication.

  ## Examples

      iex> delete_publication(publication)
      {:ok, %Publication{}}

      iex> delete_publication(publication)
      {:error, %Ecto.Changeset{}}

  """
  def delete_publication(%Publication{} = publication) do
    Repo.delete(publication)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking publication changes.

  ## Examples

      iex> change_publication(publication)
      %Ecto.Changeset{source: %Publication{}}

  """
  def change_publication(%Publication{} = publication) do
    Publication.changeset(publication, %{})
  end

  alias Oli.Publishing.ResourceMapping

  @doc """
  Returns the list of resource_mappings.

  ## Examples

      iex> list_resource_mappings()
      [%ResourceMapping{}, ...]

  """
  def list_resource_mappings do
    Repo.all(ResourceMapping)
  end

  @doc """
  Gets a single resource_mapping.

  Raises `Ecto.NoResultsError` if the Resource mapping does not exist.

  ## Examples

      iex> get_resource_mapping!(123)
      %ResourceMapping{}

      iex> get_resource_mapping!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource_mapping!(id), do: Repo.get!(ResourceMapping, id)

  @doc """
  Creates a resource_mapping.

  ## Examples

      iex> create_resource_mapping(%{field: value})
      {:ok, %ResourceMapping{}}

      iex> create_resource_mapping(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource_mapping(attrs \\ %{}) do
    %ResourceMapping{}
    |> ResourceMapping.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource_mapping.

  ## Examples

      iex> update_resource_mapping(resource_mapping, %{field: new_value})
      {:ok, %ResourceMapping{}}

      iex> update_resource_mapping(resource_mapping, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource_mapping(%ResourceMapping{} = resource_mapping, attrs) do
    resource_mapping
    |> ResourceMapping.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource_mapping.

  ## Examples

      iex> delete_resource_mapping(resource_mapping)
      {:ok, %ResourceMapping{}}

      iex> delete_resource_mapping(resource_mapping)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource_mapping(%ResourceMapping{} = resource_mapping) do
    Repo.delete(resource_mapping)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource_mapping changes.

  ## Examples

      iex> change_resource_mapping(resource_mapping)
      %Ecto.Changeset{source: %ResourceMapping{}}

  """
  def change_resource_mapping(%ResourceMapping{} = resource_mapping) do
    ResourceMapping.changeset(resource_mapping, %{})
  end

  alias Oli.Publishing.ActivityMapping

  @doc """
  Returns the list of activity_mappings.

  ## Examples

      iex> list_activity_mappings()
      [%ActivityMapping{}, ...]

  """
  def list_activity_mappings do
    Repo.all(ActivityMapping)
  end

  @doc """
  Gets a single activity_mapping.

  Raises `Ecto.NoResultsError` if the Activity mapping does not exist.

  ## Examples

      iex> get_activity_mapping!(123)
      %ActivityMapping{}

      iex> get_activity_mapping!(456)
      ** (Ecto.NoResultsError)

  """
  def get_activity_mapping!(id), do: Repo.get!(ActivityMapping, id)

  @doc """
  Creates a activity_mapping.

  ## Examples

      iex> create_activity_mapping(%{field: value})
      {:ok, %ActivityMapping{}}

      iex> create_activity_mapping(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_activity_mapping(attrs \\ %{}) do
    %ActivityMapping{}
    |> ActivityMapping.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a activity_mapping.

  ## Examples

      iex> update_activity_mapping(activity_mapping, %{field: new_value})
      {:ok, %ActivityMapping{}}

      iex> update_activity_mapping(activity_mapping, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_activity_mapping(%ActivityMapping{} = activity_mapping, attrs) do
    activity_mapping
    |> ActivityMapping.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a activity_mapping.

  ## Examples

      iex> delete_activity_mapping(activity_mapping)
      {:ok, %ActivityMapping{}}

      iex> delete_activity_mapping(activity_mapping)
      {:error, %Ecto.Changeset{}}

  """
  def delete_activity_mapping(%ActivityMapping{} = activity_mapping) do
    Repo.delete(activity_mapping)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking activity_mapping changes.

  ## Examples

      iex> change_activity_mapping(activity_mapping)
      %Ecto.Changeset{source: %ActivityMapping{}}

  """
  def change_activity_mapping(%ActivityMapping{} = activity_mapping) do
    ActivityMapping.changeset(activity_mapping, %{})
  end

  alias Oli.Publishing.ObjectiveMapping

  @doc """
  Returns the list of objective_mappings.

  ## Examples

      iex> list_objective_mappings()
      [%ObjectiveMapping{}, ...]

  """
  def list_objective_mappings do
    Repo.all(ObjectiveMapping)
  end

  @doc """
  Gets a single objective_mapping.

  Raises `Ecto.NoResultsError` if the Objective mapping does not exist.

  ## Examples

      iex> get_objective_mapping!(123)
      %ObjectiveMapping{}

      iex> get_objective_mapping!(456)
      ** (Ecto.NoResultsError)

  """
  def get_objective_mapping!(id), do: Repo.get!(ObjectiveMapping, id)

  @doc """
  Creates a objective_mapping.

  ## Examples

      iex> create_objective_mapping(%{field: value})
      {:ok, %ObjectiveMapping{}}

      iex> create_objective_mapping(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_objective_mapping(attrs \\ %{}) do
    %ObjectiveMapping{}
    |> ObjectiveMapping.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a objective_mapping.

  ## Examples

      iex> update_objective_mapping(objective_mapping, %{field: new_value})
      {:ok, %ObjectiveMapping{}}

      iex> update_objective_mapping(objective_mapping, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_objective_mapping(%ObjectiveMapping{} = objective_mapping, attrs) do
    objective_mapping
    |> ObjectiveMapping.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a objective_mapping.

  ## Examples

      iex> delete_objective_mapping(objective_mapping)
      {:ok, %ObjectiveMapping{}}

      iex> delete_objective_mapping(objective_mapping)
      {:error, %Ecto.Changeset{}}

  """
  def delete_objective_mapping(%ObjectiveMapping{} = objective_mapping) do
    Repo.delete(objective_mapping)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking objective_mapping changes.

  ## Examples

      iex> change_objective_mapping(objective_mapping)
      %Ecto.Changeset{source: %ObjectiveMapping{}}

  """
  def change_objective_mapping(%ObjectiveMapping{} = objective_mapping) do
    ObjectiveMapping.changeset(objective_mapping, %{})
  end
end