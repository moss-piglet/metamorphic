defmodule Metamorphic.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Metamorphic.Accounts` context.
  """

  alias Metamorphic.Repo
  alias Metamorphic.Accounts.{Person, PersonToken}

  def valid_person_name, do: "Test Bot"
  def unique_person_email, do: "person#{System.unique_integer()}@example.com"
  def unique_person_pseudonym, do: "pseudo#{System.unique_integer([:positive])}"
  def valid_person_password, do: "Testing Zoology Zooing Testology!"
  def valid_person_terms_of_use, do: true

  def person_fixture(attrs \\ %{}, opts \\ []) do
    temp_email = unique_person_email()
    temp_name = valid_person_name()
    temp_pseudonym = unique_person_pseudonym()

    {:ok, person} =
      attrs
      |> Enum.into(%{
        name: temp_name,
        pseudonym: temp_pseudonym,
        email: temp_email,
        password: valid_person_password(),
        terms_of_use: valid_person_terms_of_use()
      })
      |> Metamorphic.Accounts.register_person()

    if Keyword.get(opts, :confirmed, true), do: Repo.transaction(confirm_person_multi(person))

    {person, temp_email, temp_name, temp_pseudonym}
  end

  def extract_person_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    # [_, token, _] = String.split(captured.body, "[TOKEN]")
    [_, token, _] = String.split(captured.text_body, "[TOKEN]")
    token
  end

  defp confirm_person_multi(person) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:person, Person.confirm_changeset(person))
    |> Ecto.Multi.delete_all(:tokens, PersonToken.person_and_contexts_query(person, ["confirm"]))
  end
end
