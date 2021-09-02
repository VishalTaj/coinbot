defmodule CoinbotWeb.Services.Messenger do
  @moduledoc false

  @fb_base_uri %{
    "message" => "https://graph.facebook.com/v2.6/me/messages?access_token=#{System.get_env("PAGE_ACCESS_TOKEN")}"
  }

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
    }
    headers = [{"Content-type", "application/json"}]
    {:ok, response } = HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end
  
  def send_message(id, message) do
    body = %{recipient: %{id: id}, message: %{text: message}, persona_id: System.get_env("PERSONA")}
    headers = [{"Content-type", "application/json"}]
    HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end

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
            elements: coins_template_list(elements)
          }
        }
      }
    }
    headers = [{"Content-type", "application/json"}]
    # IO.inspect(body)
    response = HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)

    IO.inspect(response)
  end

  def market_list(id, elements) do
    tg = for coin <- elements do 
      {:ok, timestamp} = Enum.fetch(coin, 0)
      timestamp = DateTime.from_unix!(timestamp, :millisecond)
      
      {:ok, currency } = Enum.fetch(coin, 1)

      "*Date:* #{timestamp.day}-#{timestamp.month}-#{timestamp.year} \n*Currency:* $#{currency}"
    end
    message = Enum.join(tg, "\n\n")  
    body = %{recipient: %{id: id}, message: %{text: message}, persona_id: System.get_env("PERSONA")}
    headers = [{"Content-type", "application/json"}]
    response = HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)

  end

  def coins_template_list(coins) do
    elements = Enum.map(coins, fn coin ->
      %{
        title: coin["name"],
        image_url: "",
        subtitle: coin["symbol"],
        default_action: %{
          type: "web_url",
          url: "https://16fb-202-187-186-134.ngrok.io/api/get_market_chart?coin_id=" <> coin["id"],
          webview_height_ratio: "tall",
        },
        buttons: [
          %{
            type: "web_url",
            url: "https://16fb-202-187-186-134.ngrok.io/api/get_market_chart?coin_id=" <> coin["id"],
            title: "View Market Chart"
          }, %{
            type: "postback",
            title: "Restart",
            payload: "DEVELOPER_RESTART"
          }]
      }
    end)
    elements
  end
end