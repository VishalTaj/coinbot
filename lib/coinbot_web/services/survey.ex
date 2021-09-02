defmodule CoinbotWeb.Services.Survey do
  @moduledoc false

  # def surveys(survey, params) do
  #   apply(CoinbotWeb.Services.Survey, survey, params)
  # end


  def get_selections(id, params) do
    CoinbotWeb.Services.Messenger.quick_replies(id, q1(), "search coins by name or by ID?")
  end


  def get_questions(id, message) do
    if !Map.has_key?(message, "quick_reply") do
      CoinbotWeb.Services.Messenger.quick_replies(id, q1(), "search coins by name or by ID?")
    else
      %{ "quick_reply" => %{ "payload" => query_id }} = message

      cond do
      query_id == "SELECTED_ID" ->
        selection_response(id, "Awesome now please type ID:")
      query_id == "SELECTED_NAME" ->
        selection_response(id, "Awesome now please type Name:")
      true ->
        "do nothing"
      end
    end
  end

  def q1() do
    [
      %{
        content_type: "text",
        title: "By Id",
        payload: "SELECTED_ID",
      }, %{
        content_type: "text",
        title: "By name",
        payload: "SELECTED_NAME",
      }
    ]
  end

  def selection_response(id, message) do
    CoinbotWeb.Services.Messenger.send_message(id, message)
  end

  def search_by_name(id, query) do
    coins = CoinbotWeb.Services.CoinGecko.search_coin(query, "id")
    CoinbotWeb.Services.Messenger.template_list(id, coins)
  end

  def search_by_id(id, query) do
    coins = CoinbotWeb.Services.CoinGecko.search_coin(query, "name")
    CoinbotWeb.Services.Messenger.template_list(id, coins)
  end
end