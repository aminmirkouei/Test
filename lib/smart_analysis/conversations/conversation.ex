defmodule SmartAnalysis.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias SmartAnalysis.Analysis.Project
  alias SmartAnalysis.Messages.Message

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "conversations" do
    field :name, :string
    field :model, :string
    field :temperature, :float, default: 1.0
    field :frequency_penalty, :float, default: 0.0

    has_many :messages, Message
    belongs_to :project, Project

    timestamps(type: :utc_datetime)
  end

  def model_options() do
    [
      {"OpenAI gpt-4o mini", "gpt-4o-mini"},
      {"OpenAI gpt-4o", "gpt-4o"},

    ]
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:name, :model, :temperature, :frequency_penalty, :project_id])
    |> validate_required([:name, :model, :temperature, :frequency_penalty, :project_id])
    |> assoc_constraint(:project)
  end
end
