defmodule CoinbotWeb.PageController do
  use CoinbotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def privacy_policy(conn, _params) do
    render(conn, "index.html")
  end

  def service_url(conn, _params) do
    render(conn, "index.html")
  end
end
