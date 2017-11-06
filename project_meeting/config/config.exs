# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :project_meeting,
  ecto_repos: [ProjectMeeting.Repo]

# Configures the endpoint
config :project_meeting, ProjectMeetingWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "UyBXZKmEa6LBJbJRVtckBeNko2p0i0ZrGHvo0o/F3boFChuFZM8L8le8UPP/6jhn",
  render_errors: [view: ProjectMeetingWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ProjectMeeting.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
