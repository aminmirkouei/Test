defmodule SmartAnalysisWeb.ConversationLive.Show do
  use SmartAnalysisWeb, :live_view

  alias SmartAnalysis.Conversations
  alias SmartAnalysis.Conversations.Conversation
  alias SmartAnalysis.Messages
  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias SmartAnalysis.Tools.Python
  alias SmartAnalysis.Tools.Functions
  alias Phoenix.LiveView.AsyncResult

  # TODO add the following to the top of the page
  # Work smarter, not harder
  # AI-driven efficiency

  import SaladUI.Button

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="flex justify-between items-center mb-4">
        <div>
          <h1 class="text-2xl font-bold mt-1">{@conversation.name}</h1>
          <div class="text-sm text-gray-500">
            Model: {@conversation.model} •
            Temperature: {@conversation.temperature} •
            Frequency penalty: {@conversation.frequency_penalty}
          </div>
        </div>
        <div>
          <.link patch={~p"/conversations/#{@conversation.id}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit</.button>
          </.link>
        </div>
      </div>

      <div class="flex flex-col justify-between" id="chat-messages" phx-update="stream">
        <!-- Chat Messages -->
        <div
          :for={{msg_id, msg} <- @streams.messages}
          id={"message-#{msg_id}"}
          class="space-y-4 mb-6 max-h-[500px] overflow-y-auto px-4 py-2 bg-white rounded-lg shadow"
        >
          <div class={"flex flex-col space-y-1 " <> if msg.role == :user, do: "items-end", else: "items-start"}>
            <div class={"rounded-lg px-4 py-2 text-sm " <>
            if msg.role == :user, do: "bg-blue-100 text-blue-900", else: "bg-gray-100 text-gray-800"}>
              <.markdown text={msg.content} />
            </div>
            <div class="text-xs text-gray-400">
              {if msg.role == :user, do: "You", else: @conversation.model}
            </div>
          </div>
        </div>

    <!-- Streaming response preview -->
        <%= if @streaming_preview do %>
          <div class="space-y-4 mb-6 max-h-[500px] overflow-y-auto px-4 py-2 bg-white rounded-lg shadow streaming-preview">
            <div class="flex flex-col space-y-1 items-start">
              <div class="rounded-lg px-4 py-2 text-sm bg-gray-100 text-gray-800">
                <.markdown text={@streaming_content} />
              </div>
              <div class="text-xs text-gray-400">
                {@conversation.model}
              </div>
            </div>
          </div>
        <% end %>

        <div class="flex flex-col justify-center items-center w-full gap-3 shadow rounded-md mb-5">
          <form
            class="flex items-center gap-2"
            phx-submit="upload_file"
            phx-change="validate_file"
            enctype="multipart/form-data"
          >
            <.live_file_input upload={@uploads.files} class="border p-2 rounded" />
            <.button type="submit" variant="outline">Upload</.button>
          </form>

          <%= for file <- @uploaded_files do %>
            <p class="mt-2 text-sm text-green-600">{file}</p>
          <% end %>
          <!-- Chat Input -->
          <.form for={@form} phx-submit="save" class="flex items-center space-x-2 p-4">
            <.input
              field={@form[:message]}
              type="textarea"
              cols="80"
              placeholder="Type your message..."
              class="flex-1"
            />
            <.button type="submit" class="mt-2">Send</.button>
          </.form>
        </div>
      </div>

      <%= if @loading do %>
        <div class="text-sm text-gray-500 mt-2 animate-pulse">Thinking...</div>
      <% end %>
    </div>
    """
  end

  attr :text, :string, required: true, doc: "Markdown text to render"
  attr :rest, :global
  slot :inner_block

  def markdown(assigns) do
    html_doc =
      Earmark.as_html!(assigns.text || "")
      |> Phoenix.HTML.raw()

    ~H"""
    {html_doc}
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    conversation = Conversations.get_conversation!(id)

    socket =
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(:files, accept: ~w(.csv .xlsx), max_entries: 1)
      |> assign_conversation(conversation)
      |> assign_messages()
      |> assign_llm_chain()
      |> assign(:async_result, %AsyncResult{})
      |> assign(:streaming_preview, false)
      |> assign(:streaming_content, "")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    conversation = Conversations.get_conversation!(id)
    messages = Messages.list_conversation_messages(conversation.id)
    IO.inspect(messages, label: "Messages for Conversation")

    {:noreply,
     socket
     |> assign(:page_title, "#{conversation.name}")
     |> assign(:conversation, conversation)
     |> stream(:messages, messages)
     |> assign(:new_message, %Message{role: :user})
     |> assign(:form, to_form(%{"message" => ""}))
     |> assign(:loading, false)}
  end

  @impl true
  def handle_event("validate_file", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload_file", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        dest = Path.join("priv/static/uploads", Path.basename(entry.client_name))
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)

        extension =
          case entry.client_type do
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ->
              ".xlsx"

            "text/csv" ->
              ".csv"

            _ ->
              raise "Unsupported file type: #{entry.client_mime}"
          end

        IO.inspect(extension, label: "File Extension")
        IO.inspect(dest, label: "Destination Path")
        IO.inspect(path, label: "Uploaded File Path")
        IO.inspect(entry, label: "Entry Info")

        content =
          case extension do
            ".xlsx" ->
              # Handle Excel file
              case parse_excel(dest) do
                {:ok, text_output} ->
                  # Save the parsed content as a CSV file
                  output_path =
                    Path.join("priv/static/uploads", "#{Path.basename(dest, ".xlsx")}.csv")

                  # File.write!(output_path, text_output)
                  text_output

                {:error, reason} ->
                  raise "Failed to parse Excel file: #{inspect(reason)}"
              end

            ".csv" ->
              # Handle CSV file
              parse_csv(File.read!(dest))
          end

        # {:ok, "/priv/static/uploads/#{Path.basename(dest)}.csv"}
        {:ok, content}
      end)

    IO.inspect(uploaded_files, label: "Uploaded Files")

    {:noreply,
     assign(socket, :uploaded_files, uploaded_files)
     |> put_flash(:info, "File uploaded successfully!")}
  end

  def parse_excel(path) do
    # Read and parse the Excel file
    case XlsxReader.open(path) do
      {:ok, workbook} ->
        # {:ok, sheets} = XlsxReader.sheets(workbook)
        sheets = XlsxReader.sheet_names(workbook)
        first_sheet = List.first(sheets)

        {:ok, rows} = XlsxReader.sheet(workbook, first_sheet)

        text_output =
          rows
          |> Enum.map(fn row -> Enum.join(row, "\t") end)
          |> Enum.join("\n")

        IO.inspect(text_output, label: "Parsed Text Output")
        {:ok, text_output}

      {:error, reason} ->
        {:error, "Failed to read Excel: #{inspect(reason)}"}
    end
  end

  defp parse_csv(content) do
    content
    |> String.split("\n", trim: true)
    |> Enum.map(fn line -> String.split(line, ",") end)
  end

  def handle_event("save", %{"message" => message}, socket) do
    conversation = socket.assigns.conversation

    message =
      case message do
        %{"message" => msg} -> msg
        msg when is_binary(msg) -> msg
        _ -> message
      end

    params =
      case socket.assigns.uploaded_files do
        [] ->
          %{role: :user, content: message, status: :complete}

        _ ->
          %{
            role: :user,
            content:
              message <>
                "\n\nFiles:\n" <> Enum.join(socket.assigns.uploaded_files, "\n"),
            status: :complete
          }
      end

    IO.inspect(socket.assigns.uploaded_files, label: "Uploaded Files")

    IO.inspect(params, label: "Message Params")

    case Messages.create_message(conversation.id, params) do
      {:ok, _message} ->
        # Reset streaming preview state when sending a new message
        socket =
          socket
          |> assign(:streaming_preview, false)
          |> assign(:streaming_content, "")
          |> assign_messages()
          # re-build the chain based on the current messages
          |> assign_llm_chain()
          |> run_chain()
          |> put_flash(:info, "Message sent successfully")
          # reset the changeset
          |> assign_form(Message.changeset(%Message{}, %{}))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "Message Changeset Error")
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    message = Messages.get_message!(socket.assigns.conversation.id, id)
    {:ok, _} = Messages.delete_message(message)

    {:noreply, assign_messages(socket)}
  end

  def handle_event("resubmit", _params, socket) do
    socket =
      socket
      |> assign_llm_chain()
      |> run_chain()
      |> put_flash(:info, "Conversation re-submitted")

    {:noreply, socket}
  end

  @doc """
  Cancel the async process
  """
  def handle_event("cancel", _params, socket) do
    socket =
      socket
      |> cancel_async(:running_llm)
      |> assign(:async_result, %AsyncResult{})
      |> put_flash(:info, "Cancelled")
      |> close_pending_as_cancelled()
      |> assign(:streaming_preview, false)
      |> assign(:streaming_content, "")

    {:noreply, socket}
  end

  @impl true
  @doc """
  Handle the async result of the running_llm async function.
  """
  def handle_async(:running_llm, {:ok, :ok = _success_result}, socket) do
    # discard the result of the successful async function. The side-effects are
    # what we want.
    socket =
      socket
      |> assign(:async_result, AsyncResult.ok(%AsyncResult{}, :ok))
      |> assign(:streaming_preview, false)
      |> assign(:streaming_content, "")
      # Refresh messages after completion, this is the correct place to do it
      |> assign_messages()

    {:noreply, socket}
  end

  # Handles async function returning an error as a result
  def handle_async(:running_llm, {:ok, {:error, reason}}, socket) do
    socket =
      socket
      |> put_flash(:error, reason)
      |> assign(:async_result, AsyncResult.failed(%AsyncResult{}, reason))
      |> close_pending_as_cancelled()
      |> assign(:streaming_preview, false)
      |> assign(:streaming_content, "")

    {:noreply, socket}
  end

  # handles async function exploding
  def handle_async(:running_llm, {:exit, reason}, socket) do
    socket =
      socket
      |> put_flash(:error, "Call failed: #{inspect(reason)}")
      |> assign(:async_result, %AsyncResult{})
      |> close_pending_as_cancelled()
      |> assign(:streaming_preview, false)
      |> assign(:streaming_content, "")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_response, %LangChain.MessageDelta{} = delta}, socket) do
    updated_chain = LLMChain.apply_delta(socket.assigns.llm_chain, delta)

    # Update streaming preview with content from the delta
    streaming_content =
      if delta.content && delta.role == :assistant do
        socket.assigns.streaming_content <> delta.content
      else
        socket.assigns.streaming_content
      end

    # Enable streaming preview if we have content
    streaming_preview = String.length(streaming_content) > 0

    socket =
      socket
      |> assign(:llm_chain, updated_chain)
      |> assign(:streaming_content, streaming_content)
      |> assign(:streaming_preview, streaming_preview)

    # Handle completed message
    socket =
      cond do
        # if this completed the delta and it's a message, create the message
        updated_chain.delta == nil ->
          if updated_chain.last_message.content != nil do
            # Create the message but don't immediately refresh the messages list
            # This prevents double-insertion
            {:ok, _message} =
              Messages.create_message(
                socket.assigns.conversation.id,
                Map.from_struct(updated_chain.last_message)
              )

            socket
            |> assign(:streaming_preview, false)
            |> assign(:streaming_content, "")
            |> flash_error_if_stopped_for_limit()
          else
            socket
          end

        true ->
          socket
      end

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # Close out any pending delta messages as cancelled and save what we've
  # received so far. This works when we initiate a cancel or we receive an error
  # from the async function.
  defp close_pending_as_cancelled(socket) do
    chain = socket.assigns.llm_chain

    # the task exited with an incomplete delta
    if chain.delta != nil do
      # most likely was cancelled. An incomplete
      # delta can be converted to a "cancelled" message
      updated_chain = LLMChain.cancel_delta(chain, :cancelled)

      # save the cancelled message
      Messages.create_message(
        socket.assigns.conversation.id,
        Map.from_struct(updated_chain.last_message)
      )

      socket
      |> assign(:llm_chain, updated_chain)
      |> assign_messages()
    else
      socket
    end
  end

  defp role_icon(:system), do: "hero-cloud-solid"
  defp role_icon(:user), do: "hero-user-solid"
  defp role_icon(:assistant), do: "fa-user-robot"
  defp role_icon(:function_call), do: "fa-function"
  defp role_icon(:function), do: "fa-function"

  # Support both %Message{} and %MessageDelta{}
  defp message_block_classes(%{role: :system} = _message) do
    "bg-blue-50 text-blue-700 rounded-t-xl"
  end

  defp message_block_classes(%{role: :user} = _message) do
    "bg-white text-gray-600 font-medium"
  end

  defp message_block_classes(%{status: :length, role: :assistant} = _message) do
    "bg-red-50 text-red-800 font-medium"
  end

  defp message_block_classes(%{status: :cancelled, role: :assistant} = _message) do
    "bg-yellow-50 text-yellow-800 font-medium"
  end

  defp message_block_classes(%{role: :assistant} = _message) do
    "bg-gray-50 text-gray-600 font-medium"
  end

  defp display_date(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("America/Denver")
    |> Calendar.strftime(DateTime.shift_zone!("America/New_York"))
  end

  defp assign_conversation(socket, conversation) do
    socket
    |> assign(:conversation, conversation)
  end

  defp assign_messages(socket) do
    conversation = socket.assigns.conversation
    stream(socket, :messages, Messages.list_messages(conversation.id))
  end

  defp assign_llm_chain(socket) do
    conversation = socket.assigns.conversation
    live_view_pid = self()

    handlers = %{
      on_llm_new_delta: fn _chain, %LangChain.MessageDelta{} = delta ->
        send(live_view_pid, {:chat_response, delta})
      end
    }

    csv_content = List.first(socket.assigns.uploaded_files)
    context = %{"csv_content" => csv_content}

    # convert the DB stored message to LLMChain messages
    chain_messages =
      conversation.id
      |> Messages.list_messages()
      |> Messages.db_messages_to_langchain_messages()

    tools = [Python.new!(), Functions.speed()]

    llm_chain =
      LLMChain.new!(%{
        llm: setup_model(conversation),
        verbose: true,
        custom_context: context
      })
      |> LLMChain.add_callback(handlers)
      |> LLMChain.add_tools(tools)
      |> LLMChain.add_messages(chain_messages)

    assign(socket, :llm_chain, llm_chain)
  end

  def run_chain(socket) do
    chain = socket.assigns.llm_chain

    socket
    |> assign(:async_result, AsyncResult.loading())
    |> start_async(:running_llm, fn ->
      case LLMChain.run(chain, mode: :while_needs_response) do
        # return the errors for display
        {:error, reason} ->
          {:error, reason}

        # Don't return a large success result. The callbacks return what we
        # want.
        _other ->
          :ok
      end
    end)
  end

  defp flash_error_if_stopped_for_limit(
         %{assigns: %{llm_chain: %LLMChain{last_message: %LangChain.Message{status: :length}}}} =
           socket
       ) do
    put_flash(socket, :error, "Stopped for limit")
  end

  defp flash_error_if_stopped_for_limit(socket) do
    socket
  end

  def setup_model(conversation, opts \\ [])

  def setup_model(%Conversation{model: "gpt" <> _rest} = conversation, opts) do
    # setup OpenAI
    ChatOpenAI.new!(%{
      model: conversation.model,
      temperature: conversation.temperature,
      frequency_penalty: conversation.frequency_penalty,
      receive_timeout: 60_000 * 2,
      stream: Keyword.get(opts, :stream, true)
    })
  end
end
