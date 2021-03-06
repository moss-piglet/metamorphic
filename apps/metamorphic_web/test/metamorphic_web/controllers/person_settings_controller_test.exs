defmodule MetamorphicWeb.PersonSettingsControllerTest do
  use MetamorphicWeb.ConnCase, async: true

  alias Metamorphic.Accounts
  import Metamorphic.AccountsFixtures

  setup :register_and_log_in_person

  describe "GET /people/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.person_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if person is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.person_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.person_session_path(conn, :new)
    end
  end

  describe "PUT /people/settings  (change password form)" do
    test "updates the person password and resets tokens", %{conn: conn, person: person} do
      new_password_conn =
        put(conn, Routes.person_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_person_password(),
          "person" => %{
            "password" => "new Valid password!",
            "password_confirmation" => "new Valid password!"
          }
        })

      assert redirected_to(new_password_conn) == Routes.person_settings_path(conn, :edit)
      assert get_session(new_password_conn, :person_token) != get_session(conn, :person_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_person_by_email_and_password(person.email, "new Valid password!")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.person_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "person" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "at least one digit or punctuation character"
      assert response =~ "at least one upper case character"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :person_token) == get_session(conn, :person_token)
    end
  end

  describe "PUT /people/settings (change email form)" do
    @tag :capture_log
    test "updates the person email", %{conn: conn, person: person} do
      conn =
        put(conn, Routes.person_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_person_password(),
          "person" => %{"email" => unique_person_email()}
        })

      assert redirected_to(conn) == Routes.person_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Accounts.get_person_by_email(person.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.person_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "person" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /people/settings/confirm_email/:token" do
    setup %{person: person} do
      email = unique_person_email()

      token =
        extract_person_token(fn url ->
          Accounts.deliver_update_email_instructions(%{person | email: email}, person.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the person email once", %{
      conn: conn,
      person: person,
      token: token,
      email: email
    } do
      conn = get(conn, Routes.person_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.person_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Accounts.get_person_by_email(person.email)
      assert Accounts.get_person_by_email(email)

      conn = get(conn, Routes.person_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.person_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, person: person} do
      conn = get(conn, Routes.person_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.person_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Accounts.get_person_by_email(person.email)
    end

    test "redirects if person is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.person_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.person_session_path(conn, :new)
    end
  end
end
