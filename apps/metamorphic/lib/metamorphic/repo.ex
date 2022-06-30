defmodule Metamorphic.Repo do
  use Ecto.Repo,
    otp_app: :metamorphic,
    adapter: Ecto.Adapters.Postgres,
    pool_size: 10

  # Setup for Render deployment in production.
  def init(_type, config) do
    {:ok, Keyword.put(config, :url, System.get_env("DATABASE_URL"))}
  end
end
