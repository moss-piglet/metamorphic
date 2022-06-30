defmodule MetamorphicWeb.InviteConfirmationController do
  @moduledoc """
  This controller facilitates the invite confirmation
  flow.
  """
  use MetamorphicWeb, :controller

  alias Metamorphic.Invitations
  alias MetamorphicWeb.RealTime.Admin.Invitation, as: AdminInvitation

  def new(conn, _params) do
    render(conn, "new.html", page_title: "Resend Invite Confirmation", error_message: nil)
  end

  def create(conn, %{"invite" => %{"email" => email}}) do
    if invite = Invitations.get_invite_by_email(email) do
      Invitations.deliver_invite_confirmation_instructions(
        invite,
        &Routes.invite_confirmation_url(conn, :confirm, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "Thanks for your interest! You will receive a confirmation " <>
        "email shortly if (1) you signed up with us and (2) your email is not confirmed."
    )
    |> redirect(to: "/invitations/confirm")
  end

  # Do not log in the invite after confirmation to avoid a
  # leaked token giving the invite access to the account.
  @spec confirm(Plug.Conn.t(), map) :: Plug.Conn.t()
  def confirm(conn, %{"token" => token}) do
    case Invitations.confirm_invite(token) do
      {:ok, invite} ->
        invite_params = %{email: invite.email, codes: invite.codes}
        generate_invite_codes(invite, invite_params)
        AdminInvitation.broadcast_save_invitation(invite)

        conn
        |> put_session(:current_invite, "confirmed")
        |> put_flash(
          :success,
          "Hooray! You have successfully landed on the list for a chance at 3 invite codes to our Early Access. Stay tuned, we'll be sending you your invite codes within the coming days! 💙"
        )
        |> redirect(to: "/people/register")

      :error ->
        # If there is a current invite and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the invitee themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          # This will never match. Need to reconsider logic.
          %{current_invite: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(
              :invite_confirm_warning,
              "Resend your confirmation link below. Please note: confirmed emails won't receive another confirmation email in order to protect from spam."
            )
            |> redirect(to: "/invitations/confirm")
        end
    end
  end

  defp generate_invite_codes(invite, attrs) do
    Invitations.create_invite_codes(invite, attrs)
  end
end
