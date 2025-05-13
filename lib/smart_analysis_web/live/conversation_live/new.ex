defmodule SmartAnalysisWeb.ConversationLive.New do
  use SmartAnalysisWeb, :live_view

  alias SmartAnalysis.Conversations
  alias SmartAnalysis.Conversations.Conversation
  alias SmartAnalysis.Analysis
  import SaladUI.Button

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    project = Analysis.get_project!(project_id)
    changeset = Conversations.change_conversation(%Conversation{project_id: project_id})
    IO.inspect(changeset, label: "New Conversation Changeset")

    {:ok,
     socket
     |> assign(:page_title, "New Conversation")
     |> assign(:project, project)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def mount(_params, _session, socket) do
    # If no project_id is provided, redirect to projects
    {:ok,
     socket
     |> put_flash(:error, "Project ID is required to create a conversation")
     |> push_navigate(to: ~p"/projects")}
  end

  @impl true
  def handle_event("validate", %{"conversation" => conversation_params}, socket) do
    changeset =
      %Conversation{}
      |> Conversations.change_conversation(conversation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"conversation" => conversation_params}, socket) do
    IO.inspect(conversation_params, label: "Saving Conversation Params")
    case Conversations.create_conversation(conversation_params) do
      {:ok, conversation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Conversation created successfully")
         |> push_navigate(to: ~p"/conversations/#{conversation}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # You'll need to add this function to your Conversations context
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end
end
