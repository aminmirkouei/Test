defmodule SmartAnalysis.Repo.Migrations.AddMessagesToConversation do
  use Ecto.Migration

  def change do
alter table(:messages) do
      add :conversation_id, references(:conversations, type: :binary_id, on_delete: :delete_all),
        null: false
    end

    create index(:messages, [:conversation_id])
  end
end
