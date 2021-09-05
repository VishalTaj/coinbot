defmodule CoinbotWeb.MessengerController do
  use CoinbotWeb, :controller

  alias CoinbotWeb.Services.Survey
  alias CoinbotWeb.Services.CoinGecko
  alias Coinbot.{Repo, Conversation}

  import Ecto.Query 


  def index(conn, _params) do
    render conn, "index.json", _params
  end

  @doc """
    Facebook Triggers this webhook based on Messenger Subscription
  """
  def receive_message(conn, _params) do
    %{"entry" => entries} = _params
    IO.inspect(entries)

    rule_based_parser(entries)

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

  # def search_coin(conn, _params) do
  #   coins = CoinGecko.search_coin(_params["query"], Map.get(_params, "type", "id"))
  #   CoinbotWeb.Services.Messenger.template_list("3684472808319284", coins)
  #   render conn, "search_coin.json", %{coins: coins}
  # end

  # def get_coin(conn, _params) do
  #   coin = CoinGecko.get_coin(_params["id"])
  #   render conn, "get_coin.json", %{coin: coin}
  # end

  # def market_chart(conn, _params) do
  #   charts = CoinGecko.get_coin_market_data(_params["coin_id"])
  #   sender_id = _params["sender_id"]
  #   CoinbotWeb.Services.Messenger.market_list(sender_id, charts["prices"], _params["coin_id"])
  #   Repo.update_all((from c in Conversation, where: c.sender_id == ^sender_id), set: [step: 1, last_answer: "", last_question: ""])
  #   send_resp(conn, 200, "success")
  # end

  # below is the helper function for the webhook

  defp rule_based_parser(entries) do
    Enum.each(entries, fn entry ->
      event = Map.get(entry, "messaging") |> Enum.at(0)
      id =  Map.get(event["sender"], "id") || Map.get(event["sender"], "user_ref")
      conversation = (from c in Conversation, where: c.sender_id == ^id) |> Repo.one()
      
      cond do
      Map.has_key?(event, "message") ->
        %{"message" => message, "sender" => %{"id" => id}} = event

        # create a record if there is no existing conversation
        if conversation == nil do
          conversation = init_conversation(id, message)
        end

        if Map.has_key?(message, "quick_reply") do
          %{"quick_reply" => %{"payload" => payload} } = message
          cond do
          payload == "SELECTED_ID" or payload == "SELECTED_NAME" ->
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [last_question: message["text"], step: 2])
            get_questions(id, message)
          payload == "SELECTED_YES" ->
            CoinbotWeb.Services.Messenger.send_message(id, "Please search for a coin.")
          payload == "SELECTED_NO" ->
            CoinbotWeb.Services.Messenger.send_message(id, "Thank you for using Coinbot.")
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [step: 1, last_answer: "", last_question: ""])
          end
        else
          cond do
          conversation.step == 2 ->
            parse_response(id, message["text"], conversation)
            CoinbotWeb.Services.Messenger.quick_replies(id, CoinbotWeb.Services.Survey.qboolean(), "Do you want to continue search?")
          true ->
            get_questions(id, message)
          end
        end
      Map.has_key?(event, "postback") ->
        # this is a callback section
        %{"postback" => %{ "payload" => message }, "sender" => sender} = event
        id =  Map.get(sender, "id") || Map.get(sender, "user_ref")
        cond do
          message == "STARTUP" ->
            # CoinbotWeb.Services.Messenger.send_message(id, "Welcome to Coinbot.")
            ""
          message == "DEVELOPER_RESTART" ->
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [step: 1, last_answer: "", last_question: ""])
            get_questions(id, %{})
          message == "Hi" ->
            init_conversation(id, %{text: "Hi"})
          String.starts_with?(message, "MARKETCHART_") ->
            pat = String.split(message, "_")
            coin_id = pat |> Enum.at(1)
            sender_id = pat |> Enum.at(2)
            charts = CoinGecko.get_coin_market_data(coin_id)
            CoinbotWeb.Services.Messenger.market_list(sender_id, charts["prices"], coin_id)
            # Repo.update_all((from c in Conversation, where: c.sender_id == ^sender_id), set: [step: 1, last_answer: "", last_question: ""])
            CoinbotWeb.Services.Messenger.quick_replies(id, CoinbotWeb.Services.Survey.qboolean(), "Do you want to continue search?")
          true ->
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [last_question: message["id"], step: 2])
        end
      true ->
        "do nothing"
      end
      
    end)
    
  end

  defp parse_response(id, message, conversation) do
    cond do
    conversation.last_question == "By Id" ->
      CoinbotWeb.Services.Survey.search_by_id(id, message)
    conversation.last_question == "By name" ->
      CoinbotWeb.Services.Survey.search_by_name(id, message)
    message == "restart" ->
      Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [step: 1, last_answer: "", last_question: ""])
    true ->
      CoinbotWeb.Services.Messenger.send_message(id, "Sorry, I don't understand. Please try again.")
    end
  end

  defp get_questions(id, message) do
    Survey.get_questions(id, message)
  end

  defp init_conversation(id, message) do
    conv = Repo.insert(%Conversation{sender_id: id, step: 1, last_answer: message["text"]})
    CoinbotWeb.Services.Messenger.send_message(id, "Hi, I'm Coinbot. I can help you find the best cryptocurrency for you.")
    CoinbotWeb.Services.Messenger.initiate_chat_settings(id)
    CoinbotWeb.Services.Messenger.send_message(id, "Help: Click on Menu option to show more options.")
    conv
  end
end
