# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :coinbot,
  ecto_repos: [Coinbot.Repo]

# Configures the endpoint
config :coinbot, CoinbotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HliFYkR+I17xwRl6hL3Md8qrj3W3upEQ4X3VPwf1i4q838btY8cK4RKYrobiys5D",
  render_errors: [view: CoinbotWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Coinbot.PubSub, adapter: Phoenix.PubSub.PG2,
  pool_size: 1 ],
  live_view: [signing_salt: "I/V4kDvt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
