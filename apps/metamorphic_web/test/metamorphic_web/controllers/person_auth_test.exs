defmodule MetamorphicWeb.PersonAuthTest do
  use MetamorphicWeb.ConnCase, async: true

  alias Metamorphic.Accounts
  alias MetamorphicWeb.PersonAuth
  import Metamorphic.AccountsFixtures

  @remember_me_cookie "_metamorphic_web_person_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, MetamorphicWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    {person, _temp_email, _temp_name, _temp_pseudonym} = person_fixture()
    password = valid_person_password()
    %{person: person, conn: conn, password: password}
  end

  describe "log_in_person/3" do
    test "stores the person token and encryption key in the session", %{
      conn: conn,
      person: person,
      password: password
    } do
      conn = PersonAuth.log_in_person(conn, person, password)
      assert token = get_session(conn, :person_token)
      assert key = get_session(conn, :key)
      assert get_session(conn, :live_socket_id) == "people_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/dashboard"
      assert Accounts.get_person_by_session_token(token)
      assert {:ok, _} = key
    end

    test "clears everything previously stored in the session", %{conn: conn, person: person} do
      conn = conn |> put_session(:to_be_removed, "value") |> PersonAuth.log_in_person(person)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, person: person, password: password} do
      conn =
        conn
        |> put_session(:person_return_to, "/hello")
        |> PersonAuth.log_in_person(person, password)

      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{
      conn: conn,
      person: person,
      password: password
    } do
      conn =
        conn
        |> fetch_cookies()
        |> PersonAuth.log_in_person(person, password, %{"remember_me" => "true"})

      assert get_session(conn, :person_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :person_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_person/1" do
    test "erases session and cookies", %{conn: conn, person: person, password: password} do
      person_token = Accounts.generate_person_session_token(person)
      %{key: key} = Accounts.Person.valid_key_hash?(person, password)

      conn =
        conn
        |> put_session(:person_token, person_token)
        |> put_session(:key, key)
        |> put_req_cookie(@remember_me_cookie, person_token)
        |> fetch_cookies()
        |> PersonAuth.log_out_person()

      refute get_session(conn, :person_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/people/log_in"
      refute Accounts.get_person_by_session_token(person_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "people_sessions:abcdef-token"
      MetamorphicWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> PersonAuth.log_out_person()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "people_sessions:abcdef-token"
      }
    end

    test "works even if person is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> PersonAuth.log_out_person()
      refute get_session(conn, :person_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/people/log_in"
    end
  end

  describe "fetch_current_person/2" do
    test "authenticates person from session", %{conn: conn, person: person} do
      person_token = Accounts.generate_person_session_token(person)

      conn =
        conn |> put_session(:person_token, person_token) |> PersonAuth.fetch_current_person([])

      assert conn.assigns.current_person.id == person.id
    end

    test "authenticates person from cookies", %{conn: conn, person: person, password: password} do
      logged_in_conn =
        conn
        |> fetch_cookies()
        |> PersonAuth.log_in_person(person, password, %{"remember_me" => "true"})

      person_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> PersonAuth.fetch_current_person([])

      assert get_session(conn, :person_token) == person_token
      assert conn.assigns.current_person.id == person.id
    end

    test "does not authenticate if data is missing", %{conn: conn, person: person} do
      _ = Accounts.generate_person_session_token(person)
      conn = PersonAuth.fetch_current_person(conn, [])
      refute get_session(conn, :person_token)
      refute conn.assigns.current_person
    end
  end

  describe "redirect_if_person_is_authenticated/2" do
    test "redirects if person is authenticated", %{conn: conn, person: person} do
      conn =
        conn
        |> assign(:current_person, person)
        |> PersonAuth.redirect_if_person_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == "/dashboard"
    end

    test "does not redirect if person is not authenticated", %{conn: conn} do
      conn = PersonAuth.redirect_if_person_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_person/2" do
    test "redirects if person is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> PersonAuth.require_authenticated_person([])
      assert conn.halted
      assert redirected_to(conn) == Routes.person_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page or it does not exist."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> PersonAuth.require_authenticated_person([])

      assert halted_conn.halted
      assert get_session(halted_conn, :person_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> PersonAuth.require_authenticated_person([])

      assert halted_conn.halted
      assert get_session(halted_conn, :person_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> PersonAuth.require_authenticated_person([])

      assert halted_conn.halted
      refute get_session(halted_conn, :person_return_to)
    end

    test "does not redirect if person is authenticated", %{conn: conn, person: person} do
      conn =
        conn |> assign(:current_person, person) |> PersonAuth.require_authenticated_person([])

      refute conn.halted
      refute conn.status
    end
  end

  import Metamorphic.BillingFixtures

  describe "require_active_subscription/2" do
    test "does nothing when person is not logged in", %{conn: conn, person: person} do
      active_subscription_fixture(person)
      conn = conn |> fetch_flash() |> PersonAuth.require_active_subscription([])

      refute conn.halted
    end

    test "does nothing when person logged in with active subscription", %{
      conn: conn,
      person: person,
      password: password
    } do
      active_subscription_fixture(person)

      conn =
        PersonAuth.log_in_person(conn, person, password)
        |> PersonAuth.require_active_subscription([])

      refute conn.halted
    end
  end
end
