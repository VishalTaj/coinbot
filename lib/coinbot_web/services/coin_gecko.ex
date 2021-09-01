defmodule CoinbotWeb.Services.CoinGecko do
  @moduledoc false

  @base_uri "https://api.coingecko.com/api/v3"

  def search_coin(query, type) do
    headers = [{"Content-type", "application/json"}]
    {:ok, response} = HTTPoison.get("#{@base_uri}/coins/list")

    coins = Jason.decode!(response.body)
    selected_coins = Enum.filter(coins, &(String.starts_with?(&1[type], query)))
    Enum.take(selected_coins, 5)
  end

  def get_coin(coin_id) do
    headers = [{"Content-type", "application/json"}]
    {:ok, response} = HTTPoison.get("#{@base_uri}/coins/" <> coin_id)

    Jason.decode!(response.body)
  end

  def get_coin_market_data(coin_id) do
    headers = [{"Content-type", "application/json"}]
    {:ok, response} = HTTPoison.get("#{@base_uri}/coins/"<> coin_id <> "/market_chart?vs_currency=USD&days=14&interval=daily")

    Jason.decode!(response.body)
  end
end