defmodule CoinbotWeb.Router do
  use CoinbotWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CoinbotWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/privacy_policy", PageController, :privacy_policy
    get "/service_url", PageController, :service_url
  end

  # Other scopes may use custom stacks.
  scope "/api", CoinbotWeb do
    pipe_through :api

    get "/webhook", MessengerController, :verify
    post "/webhook", MessengerController, :receive_message
  end
end
