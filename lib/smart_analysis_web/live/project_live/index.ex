defmodule SmartAnalysisWeb.ProjectLive.Index do
  use SmartAnalysisWeb, :live_view

  alias SmartAnalysis.Analysis
  alias SmartAnalysis.Analysis.Project

  import SaladUI.Button

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Projects
      <:actions>
        <.link patch={~p"/projects/new"}>
          <.button>New Project</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="projects"
      rows={@streams.projects}
      row_click={fn {_id, project} -> JS.navigate(~p"/projects/#{project}") end}
    >
      <:col :let={{_id, project}} label="Title">{project.title}</:col>
      <:col :let={{_id, project}} label="Description">{project.description}</:col>
      <:action :let={{_id, project}}>
        <div class="sr-only">
          <.link navigate={~p"/projects/#{project}"}>Show</.link>
        </div>
        <.link patch={~p"/projects/#{project}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, project}}>
        <.link
          phx-click={JS.push("delete", value: %{id: project.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="project-modal"
      show
      on_cancel={JS.patch(~p"/projects")}
    >
      <.live_component
        module={SmartAnalysisWeb.ProjectLive.FormComponent}
        id={@project.id || :new}
        title={@page_title}
        action={@live_action}
        project={@project}
        patch={~p"/projects"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :projects, Analysis.list_projects())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, Analysis.get_project!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "EONEST.AI")
    |> assign(:project, nil)
  end

  @impl true
  def handle_info({SmartAnalysisWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Analysis.get_project!(id)
    {:ok, _} = Analysis.delete_project(project)

    {:noreply, stream_delete(socket, :projects, project)}
  end
end
