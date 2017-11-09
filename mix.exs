defmodule ProjectMeetings.Mixfile do
  use Mix.Project

  def project do
    [
      app: :project_meetings,
      version: "0.0.3",
      elixir: "~> 1.5.2",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Docs
      name: "ProjectMeetings",
      homepage_url: "https://github.com/blakedgordon/ProjectMeetings-backend",
      docs: [main: "ProjectMeetings", # The main page in the docs
            extras: ["README.md"]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ProjectMeetings.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},

      {:ecto, "~> 2.0"},
      {:json_web_token, "~> 0.2"},
      {:httpoison, "~> 0.13"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:joken, "~> 1.1"},
      {:distillery, "~> 1.5"}
    ]
  end

end
