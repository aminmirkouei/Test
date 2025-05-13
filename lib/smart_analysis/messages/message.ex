defmodule SmartAnalysis.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :status, Ecto.Enum, values: [:complete, :cancelled], default: nil
    field :role, Ecto.Enum, values: [:system, :user, :assistant, :tool_call]
    field :content, :string
    field :edited, :boolean, default: false

    belongs_to(:conversation, SmartAnalysis.Conversations.Conversation)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :edited, :role, :status, :conversation_id])
    |> validate_required([:content, :edited, :role, :status, :conversation_id])
    |> assoc_constraint(:conversation)
  end
end
