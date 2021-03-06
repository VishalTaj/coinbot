defmodule CoinbotWeb.Services.Survey do
  @moduledoc false

  @doc """
    Service which returns or trigger question for searching coins.
  """
  def get_questions(id, message) do
    if !Map.has_key?(message, "quick_reply") do
      CoinbotWeb.Services.Messenger.quick_replies(id, q1(), "Hey, please choose an option. You want to search coin by name or by ID?")
    else
      %{ "quick_reply" => %{ "payload" => query_id }} = message

      cond do
      query_id == "SELECTED_ID" ->
        selection_response(id, "Awesome, Now please type desired Coin ID:")
      query_id == "SELECTED_NAME" ->
        selection_response(id, "Awesome, Now please type desired Coin Name:")
      true ->
        CoinbotWeb.Services.Messenger.send_message(id, "Sorry, I didn't understand that. Please try again.")
      end
    end
  end

  @doc """
    Payload of 1st question
  """
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

  @doc """
    Payload of Yes or No question
  """
  def qboolean() do
    [
      %{
        content_type: "text",
        title: "Yes",
        payload: "SELECTED_YES",
      }, %{
        content_type: "text",
        title: "No",
        payload: "SELECTED_NO",
      }
    ]
  end

  @doc """
    Helper function to send reaction to user
  """
  def selection_response(id, message) do
    CoinbotWeb.Services.Messenger.send_message(id, message)
  end

  @doc """
    Helper function to search coin by name
  """
  def search_by_name(id, query) do
    coins = CoinbotWeb.Services.CoinGecko.search_coin(query, "name")
    
    if Enum.count(coins) > 0 do
      CoinbotWeb.Services.Messenger.template_list(id, coins)
    else
      CoinbotWeb.Services.Messenger.send_message(id, "Sorry, I couldn't find any coins with that name.")
    end
  end

  @doc """
    Helper function to search coin by id
  """
  def search_by_id(id, query) do
    coins = CoinbotWeb.Services.CoinGecko.search_coin(query, "id")
    if Enum.count(coins) > 0 do
      CoinbotWeb.Services.Messenger.template_list(id, coins)
    else
      CoinbotWeb.Services.Messenger.send_message(id, "Sorry, We couldn't find any coins with that ID.")
    end
  end
end