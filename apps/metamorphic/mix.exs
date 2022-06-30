defmodule Metamorphic.MixProject do
  use Mix.Project

  def project do
    [
      app: :metamorphic,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Metamorphic.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:argon2_elixir, "~> 2.0"},
      {:bamboo, "~> 2.0"},
      {:bamboo_phoenix, "~> 1.0"},
      {:gen_smtp, "~> 1.2"},
      {:premailex, "~> 0.3.0"},
      {:cloak, "~> 1.1"},
      {:cloak_ecto, "~> 1.2"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ecto, " ~> 3.7"},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.7"},
      {:enacl, github: "jlouis/enacl"},
      {:eqrcode, "~> 0.1.7"},
      {:jason, "~> 1.0"},
      {:nimble_totp, github: "dashbitco/nimble_totp"},
      {:postgrex, ">= 0.0.0"},
      {:pwned_coretheory, "~> 1.5"},
      {:sobelow, "~> 0.11.0", only: :dev},
      {:oban, "~> 2.7"},
      {:stripity_stripe, "~> 2.10"},
      {:zxcvbn, "~> 0.1.3"},
      {:libcluster, "~> 3.3"},
      {:csv, "~> 2.4"},
      {:benchee, "~> 1.1", only: :dev},
      {:tesla, "~> 1.4.3"},
      {:query_builder, "~> 1.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
