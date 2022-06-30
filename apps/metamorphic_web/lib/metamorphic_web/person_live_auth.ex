defmodule MetamorphicWeb.PersonLiveAuth do
  @moduledoc """
  This module facilitates the person authentication
  flow and the definition of plugs to be used in the `router.ex`
  for `live_session` calls.

  It should utilize sync with our `PersonAuth` controller that
  handles the authentication in our `plug` pipelines.
  """
  import Phoenix.LiveView

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.Person
  alias MetamorphicWeb.LiveHelpers
  alias MetamorphicWeb.Router.Helpers, as: Routes

  @admin_privilege :admin

  def on_mount(:marketing, _params, session, socket) do
    assign_unauthenticated_defaults(session, socket)
  end

  def on_mount(:pre_release, _params, session, socket) do
    assign_unauthenticated_defaults(session, socket)
  end

  def on_mount(:register, _params, session, socket) do
    assign_unauthenticated_or_redirect_defaults(session, socket)
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)
    opts = []

    if socket.assigns.current_person.confirmed_at do
      {:cont,
       socket
       |> MetamorphicWeb.PersonAuth.require_active_subscription(opts)}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:subscription, _params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)
    opts = []

    if socket.assigns.current_person.confirmed_at do
      {:cont,
       socket
       |> MetamorphicWeb.PersonAuth.redirect_if_person_has_subscription(opts)}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:redirect_if_admin, _params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)
    opts = []

    if socket.assigns.current_person.confirmed_at do
      {:cont,
       socket
       |> MetamorphicWeb.PersonAuth.redirect_if_admin(opts)}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:admin, _params, session, socket) do
    socket = LiveHelpers.assign_defaults(session, socket)

    if socket.assigns.current_person.confirmed_at do
      ensure_admin(session, socket)
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  # Used for unauthenticated pages like marketing and pre_release.
  defp assign_unauthenticated_defaults(session, socket) do
    case session do
      %{"person_id" => person_id} ->
        {:cont, assign_new(socket, :current_person, fn -> Accounts.get_person!(person_id) end)}

      _other ->
        {:cont, assign(socket, :current_person, nil)}
    end
  end

  # Used for the registration page currently (perhaps more later).
  # Assigns unauthenticated defaults or redirects of authenticated.
  defp assign_unauthenticated_or_redirect_defaults(session, socket) do
    case session do
      %{"person_id" => person_id} ->
        {:cont,
         socket
         |> assign_new(:current_person, fn -> Accounts.get_person!(person_id) end)
         |> put_flash(
           :info,
           "You're currently signed in. If you'd like to make a new account, then please log out first."
         )
         |> redirect(to: Routes.dashboard_path(socket, :index))}

      _other ->
        {:cont, assign(socket, :current_person, nil)}
    end
  end

  # Calls out to our `MetamorphicWeb.Plugs.EnsurePrivilege` plug
  # to check that the current_person in the current session
  # has `:admin` privileges.
  defp ensure_admin(session, socket) do
    if check_current_person_in_session(session, @admin_privilege) do
      {:cont, socket}
    else
      {:cont,
       socket
       |> put_flash(:warning, "Woops, that page doesn't exist or you're not authorized.")
       |> redirect(to: Routes.dashboard_path(socket, :index))}
    end
  end

  defp check_current_person_in_session(session, privileges) do
    person_token = Map.get(session, "person_token")

    (person_token &&
       Accounts.get_person_by_session_token(person_token))
    |> has_privilege?(privileges)
  end

  defp has_privilege?(%Person{privileges: privilege}, privilege), do: true
  defp has_privilege?(_person, _privilege), do: false
end
