defmodule MetamorphicWeb.PersonTOTPController do
  use MetamorphicWeb, :controller

  alias Metamorphic.Accounts
  alias MetamorphicWeb.Extensions.MaxTOTPProcessor
  alias MetamorphicWeb.PersonAuth
  alias MetamorphicWeb.Router.Helpers, as: Routes

  # plug :put_layout, "log_in.html"
  plug :redirect_if_totp_is_not_pending

  @pending :person_totp_pending

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"person" => person_params}) do
    # audit_context = conn.assigns.audit_context
    current_person = conn.assigns.current_person
    %{"_csrf_token" => session_token} = conn |> get_session()

    case MaxTOTPProcessor.log(session_token) do
      {:ok, count} ->
        # audit_context
        case Accounts.validate_person_totp(current_person, person_params["code"]) do
          :valid_totp ->
            MaxTOTPProcessor.sweep_on_login(session_token)

            conn
            |> delete_session(@pending)
            |> PersonAuth.redirect_person_after_login_with_remember_me(person_params)

          {:valid_backup_code, remaining} ->
            MaxTOTPProcessor.sweep_on_login(session_token)
            plural = ngettext("backup code", "backup codes", remaining)

            conn
            |> delete_session(@pending)
            |> put_flash(
              :info,
              "You have #{remaining} #{plural} left. " <>
                "You can generate new ones under the Two-factor authentication section in the Settings page"
            )
            |> PersonAuth.redirect_person_after_login_with_remember_me(person_params)

          :invalid ->
            case count do
              2 ->
                conn
                |> put_flash(
                  :invalid_totp,
                  "Invalid two-factor authentication code. You have 3 more attempts left. Perhaps you should try one of your backup codes?"
                )
                |> render("new.html")

              3 ->
                conn
                |> put_flash(
                  :invalid_totp,
                  "Invalid two-factor authentication code. You have 2 more log in attempts left. Perhaps you should try one of your backup codes?"
                )
                |> render("new.html")

              4 ->
                conn
                |> put_flash(
                  :invalid_totp,
                  "Invalid two-factor authentication code. You have 1 more log in attempt left. Perhaps you should try one of your backup codes?"
                )
                |> render("new.html")

              _ ->
                conn
                |> put_flash(
                  :invalid_totp,
                  "Invalid two-factor authentication code. Perhaps you should try one of your backup codes?"
                )
                |> render("new.html")
            end
        end

      {:error, :rate_limited} ->
        conn
        |> put_flash(
          :max_totp_attempts,
          "You have tried too many times. Your session has been locked for safety. Please try again in 3 hours."
        )
        |> redirect(to: Routes.person_session_path(conn, :new))
    end
  end

  defp redirect_if_totp_is_not_pending(conn, _opts) do
    if get_session(conn, @pending) do
      conn
    else
      conn
      |> redirect(to: Routes.live_path(conn, MetamorphicWeb.DashboardLive.Index))
      |> halt()
    end
  end
end
