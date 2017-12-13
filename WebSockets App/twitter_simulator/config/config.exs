# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :twitter_simulator,
  ecto_repos: [TwitterSimulator.Repo]

# Configures the endpoint
config :twitter_simulator, TwitterSimulatorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BITkT8PUtRnzdKqNgOuSNlwqZt66mj86qqwcwWu2NYKgklNBDIbwTPKXoR/5sTda",
  render_errors: [view: TwitterSimulatorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterSimulator.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
