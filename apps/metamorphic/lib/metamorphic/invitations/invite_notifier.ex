defmodule Metamorphic.Invitations.InviteNotifier do
  @moduledoc """
  Invite email notification module that logs messages
  to the terminal in a local environment, and uses
  [Bamboo](https://hexdocs.pm/bamboo) to send email
  notifications in a production environment.
  """
  use Bamboo.Phoenix, view: MetamorphicWeb.EmailView

  alias Metamorphic.{Email, Mailer}

  @from_address "hello@metamorphic.app"
  @reply_to_address "support@metamorphic.app"

  @doc """
  Deliver instructions to confirm account.
  """
  def old_deliver_invite_confirmation_instructions(invite, url) do
    new_email()
    |> put_layout({MetamorphicWeb.LayoutView, :email})
    |> to(invite.email)
    |> from(@from_address)
    |> put_header("Reply-To", @reply_to_address)
    |> subject("Please confirm your email")
    |> render(:invite_confirmation_instructions, %{url: url})
    |> Mailer.deliver_later()
  end

  @doc """
  Deliver early access invite codes to invite emailee.
  """
  def old_deliver_invite_codes_for_early_access(email, invite_codes, url) do
    new_email()
    |> put_layout({MetamorphicWeb.LayoutView, :email})
    |> to(email)
    |> from(@from_address)
    |> put_header("Reply-To", @reply_to_address)
    |> subject("Welcome to our early access! 🎉🥳")
    |> render(:invite_codes_for_beta, %{email: email, invite_codes: invite_codes, url: url})
    |> Mailer.deliver_later()
  end

  @doc """
  Deliver instructions to confirm invite.
  """
  def deliver_invite_confirmation_instructions(invite, url) do
    Email.confirm_early_access_email(invite.email, url)
    |> deliver()
  end

  @doc """
  Deliver instructions to confirm invite.
  """
  def deliver_invite_codes_for_early_access(email, invite_codes, url) do
    Email.send_early_access_codes_email(email, invite_codes, url)
    |> deliver()
  end

  defp deliver(email) do
    with {:ok, _metadata} <- Mailer.deliver_later(email) do
      # Returning the email helps with testing
      {:ok, email}
    end
  end
end
