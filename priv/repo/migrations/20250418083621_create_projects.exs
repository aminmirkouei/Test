defmodule SmartAnalysis.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
