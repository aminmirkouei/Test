defmodule SmartAnalysis.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :model, :string
      add :temperature, :float, default: 1.0
      add :frequency_penalty, :float, default: 0.0

      timestamps(type: :utc_datetime)
    end

    create index(:conversations, [:name])

  end
end
