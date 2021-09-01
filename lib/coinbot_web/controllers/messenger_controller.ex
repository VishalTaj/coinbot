defmodule CoinbotWeb.MessengerController do
  use CoinbotWeb, :controller

  alias CoinbotWeb.Services.Survey
  alias CoinbotWeb.Services.CoinGecko

  def index(conn, _params) do
    render conn, "index.json", _params
  end

  @doc """
    Facebook Triggers this webhook based on Messenger Subscription
  """
  def receive_message(conn, _params) do
    %{"entry" => entries} = _params
    IO.inspect(entries)
    Enum.each(entries, fn entry ->
      event = Map.get(entry, "messaging") |> Enum.at(0)
      %{"message" => message, "sender" => %{"id" => id}} = event
      Survey.get_questions(id, message)
    end)

    text conn, "EVENT_RECEIVED"
  end

  @doc """
    This action will send message to the Facebook App
  """
  def send_message(conn, _params) do
    %{"psid" => id, "message" => message} = _params
    {:ok, response} = Chatbot.Services.Messenger.send_message(id, message)
    resp_body = Jason.encode!(response.body)
    # Base.render_json(conn, response.status_code || 200, resp_body)

    render conn, "send_message.json", resp_body
  end

  @doc """
    This action will take care of verifying the domain with Facebook App
  """
  def verify(conn, _params) do
    verify_token = System.get_env("TOKEN")
    %{"hub.mode" => mode, "hub.verify_token" => token, "hub.challenge" => challenge} = _params
    IO.inspect(verify_token)
    if (mode == "subscribe" and token == verify_token) do
      IO.inspect("Webhook verified")
      # Base.render_string(conn, 200, challenge)
      send_resp(conn, 200, challenge)
    else
      IO.inspect("Unauthorized echo")
      # Base.render_string(conn, 403, "Unauthorized")
      send_resp(conn, 403, "Unauthorized")
    end
  end

  def search_coin(conn, _params) do
    coins = CoinGecko.search_coin(_params["query"], Map.get(_params, "type", "id"))
    render conn, "search_coin.json", %{coins: coins}
  end

  def get_coin(conn, _params) do
    coin = CoinGecko.get_coin(_params["id"])
    render conn, "get_coin.json", %{coin: coin}
  end
end
