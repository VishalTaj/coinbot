defmodule CoinbotWeb.MessengerController do
  use CoinbotWeb, :controller

  alias CoinbotWeb.Services.{CoinGecko, Survey, Messenger}
  alias Coinbot.{Repo, Conversation}

  import Ecto.Query

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
    {:ok, response} = Messenger.send_message(id, message)
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

  # Below is the helper function for the webhooks

  @docp """
    This function will parse the incoming message and decide which action to take
  """
  defp rule_based_parser(entries) do
    Enum.each(entries, fn entry ->
      event = Map.get(entry, "messaging") |> Enum.at(0)
      id =  Map.get(event["sender"], "id") || Map.get(event["sender"], "user_ref")
      conversation = (from c in Conversation, where: c.sender_id == ^id) |> Repo.one()

      # create a record if there is no existing conversation
      if conversation == nil && !Map.get(event["sender"], "user_ref") do
        conversation = init_conversation(id, %{text: Map.get(event, "message", "Hi")})        
      end
      
      cond do
      Map.has_key?(event, "message") ->
        %{"message" => message, "sender" => %{"id" => id}} = event

        if Map.has_key?(message, "quick_reply") do
          %{"quick_reply" => %{"payload" => payload} } = message
          cond do
          payload in ["SELECTED_ID", "SELECTED_NAME"] ->
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [last_question: message["text"], step: 2])
            get_questions(id, message)
          payload == "SELECTED_YES" ->
            Messenger.send_message(id, "Please search for a coin.")
          payload == "SELECTED_NO" ->
            Messenger.send_message(id, "Thank you for using Coinbot.")
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [step: 1, last_answer: "", last_question: ""])
          end
        else
          cond do
          conversation.step == 2 ->
            parse_response(id, message["text"], conversation)
            Messenger.quick_replies(id, Survey.qboolean(), "Do you want to continue search?")
          String.contains? String.downcase(message["text"]), ["thank", "bye"] ->
            Messenger.send_message(id, "Thank you for using Coinbot.")
          true ->
            get_questions(id, message)
          end
        end
      Map.has_key?(event, "postback") ->
        # this is a callback section
        %{"postback" => %{ "payload" => message }, "sender" => sender} = event
        id =  Map.get(sender, "id") || Map.get(sender, "user_ref")
        cond do
          message in ["STARTUP", "Hi"] ->
            Messenger.send_message(id, "Hi... 👋,")
          message == "DEVELOPER_RESTART" ->
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [step: 1, last_answer: "", last_question: ""])
            get_questions(id, %{})
          String.starts_with?(message, "MARKETCHART_") ->
            pat = String.split(message, "_")
            coin_id = pat |> Enum.at(1)
            sender_id = pat |> Enum.at(2)
            charts = CoinGecko.get_coin_market_data(coin_id)
            Messenger.market_list(sender_id, charts["prices"], coin_id)
            Messenger.quick_replies(id, Survey.qboolean(), "Do you want to continue search?")
          true ->
            Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [last_question: message["id"], step: 2])
        end
      true ->
        "do nothing"
      end
      
    end)
    
  end

  @docp """
    This function will take care or coin search
  """
  defp parse_response(id, message, conversation) do
    cond do
    conversation.last_question == "By Id" ->
      Survey.search_by_id(id, message)
    conversation.last_question == "By name" ->
      Survey.search_by_name(id, message)
    message == "restart" ->
      Repo.update_all((from c in Conversation, where: c.sender_id == ^conversation.sender_id), set: [step: 1, last_answer: "", last_question: ""])
    true ->
      Messenger.send_message(id, "Sorry, I don't understand. Please try again.")
    end
  end

  @docp """
    This is a helper function to trigger search the questions
  """
  defp get_questions(id, message) do
    Survey.get_questions(id, message)
  end

  @docp """
    This is a helper function to initialize the conversation
  """
  defp init_conversation(id, message) do
    conv = Repo.insert(%Conversation{sender_id: id, step: 1, last_answer: message["text"]})
    Messenger.send_message(id, "Hi, I'm Coinbot. I can help you find the best cryptocurrency for you.")
    Messenger.initiate_chat_settings(id)
    Messenger.send_message(id, "Help: Click on Menu option to show more options.")
    conv
  end
end
