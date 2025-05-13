defmodule SmartAnalysisWeb.ProjectLive.Show do
  use SmartAnalysisWeb, :live_view

  alias SmartAnalysis.Analysis
  alias SmartAnalysis.Conversations
  import SaladUI.Button

  def render(assigns) do
    ~H"""
    <.header>
      Project {@project.id}
      <:subtitle>This is a project record from your database.</:subtitle>
      <:actions>
        <.link patch={~p"/projects/#{@project}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit project</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Title">{@project.title}</:item>
      <:item title="Description">{@project.description}</:item>
    </.list>

    <div class="mt-4">
      <div class="text-center py-8 bg-gray-50 rounded-lg">
        <.link
          navigate={~p"/conversations/new?project_id=#{@project.id}"}
          class="text-primary-600 hover:text-primary-700 mt-2 inline-block"
        >
          Create an analysis conversation
        </.link>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for conversation <- @conversations do %>
          <.link navigate={~p"/conversations/#{conversation.id}"} class="block">
            <div class="border rounded-lg p-4 hover:shadow-md transition-shadow">
              <div class="font-medium">{conversation.name}</div>
              <div class="text-sm text-gray-500">Model: {conversation.model}</div>
              <div class="text-xs text-gray-400 mt-2">
                {conversation.updated_at}
              </div>
            </div>
          </.link>
        <% end %>
      </div>
    </div>

    <.back navigate={~p"/projects"}>Back to projects</.back>

    <.modal
      :if={@live_action == :edit}
      id="project-modal"
      show
      on_cancel={JS.patch(~p"/projects/#{@project}")}
    >
      <.live_component
        module={SmartAnalysisWeb.ProjectLive.FormComponent}
        id={@project.id}
        title={@page_title}
        action={@live_action}
        project={@project}
        patch={~p"/projects/#{@project}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(%{"id" => project_id}, _session, socket) do
    if connected?(socket) do
      project = Analysis.get_project!(project_id)
      conversations = Conversations.list_project_conversations(project.id)
      IO.inspect(conversations, label: "Conversations for Project")

      socket =
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:project, project)
        |> assign(:conversations, conversations)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    project = Analysis.get_project!(id)
    conversations = Conversations.list_project_conversations(project.id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, project)
     |> assign(:conversations, conversations)}
  end

  defp page_title(:show), do: "Show Project"
  defp page_title(:edit), do: "Edit Project"
end
