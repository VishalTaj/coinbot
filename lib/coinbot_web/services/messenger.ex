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
      }
    }
    headers = [{"Content-type", "application/json"}]
    HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end
  
  def send_message(id, message) do
    body = %{recipient: %{id: id}, message: %{text: message}, persona_id: System.get_env("PERSONA")}
    headers = [{"Content-type", "application/json"}]
    HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end

  def template_list(id, elements, buttons) do
    body = %{
      recipient: %{
        id: id
      }, 
      message:  %{
        attachment: %{
          type: "template",
          payload: %{
            template_type: "list",
            top_element_style: "compact",
            elements: elements,
             buttons: buttons 
          }
        }
      }
    }
    headers = [{"Content-type", "application/json"}]
    HTTPoison.post(@fb_base_uri["message"], Jason.encode!(body), headers)
  end
end