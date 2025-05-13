defmodule SmartAnalysis.ConversationsTest do
  use SmartAnalysis.DataCase

  alias SmartAnalysis.Conversations

  describe "conversations" do
    alias SmartAnalysis.Conversations.Conversation

    import SmartAnalysis.ConversationsFixtures

    @invalid_attrs %{name: nil, model: nil, temperature: nil, frequency_penalty: nil}

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Conversations.list_conversations() == [conversation]
    end

    test "get_conversation!/1 returns the conversation with given id" do
      conversation = conversation_fixture()
      assert Conversations.get_conversation!(conversation.id) == conversation
    end

    test "create_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{name: "some name", model: "some model", temperature: 120.5, frequency_penalty: 120.5}

      assert {:ok, %Conversation{} = conversation} = Conversations.create_conversation(valid_attrs)
      assert conversation.name == "some name"
      assert conversation.model == "some model"
      assert conversation.temperature == 120.5
      assert conversation.frequency_penalty == 120.5
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "update_conversation/2 with valid data updates the conversation" do
      conversation = conversation_fixture()
      update_attrs = %{name: "some updated name", model: "some updated model", temperature: 456.7, frequency_penalty: 456.7}

      assert {:ok, %Conversation{} = conversation} = Conversations.update_conversation(conversation, update_attrs)
      assert conversation.name == "some updated name"
      assert conversation.model == "some updated model"
      assert conversation.temperature == 456.7
      assert conversation.frequency_penalty == 456.7
    end

    test "update_conversation/2 with invalid data returns error changeset" do
      conversation = conversation_fixture()
      assert {:error, %Ecto.Changeset{}} = Conversations.update_conversation(conversation, @invalid_attrs)
      assert conversation == Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation" do
      conversation = conversation_fixture()
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "change_conversation/1 returns a conversation changeset" do
      conversation = conversation_fixture()
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end
  end
end
