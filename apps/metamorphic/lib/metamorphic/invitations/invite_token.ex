defmodule Metamorphic.Invitations.InviteToken do
  @moduledoc """
  InviteToken module for handling invite tokens for
  sessions and emails.
  """
  use Ecto.Schema
  import Ecto.Query

  alias Metamorphic.{Encrypted, Hashed}

  @hash_algorithm :sha512
  @rand_size 32

  @confirm_validity_in_days 1

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invitations_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, Encrypted.Binary
    field :sent_to_hash, Hashed.HMAC

    belongs_to :invite, Metamorphic.Invitations.Invite

    timestamps(updated_at: false)
  end

  @doc """
  Builds a token with a hashed counter part.

  The non-hashed token is sent to the invite email while the
  hashed part is stored in the database, to avoid reconstruction.
  The token is valid for a week as long as invitations don't change
  their email.
  """
  def build_email_token(invite, context) do
    build_hashed_token(invite, context, invite.email)
  end

  defp build_hashed_token(invite, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Metamorphic.Invitations.InviteToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       sent_to_hash: sent_to,
       invite_id: invite.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the invite found by the token.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: invite in assoc(token, :invite),
            where:
              token.inserted_at > ago(^days, "day") and token.sent_to_hash == invite.email_hash,
            where: is_nil(invite.confirmed_at),
            select: invite

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  # defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Returns the given token with the given context.
  """
  def token_and_context_query(token, context) do
    from Metamorphic.Invitations.InviteToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given invite for the given contexts.
  """
  def invite_and_contexts_query(invite, :all) do
    from t in Metamorphic.Invitations.InviteToken, where: t.invite_id == ^invite.id
  end

  def invite_and_contexts_query(invite, [_ | _] = contexts) do
    from t in Metamorphic.Invitations.InviteToken,
      where: t.invite_id == ^invite.id and t.context in ^contexts
  end
end
