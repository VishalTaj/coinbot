defmodule CoinbotWeb.Services.Messenger do
  @moduledoc false

  @fb_base_uri %{
    "message" => "https://graph.facebook.com/v2.6/me/messages?access_token=#{System.get_env("PAGE_ACCESS_TOKEN")}",
    "user_settings" => "https://graph.facebook.com/v11.0/me/custom_user_settings?access_token=#{System.get_env("PAGE_ACCESS_TOKEN")}"
  }

  @doc """
    A Service which triggers Fb messenger quick replies api.
  """
  def quick_replies(id, replies, question) do
    body = %{
      recipient: %{
        id: id
      },
      messaging_type: "RESPONSE",
      message: %{
        text: question,
        quick_replies: replies
      },
      persona_id: System.get_env("PERSONA")
    }
    headers = [{"Content-type", "application/json"}]
    {:ok, response } = HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end
  
  @doc """
    A Service which triggers Fb messenger send message api.
  """
  def send_message(id, message) do
    body = %{recipient: %{id: id}, message: %{text: message}, persona_id: System.get_env("PERSONA")}
    headers = [{"Content-type", "application/json"}]
    {:ok, response } = HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end

  @doc """
    A Service which triggers Fb messenger template list api.
  """
  def template_list(id, elements) do
    body = %{
      recipient: %{
        id: id
      }, 
      message:  %{
        attachment: %{
          type: "template",
          payload: %{
            template_type: "generic",
            elements: coins_template_list(elements, id)
          }
        }
      },
      persona_id: System.get_env("PERSONA")
    }
    headers = [{"Content-type", "application/json"}]
    HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end

  def market_list(id, elements, coin_id) do
    tg = for coin <- elements do 
      {:ok, timestamp} = Enum.fetch(coin, 0)
      timestamp = DateTime.from_unix!(timestamp, :millisecond)
      
      {:ok, currency } = Enum.fetch(coin, 1)

      "*Date:* #{timestamp.day}-#{timestamp.month}-#{timestamp.year} \n*Currency:* $#{currency}"
    end
    message = Enum.join(tg, "\n\n")
    message = "*Market List of #{coin_id} * \n\n" <> message
    body = %{recipient: %{id: id}, message: %{text: message}, persona_id: System.get_env("PERSONA")}
    headers = [{"Content-type", "application/json"}]
    response = HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)

  end

  @doc """
    Generates payload for Fb messenger template list api.
    this will return a list of elements/coins for the template list api.
  """
  def coins_template_list(coins, id) do
    elements = Enum.map(coins, fn coin ->
      %{
        title: coin["name"],
        image_url: "",
        subtitle: coin["symbol"],
        buttons: [
          %{
            type: "postback",
            title: "View Market Chart",
            payload: "MARKETCHART_#{coin["id"]}_#{id}"
          }, %{
            type: "postback",
            title: "Restart",
            payload: "DEVELOPER_RESTART"
          }
        ]
      }
    end)
    elements
  end

  @doc """
    Generates payload for Fb messenger persistent menu api.
  """
  def initiate_chat_settings(sender_id) do
    body = %{
      psid: sender_id,
      persistent_menu: [
        %{
            locale: "default",
            composer_input_disabled: false,
             call_to_actions: [
                  %{
                      type: "postback",
                      title: "Start Over",
                      payload: "DEVELOPER_RESTART"
                  },
                  %{
                      type: "postback",
                      title: "Help",
                      payload: "HELP"
                  },
              ]
        }
      ]
    }
    headers = [{"Content-type", "application/json"}]
    response = HTTPoison.post(@fb_base_uri["user_settings"], Jason.encode!(body), headers)
  end
end