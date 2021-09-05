defmodule Coinbot.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :sender_id, :string
      add :last_answer, :string
      add :last_question, :string
      add :status, :integer, default: 0
      add :step, :integer, default: 1

      timestamps()
    end

  end
end
