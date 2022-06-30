defmodule MetamorphicWeb.Plugs.VerifyPortalPass do
  @moduledoc """
  A plug to verify the correct portal pass for the current person.

  If a person attempts to access a portal without the correct portal
  pass, then they will be redirected back to the portal index. This
  also defaults to allow the `require_authenticated_person` plug to
  run its checks first.
  """
  import Plug.Conn

  alias Phoenix.Controller

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.Person
  alias Metamorphic.Constructor
  alias Metamorphic.Encrypted

  alias Metamorphic.Constructor.Portal
  alias MetamorphicWeb.Router.Helpers, as: Routes

  def init(config), do: config

  def call(conn, _config) do
    person_token = get_session(conn, :person_token)
    session_key = get_session(conn, :key)

    (person_token &&
       Accounts.get_person_by_session_token(person_token))
    |> has_portal_pass?(conn.path_params, session_key)
    |> maybe_halt(conn)
  end

  defp has_portal_pass?(%Person{} = person, %{"slug" => slug}, session_key)
       when is_struct(person) and is_binary(slug) do
    verify_portal_pass(person, slug, session_key)
  end

  defp has_portal_pass?(_person, _slug, _session_key), do: false

  defp verify_portal_pass(person, slug, session_key) do
    case valid_portal_or_shared_portal_pass?(person, slug, session_key) do
      true ->
        true

      _ ->
        false
    end
  end

  defp valid_portal_or_shared_portal_pass?(person, slug, session_key) do
    case Constructor.get_portal(slug) do
      %Portal{} = portal ->
        if portal.person_id == person.id && valid_portal_pass?(portal, person, session_key) do
          true
        else
          shared_portal =
            Constructor.get_shared_portal_by_slug_and_current_person_id(slug, person.id)

          if shared_portal && shared_portal.person_id == person.id &&
               valid_shared_portal_pass?(portal, shared_portal, person, session_key) do
            true
          else
            false
          end
        end

      nil ->
        false

      _ ->
        false
    end
  end

  defp valid_portal_pass?(portal, person, session_key) do
    case decrypt_portal_pass(portal, person, session_key) do
      "Invalid authentication" ->
        false

      decrypted_portal_pass ->
        case valid_portal_pass?(decrypted_portal_pass, portal.hashed_portal_pass) do
          true ->
            true

          _ ->
            false
        end
    end
  end

  defp valid_shared_portal_pass?(portal, shared_portal, person, session_key) do
    case decrypt_shared_portal_pass(shared_portal, person, session_key) do
      "Invalid authentication" ->
        false

      decrypted_shared_portal_pass ->
        case valid_portal_pass?(decrypted_shared_portal_pass, portal.hashed_portal_pass) do
          true ->
            true

          _ ->
            false
        end
    end
  end

  defp valid_portal_pass?(password, hashed_password)
       when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  defp valid_portal_pass?(_, _) do
    Argon2.no_user_verify()
    false
  end

  defp decrypt_portal_pass(portal, person, session_key) do
    decrypted_portal_pass =
      Encrypted.Portals.Utils.decrypt_portal_data(
        portal.portal_pass,
        portal.person_key,
        person,
        session_key
      )

    decrypted_portal_pass
  end

  defp decrypt_shared_portal_pass(shared_portal, person, session_key) do
    decrypted_shared_portal_pass =
      Encrypted.Portals.Utils.decrypt_portal_data(
        shared_portal.portal_pass,
        shared_portal.person_key,
        person,
        session_key
      )

    decrypted_shared_portal_pass
  end

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_any, conn) do
    conn
    |> Controller.put_flash(
      :error,
      "That portal has not been constructed or your portal pass is invalid."
    )
    |> Controller.redirect(to: signed_in_path(conn))
    |> halt()
  end

  defp signed_in_path(conn), do: Routes.portal_path(conn, :index)
end
