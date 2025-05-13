defmodule SmartAnalysis.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :edited, :boolean, default: false, null: false
      add :role, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:status])
  end
end
