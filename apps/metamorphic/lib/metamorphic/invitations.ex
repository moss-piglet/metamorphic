defmodule Metamorphic.Invitations do
  @moduledoc """
  The Invitations context.
  """

  import Ecto.Query, warn: false
  alias Metamorphic.Repo

  alias Metamorphic.Invitations.{Invite, InviteToken, InviteNotifier}
  alias MetamorphicWeb.RealTime

  # Set the random bytes for invitation code generator.
  @rand_bytes 16

  ## Database getters

  @doc """
  Gets a invite by email.

  ## Examples

      iex> get_invite_by_email("foo@example.com")
      %Invite{}

      iex> get_invite_by_email("unknown@example.com")
      nil

  """
  def get_invite_by_email(email) when is_binary(email) do
    Repo.get_by(Invite, email_hash: email)
  end

  @doc """
  Gets an invite by code.

  Used upon beta registration, where it takes in the code to
  match to a given invite.

  ## Examples

      iex> get_invite_by_redeemed_code(invite_code)
      %Invite{}

      iex> get_invite_by_redeemed_code(invalid_invite_code)
      nil
  """
  def get_invite_by_redeemed_code(code) when is_binary(code) do
    Repo.one(
      from i in Invite,
        where: ^code in i.codes_hash
    )
  end

  @doc """
  Gets an invite if the given code's hash is present
  in the redeemed_codes list.

  Can be used for checking if a code exists and whether or not
  it has been redeemed.

  ## Examples

      iex> get_redeemed_code(invite_code)
      %Invite{}

      iex> get_redeemed_code(used_invite_code)
      nil
  """
  def get_redeemed_code(invite_code) when is_binary(invite_code) do
    Repo.one(
      from i in Invite,
        where: ^invite_code in i.codes_hash,
        where: ^invite_code not in i.redeemed_codes
    )
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given invite.

  ## Examples

      iex> deliver_invite_confirmation_instructions(invite, &Routes.invite_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_invite_confirmation_instructions(confirmed_invite, &Routes.invite_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """
  def deliver_invite_confirmation_instructions(%Invite{} = invite, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if invite.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, invite_token} = InviteToken.build_email_token(invite, "confirm")
      Repo.insert!(invite_token)

      InviteNotifier.deliver_invite_confirmation_instructions(
        invite,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a invite by the given token.

  If the token matches, the invite account is marked as confirmed
  and the token is deleted.
  """
  def confirm_invite(token) do
    with {:ok, query} <- InviteToken.verify_email_token_query(token, "confirm"),
         %Invite{} = invite <- Repo.one(query),
         {:ok, %{invite: invite}} <- Repo.transaction(confirm_invite_multi(invite)) do
      {:ok, invite}
    else
      _ -> :error
    end
  end

  defp confirm_invite_multi(invite) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:invite, Invite.confirm_changeset(invite))
    |> Ecto.Multi.delete_all(:tokens, InviteToken.invite_and_contexts_query(invite, ["confirm"]))
  end

  @doc """
  Returns the list of invitations.

  ## Examples

      iex> list_invitations()
      [%Invite{}, ...]

  """
  def list_invitations do
    Repo.all(Invite)
  end

  @doc """
  Returns the number of requested invitations.

  ## Examples

      iex> get_requested_invites_count()
      200000
  """
  def get_requested_invites_count do
    Repo.all(Invite) |> Enum.count()
  end

  @doc """
  Returns a list of emails that have requested
  invitations.

  ## Examples

      iex> get_list_of_invitation_emails()
      ["email_1", ... ]
  """
  def get_list_of_invitation_emails do
    Repo.all(from i in Invite, select: i.email)
  end

  @doc """
  Returns a list of ids that have requested
  invitations.

  ## Examples

      iex> get_list_of_invitation_ids()
      ["id_1", ... ]
  """
  def get_list_of_invitation_ids do
    Repo.all(from i in Invite, select: i.id)
  end

  @doc """
  Returns a list of codes that have requested
  invitations.

  ## Examples

      iex> get_list_of_invitation_codes()
      ["code_1", ... ]
  """
  def get_list_of_invitation_codes do
    Repo.all(from i in Invite, select: i.codes)
  end

  @doc """
  Returns a list of messages from requested
  invitations.

  ## Examples

      iex> get_list_of_messages()
      ["message_1", ... ]
  """
  def get_list_of_messages do
    Repo.all(from i in Invite, select: i.message)
  end

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123)
      %Invite{}

      iex> get_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invite!(id), do: Repo.get!(Invite, id)

  ## Admin getters and counters

  @doc false
  def admin_safe_count_all_invitations(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      Repo.aggregate(Invite, :count)
    end
  end

  @doc false
  def admin_safe_count_all_confirmed_invitations(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      query = from i in Invite, where: not is_nil(i.confirmed_at)
      Repo.aggregate(query, :count)
    end
  end

  @doc false
  def admin_safe_count_all_sent_invitations(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      query = from i in Invite, where: i.sent_codes == true
      Repo.aggregate(query, :count)
    end
  end

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%{field: value})
      {:ok, %Invite{}}

      iex> create_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invite(attrs \\ %{}) do
    %Invite{}
    |> Invite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates 3 invite codes for an invite.

  ## Examples

      iex> create_invite_codes(invite, %field: new_value)
      {:ok, %Invite{}}

      iex> create_invite_codes(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_invite_codes(%Invite{} = invite, attrs) do
    invite
    |> Invite.invite_codes_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a invite.

  ## Examples

      iex> update_invite(invite, %{field: new_value})
      {:ok, %Invite{}}

      iex> update_invite(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
    |> RealTime.Admin.Invitation.broadcast_update_invitation()
  end

  @doc """
  Redeems an invite.

  ## Examples

      iex> redeem_invite(invite, %{field: new_value})
      {:ok, %Invite{}}

      iex> redeem_invite(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def redeem_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.redeem_invite_codes_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite)
      {:ok, %Invite{}}

      iex> delete_invite(invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Ecto.Changeset{data: %Invite{}}

  """
  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end

  @doc """
  Generates three random invitation codes.
  """
  def generate_new_invitation_codes do
    Enum.into([@rand_bytes, @rand_bytes, @rand_bytes], [], fn x ->
      :crypto.strong_rand_bytes(x) |> :base64.encode()
    end)
  end
end
