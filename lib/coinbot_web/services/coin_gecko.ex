defmodule CoinbotWeb.Services.CoinGecko do
  @moduledoc false

  @base_uri "https://api.coingecko.com/api/v3"

  @doc """
    Search for coins.
  """
  def search_coin(query, type) do
    headers = [{"Content-type", "application/json"}]

    case HTTPoison.get("#{@base_uri}/coins/list") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        coins = Jason.decode!(body)
        selected_coins = Enum.filter(coins, &(String.starts_with?(&1[type], query)))
        Enum.take(selected_coins, 5)
      {:error, %HTTPoison.Error{reason: reason}} ->
        []
    end
  end

  @doc """
    Get coin info.
  """
  def get_coin(coin_id) do
    headers = [{"Content-type", "application/json"}]
    {:ok, response} = HTTPoison.get("#{@base_uri}/coins/" <> coin_id)

    Jason.decode!(response.body)
  end

  @doc """
    Get coin market data.
    @default_param currency: "usd", interval: "daily", days: 14
  """
  def get_coin_market_data(coin_id) do
    headers = [{"Content-type", "application/json"}]

    case HTTPoison.get("#{@base_uri}/coins/"<> coin_id <> "/market_chart?vs_currency=USD&days=14&interval=daily") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        %{}
    end
  end
end