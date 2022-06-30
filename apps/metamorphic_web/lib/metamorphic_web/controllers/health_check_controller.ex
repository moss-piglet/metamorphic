defmodule MetamorphicWeb.HealthCheckController do
  @moduledoc """
  This controller facilitates health checks currently
  with Render to enable zero-downtime-deploys.
  """
  use MetamorphicWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end
end
