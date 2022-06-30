defmodule Metamorphic.Letters do
  @moduledoc """
  The Letters context.
  """

  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Accounts.Person
  alias Metamorphic.Letters.{Letter}
  alias Metamorphic.Relationships

  alias MetamorphicWeb.RealTime

  ## Getters

  @doc """
  Returns the letter by `id` scoped
  to the `current_person` in the `socket`.
  """
  def safe_get_letter(id, current_person) when is_binary(id) and is_struct(current_person) do
    Repo.one(
      from l in Letter,
        where: l.id == ^id,
        where: l.person_id == ^current_person.id
    )
  end

  @doc """
  Returns a list of the current_person's
  Letters. Returns the list in `descending`
  order.
  """
  def safe_list_letters(current_person) when is_struct(current_person) do
    Repo.all(
      from l in Letter,
        where: l.person_id == ^current_person.id,
        order_by: [desc: l.inserted_at]
    )
  end

  @doc """
  Returns a list of the current_person's letters.

  This is used for downloading data.
  """
  def safe_download_list_letters(current_person) when is_struct(current_person) do
    Repo.all(
      from l in Letter,
        where: l.person_id == ^current_person.id
    )
  end

  ## Writers

  @doc """
  Creates a letter and broadcasts it
  to all recipients.

  ## Examples

      iex> create_letter(%{field: value})
      {:ok, %Memory{}}

      iex> create_letter(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_letter(%Letter{} = letter, current_person, attrs \\ %{})
      when is_struct(current_person) do
    letter
    |> Letter.changeset(attrs)
    |> Repo.insert()
    |> RealTime.Person.Letter.broadcast_save_letter()
  end

  @doc """
  Deletes a letter.

  ## Examples

      iex> delete_letter(letter)
      {:ok, %Letter{}}

      iex> delete_letter(letter)
      {:error, %Ecto.Changeset{}}

  """
  def delete_letter(%Letter{} = letter) do
    letter
    |> Repo.delete()
    |> RealTime.Person.Letter.broadcast_delete_letter()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking `%Letter{}` changes.

  ## Examples

      iex> change_letter(letter)
      %Ecto.Changeset{data: %Letter{}}
  """
  def change_letter(%Letter{} = letter, attrs \\ %{}) do
    Letter.changeset(letter, attrs)
  end
end
