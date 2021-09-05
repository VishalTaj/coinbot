# Coinbot


Coinbot is a facebook chatbot which connects to coin gecko platform helps to search coin and get the market chart data.


## Preview


[![Preview](https://s9.gifyu.com/images/Screen-Recording-2021-09-05-at-7.38.05-PM.gif)](https://gifyu.com/image/JsJ6)

## Setup

Install all dependencies

```bash
  $ mix deps.get
```

Configure database.

in `.env` file update `DATABASE_URL` with your postgres database url.

Create database.

```bash
  $ mix ecto.create
```

Migrate database.

```bash
  $ mix ecto.migrate
```

For Running the application.

```bash
$ source .env && mix phx.server`
```


## Scope

- Facebook Messenger Bot Integration
- Coin Gecko API Integration


### References

- [CoinGecko API](https://www.coingecko.com/api/documentations/v3)
- [Facebook Messenger Bot](https://developers.facebook.com/docs/messenger-platform)
- [Mix](https://hexdocs.pm/phoenix/Phoenix.html)


### Tech Stack

- Phoenix Framework (Elixir)
- Postgresql (Database)
- Gigalixir (PAAS)
### Endpoints

```elixir
  @doc """
  @route GET /webhook
  
  facebook pings this endpoint to verify the webhook. for authentication we have a token in the header.
  """
  get "/webhook", MessengerController, :verify

  @doc """
  @route POST /webhook
  
  Facebook triggers this endpoint when a message is received.
  there are 2 types of messages:
  normal messages, postbacl messages
  """
  post "/webhook", MessengerController, :receive_message
```


### User Story

- As a Facebook User i can interact with the coinbot.
- As a Facebook User i can get the market chart data of a coin.
- As a Facebook user i can search for coin by name or ID.



> *Note* 
This a experiemental application which connects with facebook messenger and integerated with CoinGecko API.





