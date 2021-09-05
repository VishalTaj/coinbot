defmodule Coinbot.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :step, :integer
    field :last_answer, :string
    field :last_question, :string
    field :status, :integer
    field :sender_id, :string

    timestamps()
  end
  

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:sender_id, :last_answer, :last_question, :step, :status])
    |> validate_required([:sender_id])
  end
end
