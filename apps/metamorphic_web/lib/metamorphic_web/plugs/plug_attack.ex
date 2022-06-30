defmodule MetamorphicWeb.Plugs.PlugAttack do
  @moduledoc false
  use PlugAttack
  import Plug.Conn

  @alg :sha512
  @ip_secret System.fetch_env!("PLUG_ATTACK_IP_SECRET")

  rule "allow local", conn do
    allow(conn.remote_ip == {127, 0, 0, 1})
  end

  rule "fail2ban by ip", conn do
    fail2ban(hash_ip(@alg, convert_ip(conn.remote_ip)),
      period: 60_000,
      limit: 100,
      ban_for: 3_600_000,
      storage: {PlugAttack.Storage.Ets, MetamorphicWeb.PlugAttack.Storage}
    )
  end

  def allow_action(conn, {:throttle, data}, opts) do
    conn
    |> add_throttling_headers(data)
    |> allow_action(true, opts)
  end

  def allow_action(conn, _data, _opts) do
    conn
  end

  def block_action(conn, {:throttle, data}, opts) do
    conn
    |> add_throttling_headers(data)
    |> block_action(false, opts)
  end

  def block_action(conn, _data, _opts) do
    conn
    |> send_resp(:forbidden, "Forbidden\n")
    # It's important to halt connection once we send a response early
    |> halt
  end

  defp add_throttling_headers(conn, data) do
    # The expires_at value is a unix time in milliseconds, we want to return one
    # in seconds
    reset = div(data[:expires_at], 1_000)

    conn
    |> put_resp_header("x-ratelimit-limit", to_string(data[:limit]))
    |> put_resp_header("x-ratelimit-remaining", to_string(data[:remaining]))
    |> put_resp_header("x-ratelimit-reset", to_string(reset))
  end

  defp hash_ip(alg, ip) do
    :crypto.mac(:hmac, alg, @ip_secret, ip)
  end

  defp convert_ip(ip) do
    ip
    |> Tuple.to_list()
    |> List.to_charlist()
    |> IO.chardata_to_string()
  end
end
