defmodule MetamorphicWeb.GlobalPrivacyController do
  @moduledoc """
  This controller facilitates the Global Privacy Control
  `well-known` json file.
  """
  use MetamorphicWeb, :controller

  def global_privacy_response(conn, _params) do
    gpc_response = %{gpc: true, version: 1}
    json(conn, gpc_response)
  end
end
