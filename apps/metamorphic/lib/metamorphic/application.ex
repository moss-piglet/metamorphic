defmodule Metamorphic.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Metamorphic.Repo,
      # Start the Cloak vault.
      Metamorphic.Vault
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Metamorphic.Supervisor)
  end
end
