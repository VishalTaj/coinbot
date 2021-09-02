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
      cond do
      Map.has_key?(event, "message") ->
        %{"message" => message, "sender" => %{"id" => id}} = event
        Survey.get_questions(id, message)
      Map.has_key?(event, "postback") ->
        %{"postback" => %{ "payload" => message }, "sender" => %{"user_ref" => id}} = event
        if message == "STARTUP" do
          Survey.get_questions(id, %{})
        end
      true ->
        "do nothing"
      end
      
    end)

    text conn, "EVENT_RECEIVED"
  end

  @doc """
    This action will send message to the Facebook App
  """
  def send_message(conn, _params) do
    %{"psid" => id, "message" => message} = _params
    {:ok, response} = CoinbotWeb.Services.Messenger.send_message(id, message)
    resp_body = Jason.encode!(response.body)

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
      send_resp(conn, 200, challenge)
    else
      IO.inspect("Unauthorized echo")
      send_resp(conn, 403, "Unauthorized")
    end
  end

  def search_coin(conn, _params) do
    coins = CoinGecko.search_coin(_params["query"], Map.get(_params, "type", "id"))
    # 3684472808319284 "109656651425367"
    IO.inspect(coins)
    CoinbotWeb.Services.Messenger.template_list("3684472808319284", coins)
    render conn, "search_coin.json", %{coins: coins}
  end

  def get_coin(conn, _params) do
    coin = CoinGecko.get_coin(_params["id"])
    render conn, "get_coin.json", %{coin: coin}
  end

  def market_chart(conn, _params) do
    charts = CoinGecko.get_coin_market_data(_params["id"])

    CoinbotWeb.Services.Messenger.market_list("3684472808319284", charts["prices"])
    send_resp(conn, 200, "success")
  end
end
