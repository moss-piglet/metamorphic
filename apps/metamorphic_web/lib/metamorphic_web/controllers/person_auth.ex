defmodule MetamorphicWeb.PersonAuth do
  @moduledoc """
  This controller facilitates the person authentication
  flow and the definition of plugs to be used in the `router.ex`.
  """
  import Plug.Conn
  import Phoenix.Controller
  import MetamorphicWeb.Gettext

  alias Metamorphic.Accounts
  alias MetamorphicWeb.Router.Helpers, as: Routes

  defmodule NotAdminError do
    defexception plug_status: 404, message: "admin status is required to access this page"
  end

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in PersonToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_metamorphic_web_person_remember_me"
  @remember_me_options [encrypt: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the person in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_person(conn, person, password \\ nil) do
    token = Accounts.generate_person_session_token(person)

    case Accounts.Person.valid_key_hash?(person, password) do
      %{key: key} ->
        conn
        |> renew_session()
        |> put_session(:person_token, token)
        |> put_session(:key, key)
        |> put_session(:live_socket_id, "people_sessions:#{Base.url_encode64(token)}")

      _ ->
        conn
        |> renew_session()
        |> redirect(to: "/people/log_in")
    end
  end

  # defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
  #  put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  # end

  # defp maybe_write_remember_me_cookie(conn, _token, _params) do
  #  conn
  # end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Returns to or redirects home and potentially set remember_me token.
  """
  def redirect_person_after_login_with_remember_me(conn, params \\ %{}) do
    person_return_to = get_session(conn, :person_return_to)

    conn
    |> maybe_remember_person(params)
    |> delete_session(:person_return_to)
    |> redirect(to: person_return_to || signed_in_path(conn))
  end

  defp maybe_remember_person(conn, %{"remember_me" => "true"}) do
    token = get_session(conn, :person_token)
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_remember_person(conn, _params) do
    conn
  end

  @doc """
  Logs the person out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_person(conn) do
    person_token = get_session(conn, :person_token)
    person_token && Accounts.delete_session_token(person_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      MetamorphicWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: Routes.person_session_path(conn, :new))
  end

  @doc """
  Authenticates the person by looking into the session
  and remember me token.
  """
  def fetch_current_person(conn, _opts) do
    {person_token, conn} = ensure_person_token(conn)
    person = person_token && Accounts.get_person_by_session_token(person_token)
    assign(conn, :current_person, person)
  end

  defp ensure_person_token(conn) do
    if person_token = get_session(conn, :person_token) do
      {person_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if person_token = conn.cookies[@remember_me_cookie] do
        {person_token, put_session(conn, :person_token, person_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the person to not be authenticated.
  """
  def redirect_if_person_is_authenticated(conn, _opts) do
    if conn.assigns[:current_person] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the person to be authenticated.

  If you want to enforce the person email is confirmed before
  they use the application at all, here would be a good place.
  """

  # def require_authenticated_person(conn, _opts) do
  #  if conn.assigns[:current_person] do
  #    conn
  #  else
  #    conn
  #    |> put_flash(:error, "You must log in to access this page.")
  #    |> maybe_store_return_to()
  #    |> redirect(to: Routes.person_session_path(conn, :new))
  #    |> halt()
  #  end
  # end

  def require_authenticated_person(conn, _opts) do
    cond do
      is_nil(conn.assigns[:current_person]) ->
        conn
        |> put_flash(:error, "You must log in to access this page or it does not exist.")
        |> maybe_store_person_return_to()
        |> maybe_redirect_to_register_or_log_in()
        |> halt()

      get_session(conn, :person_totp_pending) && conn.path_info != ["people", "totp"] &&
          conn.path_info != ["people", "log_out"] ->
        conn
        |> redirect(to: Routes.person_totp_path(conn, :new))
        |> halt()

      true ->
        conn
    end
  end

  def require_admin(conn, _opts) do
    if conn.assigns.current_person.privileges === :admin do
      conn
    else
      raise NotAdminError
    end
  end

  @doc """
  Used for re-routing the admin to admin specific pages to avoid
  accidentally leaking admin html to non-admin accounts.
  """
  def redirect_if_admin(conn, _opts) do
    if conn.assigns.current_person && conn.assigns.current_person.privileges === :admin do
      conn
      |> redirect(to: "/admin" <> conn.request_path)
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the person to be confirmed.
  """
  def require_confirmed_person(conn, _opts) do
    if conn.assigns[:current_person] do
      conn
    else
      conn
      |> put_flash(:error, gettext("You must be confirmed to access this page or it does not exist."))
      |> redirect(to: signed_in_path(conn.assigns[:current_person]))
      |> halt()
    end
  end

  @doc """
  Used for routes that require the person to be a admin
  """
  def require_admin_person(conn, _opts) do
    if conn.assigns[:current_person] && conn.assigns[:current_person].is_admin do
      conn
    else
      conn
      |> put_flash(:error, gettext("You do not have access to this page."))
      |> redirect(to: "/")
      |> halt()
    end
  end

  def kick_person_if_suspended_or_deleted(conn, opts \\ []) do
    if not is_nil(conn.assigns[:current_person]) and
         (conn.assigns[:current_person].is_suspended or
            conn.assigns[:current_person].is_deleted) do
      conn
      |> put_flash(
        :error,
        Keyword.get(opts, :flash, gettext("Your account is not accessible."))
      )
      |> log_out_person
      |> halt()
    else
      conn
    end
  end

  @doc """
  Stores return to in the session as long as it is a GET request
  and the person is not authenticated.
  """
  def maybe_store_person_return_to(conn, _opts) do
    maybe_store_person_return_to(conn)
  end

  def signed_in_path(conn), do: Routes.dashboard_path(conn, :index)

  defp maybe_store_person_return_to(%{assigns: %{current_person: %{}}} = conn), do: conn

  defp maybe_store_person_return_to(%{method: "GET"} = conn) do
    %{request_path: request_path, query_string: query_string} = conn
    return_to = if query_string == "", do: request_path, else: request_path <> "?" <> query_string
    put_session(conn, :person_return_to, return_to)
  end

  defp maybe_store_person_return_to(conn), do: conn

  defp maybe_redirect_to_register_or_log_in(conn) do
    if get_session(conn, :person_return_to) != nil do
      cond do
        conn.params === %{"interval" => "year", "product" => "Member Plan"} ->
          conn =
            conn
            |> redirect(to: Routes.person_registration_path(conn, :new))

          conn

        conn.params === %{"interval" => "month", "product" => "Member Plan"} ->
          conn =
            conn
            |> redirect(to: Routes.person_registration_path(conn, :new))

          conn

        true ->
          conn =
            conn
            |> redirect(to: Routes.person_session_path(conn, :new))

          conn
      end
    else
      conn =
        conn
        |> redirect(to: Routes.person_session_path(conn, :new))

      conn
    end
  end

  @doc """
  Used for routes that require the person to have an active subscription.

  Note that this first looks for a current_person and if that person has
  `:admin` privileges. If the current_person is not found, then it just
  returns the `conn` and expects `require_authenticated_person/2` to
  handle it.

  If the person has `:admin` privileges, then it returns the conn and expects
  `require_authenticated_person/2` to handle it.

  This checks for a subscription on every request but the result could be stored
  as a cookie.
  """
  def require_active_subscription(conn, _opts) do
    case conn.assigns[:current_person] do
      %{privileges: :admin} ->
        conn

      %{id: person_id} ->
        Metamorphic.Billing.get_active_or_trial_subscription_for_person(person_id)
        |> handle_inactive_subscription(conn)

      _ ->
        conn
    end
  end

  defp handle_inactive_subscription(%Metamorphic.Billing.Subscription{}, conn), do: conn

  defp handle_inactive_subscription(_, conn) do
    conn
    |> put_flash(
      :info,
      "You need an active or trial subscription to continue. You can download any existing data from your settings."
    )
    |> maybe_store_person_return_to()
    |> redirect(to: Routes.subscription_new_path(conn, :new))
    |> halt()
  end

  @doc """
  Used for routes that require a person to **not** have a subscription.
  Note that this first checks for a current_person like the
  `require_active_subscription` plug.
  """
  def redirect_if_person_has_subscription(conn, _opts) do
    case conn.assigns[:current_person] do
      %{id: person_id} ->
        Metamorphic.Billing.get_active_or_trial_subscription_for_person(person_id)
        |> handle_active_subscription(conn)

      _ ->
        conn
    end
  end

  defp handle_active_subscription(%Metamorphic.Billing.Subscription{}, conn) do
    conn
    |> maybe_store_person_return_to()
    |> put_flash(
      :info,
      "You already have an active subscription. To update or cancel your subscription, please go to the \"Billing\" section of your settings page."
    )
    |> redirect(to: Routes.dashboard_path(conn, :index))
    |> halt()
  end

  defp handle_active_subscription(_, conn), do: conn
end
