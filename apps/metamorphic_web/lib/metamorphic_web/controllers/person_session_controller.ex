defmodule MetamorphicWeb.PersonSessionController do
  use MetamorphicWeb, :controller

  alias Metamorphic.Accounts
  alias MetamorphicWeb.PersonAuth

  alias MetamorphicWeb.Extensions.{
    AvatarProcessor,
    MemoryProcessor,
    SharedAvatarProcessor,
    SharedMemoryProcessor,
    MaxLoginProcessor
  }

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"person" => person_params}) do
    %{"email" => email, "password" => password} = person_params
    %{"_csrf_token" => session_token} = conn |> get_session()

    case MaxLoginProcessor.log(session_token) do
      {:ok, count} ->
        case Accounts.get_person_by_email_and_password(email, password) do
          {:ok, person} ->
            MaxLoginProcessor.sweep_on_login(session_token)
            check_if_pwned_password_on_login(conn, person, password, person_params)

          {:error, :bad_username_or_password} ->
            case count do
              2 ->
                conn
                |> put_flash(
                  :max_login_warning,
                  "Invalid email or password. You have 3 more log in attempts left. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))

              3 ->
                conn
                |> put_flash(
                  :max_login_warning,
                  "Invalid email or password. You have 2 more log in attempts left. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))

              4 ->
                conn
                |> put_flash(
                  :max_login_warning,
                  "Invalid email or password. You have 1 more log in attempt left. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))

              _ ->
                conn
                |> put_flash(
                  :error,
                  "Invalid email or password. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))
            end

          {:error, :not_confirmed} ->
            case count do
              2 ->
                conn
                |> put_flash(
                  :max_login_warning,
                  "Invalid email or password. You have 3 more log in attempts left. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))

              3 ->
                conn
                |> put_flash(
                  :max_login_warning,
                  "Invalid email or password. You have 2 more log in attempts left. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))

              4 ->
                conn
                |> put_flash(
                  :max_login_warning,
                  "Invalid email or password. You have 1 more log in attempt left. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))

              _ ->
                conn
                |> put_flash(
                  :error,
                  "Invalid email or password. Perhaps you need to confirm your account first?"
                )
                |> redirect(to: Routes.person_session_path(conn, :new))
            end

          {:error, :person_blocked} ->
            conn
            |> put_flash(
              :person_blocked,
              "Your account has been found in violation of our terms of use."
            )
            |> redirect(to: Routes.person_session_path(conn, :new))
        end

      {:error, :rate_limited} ->
        conn
        |> put_flash(
          :max_login_attempts,
          "You have tried to log in too many times. Whether or not you have an account with us, your session has been locked for safety. Please try again in 1 hour."
        )
        |> redirect(to: Routes.person_session_path(conn, :new))
    end
  end

  def delete(conn, params) do
    conn
    |> put_flash(:success, "Logged out successfully.")
    |> clear_person_ets_data(params["current_person_id"])
    |> PersonAuth.log_out_person()
  end

  defp clear_person_ets_data(conn, key) do
    AvatarProcessor.delete_ets_avatar(key)
    SharedAvatarProcessor.delete_ets_avatars(key)
    MemoryProcessor.delete_ets_memories(key)
    SharedMemoryProcessor.delete_ets_memories(key)

    conn
  end

  defp check_if_pwned_password_on_login(conn, person, password, person_params) do
    person_return_to = get_session(conn, :person_return_to)

    case Pwned.check_password(password) do
      {:ok, false} ->
        conn = PersonAuth.log_in_person(conn, person, password)

        if Accounts.get_person_totp(person) do
          totp_params = Map.take(person_params, ["remember_me"])

          conn
          |> put_session(:person_totp_pending, true)
          |> redirect(to: Routes.person_totp_path(conn, :new, person: totp_params))
        else
          conn
          |> redirect(to: person_return_to || PersonAuth.signed_in_path(conn))
        end

      {:ok, count} ->
        pwned_message =
          "Danger! Your password has appeared at least #{count} time(s) in data breaches. Please change your password immediately."

        conn = PersonAuth.log_in_person(conn, person, password)

        if Accounts.get_person_totp(person) do
          totp_params = Map.take(person_params, ["remember_me"])

          conn
          |> put_flash(:pwned_password_alert, pwned_message)
          |> put_session(:person_totp_pending, true)
          |> redirect(to: Routes.person_totp_path(conn, :new, person: totp_params))
        else
          conn
          |> put_flash(:pwned_password_alert, pwned_message)
          |> redirect(to: person_return_to || PersonAuth.signed_in_path(conn))
        end

      :error ->
        # Assume internet dropped and we were unable to check against the pwned_password
        # database.
        conn = PersonAuth.log_in_person(conn, person, password)

        if Accounts.get_person_totp(person) do
          totp_params = Map.take(person_params, ["remember_me"])

          conn
          |> put_flash(
            :pwned_password_info,
            "The internet connection dropped and we couldn't run our secure password check this time. We will try again the next time you log in."
          )
          |> put_session(:person_totp_pending, true)
          |> redirect(to: Routes.person_totp_path(conn, :new, person: totp_params))
        else
          conn
          |> put_flash(
            :pwned_password_info,
            "The internet connection dropped and we couldn't run our secure password check this time. We will try again the next time you log in."
          )
          |> redirect(to: person_return_to || PersonAuth.signed_in_path(conn))
        end
    end
  end
end
