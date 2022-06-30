defmodule MetamorphicWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :metamorphic_web,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      mod: {MetamorphicWeb.Application, []},
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
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.3"},
      {:phoenix_live_view, "~> 0.16"},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.11"},
      {:metamorphic, in_umbrella: true},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.2"},
      {:stun, "~> 1.0"},
      {:timex, "~> 3.7"},
      {:plug_content_security_policy, "~> 0.2.1"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.2"},
      {:sweet_xml, "~> 0.6"},
      {:hackney, "~> 1.17"},
      {:number, "~> 1.0"},
      {:cors_plug, "~> 2.0"},
      {:earmark, "~> 1.4"},
      {:remote_ip, "~> 1.0"},
      {:plug_attack, "~> 0.4.3"},
      {:petal_components, "~> 0.16"},
      {:blankable, "~> 1.0.0"},
      {:faker, git: "https://github.com/elixirs/faker"},
      {:slugify, "~> 1.3"},
      {:email_checker, "~> 0.2.4"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
