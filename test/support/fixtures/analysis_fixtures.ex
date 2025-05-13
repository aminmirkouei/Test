defmodule SmartAnalysis.AnalysisFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SmartAnalysis.Analysis` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> SmartAnalysis.Analysis.create_project()

    project
  end
end
