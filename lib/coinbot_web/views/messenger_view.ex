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
end
