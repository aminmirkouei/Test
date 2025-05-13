defmodule SmartAnalysis.Repo.Migrations.AddConversationsToProjects do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all), null: false
    end
  create index(:conversations, [:project_id])
  end

end
