defmodule MetamorphicWeb.PersonResetPasswordController do
  use MetamorphicWeb, :controller

  alias Metamorphic.Accounts

  plug :get_person_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html", page_title: "Reset account password")
  end

  # def create(conn, %{"person" => %{"email" => email}}) do
  #  if person = Accounts.get_person_by_email(email) do
  #    Accounts.deliver_person_reset_password_instructions(
  #      person,
  #      email,
  #      &Routes.person_reset_password_url(conn, :edit, &1)
  #    )
  #  end

  # Regardless of the outcome, show an impartial success/error message.
  #  conn
  #  |> put_flash(
  #    :info,
  #    "If your email is in our system, you will receive instructions to reset your password shortly."
  #  )
  #  |> redirect(to: "/")
  # end

  # def edit(conn, _params) do
  #  render(conn, MetamorphicWeb.Live.PersonResetPassword.Edit, changeset: Accounts.change_person_password(conn.assigns.person))
  # end

  # Do not log in the person after reset password to avoid a
  # leaked token giving the person access to the account.
  def update(conn, %{"person" => person_params}) do
    case Accounts.reset_person_password(conn.assigns.person, person_params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Password reset successfully.")
        |> redirect(to: Routes.person_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, MetamorphicWeb.Live.PersonResetPassword.Edit, changeset: changeset)
    end
  end

  defp get_person_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if person = Accounts.get_person_by_reset_password_token(token) do
      conn |> assign(:person, person) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
