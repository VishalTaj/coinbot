defmodule CoinbotWeb.MessengerView do
  use CoinbotWeb, :view


  def render("index.json", _params) do
    %{
      status: _params["status"]
    }
  end

  def render("search_coin.json", %{coins: coins }) do
    %{ 
      coins: coins
    }
  end

  def render("get_coin.json", %{coin: coin }) do
    %{ 
      coin: coin
    }
  end
end
