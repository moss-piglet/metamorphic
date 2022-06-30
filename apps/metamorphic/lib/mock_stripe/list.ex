defmodule MockStripe.List do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe data list struct.
  """
  defstruct data: [], has_more: false, object: "list", total_count: nil, url: nil
end
