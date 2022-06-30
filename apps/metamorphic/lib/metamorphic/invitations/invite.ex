defmodule Metamorphic.Invitations.Invite do
  @moduledoc """
  Schema for pre-release Invitations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.{Encrypted, Hashed}
  alias Metamorphic.Invitations

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invitations" do
    field :codes, {:array, Encrypted.Binary}, redact: true
    field :codes_hash, {:array, Hashed.HMAC}, redact: true
    field :redeemed_code, {:array, :binary}, virtual: true, redact: true
    field :redeemed_codes, {:array, :binary}, redact: true
    field :message, Encrypted.Binary, redact: true
    field :email, Encrypted.Binary, redact: true
    field :email_hash, Hashed.HMAC, redact: true
    field :confirmed_at, Encrypted.NaiveDateTime
    field :sent_codes, :boolean, default: false

    timestamps()
  end

  @doc """
  An invite changeset for invitations.
  """
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :message, :sent_codes])
    |> validate_email()
    |> validate_message()
  end

  @doc """
  An invite changeset for redeeming
  invite codes.
  """
  def redeem_invite_codes_changeset(invite, attrs) do
    invite
    |> cast(attrs, [:redeemed_code])
    |> validate_redeemed_code()
  end

  @doc """
  A changeset for updating the invite
  codes.
  """
  def invite_codes_changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :codes])
    |> validate_email()
    |> add_invitation_codes()
    |> validate_invitation_codes()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})*$/,
      message: "must have the @ sign, no spaces, and/or proper format"
    )
    |> validate_length(:email, max: 160)
    |> add_email_hash()
    |> validate_email_hash()
  end

  defp add_email_hash(changeset) do
    if Map.has_key?(changeset.changes, :email) do
      changeset |> put_change(:email_hash, String.downcase(get_field(changeset, :email)))
    else
      changeset
    end
  end

  defp validate_email_hash(changeset) do
    changeset
    |> unsafe_validate_unique([:email_hash], Metamorphic.Repo, message: "invalid email")
    |> unique_constraint(:email_hash)
  end

  defp validate_message(changeset) do
    changeset
    |> validate_required([:message])
    |> validate_length(:message, min: 20, max: 1000)
  end

  defp add_invitation_codes(changeset) do
    changeset
    |> put_change(:codes, Invitations.generate_new_invitation_codes())
  end

  defp validate_invitation_codes(changeset) do
    changeset
    |> validate_required([:codes])
    |> add_codes_hash()
    |> validate_codes_hash()
  end

  defp add_codes_hash(changeset) do
    if Map.has_key?(changeset.changes, :codes) do
      changeset |> put_change(:codes_hash, get_field(changeset, :codes))
    else
      changeset
    end
  end

  defp validate_codes_hash(changeset) do
    changeset
    |> unsafe_validate_unique([:codes_hash], Metamorphic.Repo, message: "invalid invite code")
    |> unique_constraint(:codes_hash)
  end

  defp validate_redeemed_code(changeset) do
    changeset
    |> validate_required([:redeemed_code])
    |> add_redeemed_codes()
    |> validate_redeemed_codes()
  end

  defp add_redeemed_codes(changeset) do
    redeemed_codes = get_field(changeset, :redeemed_codes)

    if Map.has_key?(changeset.changes, :redeemed_code) do
      if length(redeemed_codes) >= 1 do
        [redeemed_code] = get_field(changeset, :redeemed_code)
        updated_redeemed_codes = [redeemed_code | redeemed_codes]

        changeset
        |> put_change(:redeemed_codes, updated_redeemed_codes)
        |> delete_change(:redeemed_code)
      else
        redeemed_code = get_field(changeset, :redeemed_code)

        changeset
        |> put_change(:redeemed_codes, redeemed_code)
        |> delete_change(:redeemed_code)
      end
    else
      changeset
    end
  end

  defp validate_redeemed_codes(changeset) do
    changeset
    |> unsafe_validate_unique([:redeemed_codes], Metamorphic.Repo,
      message: "has already been redeemed"
    )
    |> unique_constraint(:redeemed_codes)
  end

  @doc """
  Confirms the invite email by setting `confirmed_at`.
  """
  def confirm_changeset(invite) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(invite, confirmed_at: now)
  end
end
