defmodule Coinbot.Repo do
  use Ecto.Repo,
    otp_app: :coinbot,
    adapter: Ecto.Adapters.Postgres
end
