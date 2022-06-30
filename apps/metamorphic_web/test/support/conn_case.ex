defmodule MetamorphicWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MetamorphicWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import MetamorphicWeb.ConnCase

      alias MetamorphicWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint MetamorphicWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Metamorphic.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Metamorphic.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in people.

      setup :register_and_log_in_person

  It stores an updated connection and a registered person in the
  test context.
  """
  def register_and_log_in_person(%{conn: conn}) do
    {person, _temp_email, _temp_name, _temp_pseudonym} =
      Metamorphic.AccountsFixtures.person_fixture()

    person_password = Metamorphic.AccountsFixtures.valid_person_password()
    %{key: key} = Metamorphic.Accounts.Person.valid_key_hash?(person, person_password)
    %{conn: log_in_person(conn, person), person: person, key: key}
  end

  @doc """
  Logs the given `person` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_person(conn, person) do
    token = Metamorphic.Accounts.generate_person_session_token(person)
    person_password = Metamorphic.AccountsFixtures.valid_person_password()
    %{key: key} = Metamorphic.Accounts.Person.valid_key_hash?(person, person_password)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:person_token, token)
    |> Plug.Conn.put_session(:key, key)
  end
end
