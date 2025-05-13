defmodule SmartAnalysis.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SmartAnalysis.Conversations` context.
  """

  @doc """
  Generate a conversation.
  """
  def conversation_fixture(attrs \\ %{}) do
    {:ok, conversation} =
      attrs
      |> Enum.into(%{
        frequency_penalty: 120.5,
        model: "some model",
        name: "some name",
        temperature: 120.5
      })
      |> SmartAnalysis.Conversations.create_conversation()

    conversation
  end
end
