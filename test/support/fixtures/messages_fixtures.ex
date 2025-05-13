defmodule SmartAnalysis.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SmartAnalysis.Messages` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        edited: true,
        role: :"",
        status: :complete
      })
      |> SmartAnalysis.Messages.create_message()

    message
  end
end
