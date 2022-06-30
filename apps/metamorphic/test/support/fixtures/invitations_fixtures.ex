defmodule Metamorphic.InvitationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Metamorphic.Invitations` context.
  """

  alias Metamorphic.Repo
  alias Metamorphic.Invitations
  alias Metamorphic.Invitations.{Invite, InviteToken}

  def unique_email, do: "email#{System.unique_integer()}@example.com"

  def invite_fixture(attrs \\ %{}, opts \\ []) do
    {:ok, invite} =
      attrs
      |> Enum.into(%{
        email: unique_email()
      })
      |> Invitations.create_invite()

    if Keyword.get(opts, :confirmed, true), do: Repo.transaction(confirm_invite_multi(invite))

    invite
  end

  def extract_invite_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    # [_, token, _] = String.split(captured.body, "[TOKEN]")
    [_, token, _] = String.split(captured.text_body, "[TOKEN]")
    token
  end

  defp confirm_invite_multi(invite) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:invite, Invite.confirm_changeset(invite))
    |> Ecto.Multi.delete_all(:tokens, InviteToken.invite_and_contexts_query(invite, ["confirm"]))
  end
end
