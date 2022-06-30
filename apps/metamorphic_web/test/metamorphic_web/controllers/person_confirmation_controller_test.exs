defmodule MetamorphicWeb.PersonConfirmationControllerTest do
  use MetamorphicWeb.ConnCase, async: true

  alias Metamorphic.Accounts
  alias Metamorphic.Repo
  import Metamorphic.AccountsFixtures

  setup do
    %{person: person_fixture(%{}, confirmed: false)}
  end

  describe "GET /persons/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.person_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /persons/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, person: person} do
      conn =
        post(conn, Routes.person_confirmation_path(conn, :create), %{
          "person" => %{"email" => person.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.PersonToken, person_id: person.id).context == "confirm"
    end

    test "does not send confirmation token if account is confirmed", %{conn: conn, person: person} do
      Repo.update!(Accounts.Person.confirm_changeset(person))

      conn =
        post(conn, Routes.person_confirmation_path(conn, :create), %{
          "person" => %{"email" => person.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Accounts.PersonToken, person_id: person.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.person_confirmation_path(conn, :create), %{
          "person" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.PersonToken) == []
    end
  end

  describe "GET /persons/confirm/:token" do
    test "confirms the given token once", %{conn: conn, person: person} do
      token =
        extract_person_token(fn url ->
          Accounts.deliver_person_confirmation_instructions(person, url)
        end)

      conn = get(conn, Routes.person_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Account confirmed successfully"
      assert Accounts.get_person!(person.id).confirmed_at
      refute get_session(conn, :person_token)
      assert Repo.all(Accounts.PersonToken) == []

      # When not logged in
      conn = get(conn, Routes.person_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Account confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_person(person)
        |> get(Routes.person_confirmation_path(conn, :confirm, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, person: person} do
      conn = get(conn, Routes.person_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Account confirmation link is invalid or it has expired"
      refute Accounts.get_person!(person.id).confirmed_at
    end
  end
end
