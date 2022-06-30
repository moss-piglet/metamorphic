defmodule MetamorphicWeb.Plugs.EnsurePrivilege do
  @moduledoc """
  A plug to ensure a person has a specific privelege.

  If a person attempts to access a part of the application
  without the proper privilege, then the connection will be halted
  and they will be redirected to the signed_in_path/1 of the connection.
  """
  import Plug.Conn

  alias Phoenix.Controller
  alias Plug.Conn

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.Person
  alias MetamorphicWeb.Router.Helpers, as: Routes

  @doc false
  @spec init(any()) :: any()
  def init(config), do: config

  @doc false
  @spec call(Conn.t(), atom() | [atom()]) :: Conn.t()
  def call(conn, privileges) do
    person_token = get_session(conn, :person_token)

    (person_token &&
       Accounts.get_person_by_session_token(person_token))
    |> has_privilege?(privileges)
    |> maybe_halt(conn)
  end

  defp has_privilege?(%Person{} = person, privileges) when is_list(privileges),
    do: Enum.any?(privileges, &has_privilege?(person, &1))

  defp has_privilege?(%Person{privileges: privilege}, privilege), do: true
  defp has_privilege?(_person, _privilege), do: false

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_any, conn) do
    conn
    |> Controller.put_flash(:warning, "Woops, that page doesn't exist or you're not authorized.")
    |> Controller.redirect(to: signed_in_path(conn))
    |> halt()
  end

  defp signed_in_path(conn), do: Routes.dashboard_path(conn, :index)
end
