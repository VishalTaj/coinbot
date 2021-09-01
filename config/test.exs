use Mix.Config

# Configure your database
config :coinbot, Coinbot.Repo,
  username: "postgres",
  password: "postgres",
  database: "coinbot_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :coinbot, CoinbotWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
