defmodule SmartAnalysis.AnalysisTest do
  use SmartAnalysis.DataCase

  alias SmartAnalysis.Analysis

  describe "projects" do
    alias SmartAnalysis.Analysis.Project

    import SmartAnalysis.AnalysisFixtures

    @invalid_attrs %{description: nil, title: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Analysis.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Analysis.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{description: "some description", title: "some title"}

      assert {:ok, %Project{} = project} = Analysis.create_project(valid_attrs)
      assert project.description == "some description"
      assert project.title == "some title"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Analysis.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title"}

      assert {:ok, %Project{} = project} = Analysis.update_project(project, update_attrs)
      assert project.description == "some updated description"
      assert project.title == "some updated title"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Analysis.update_project(project, @invalid_attrs)
      assert project == Analysis.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Analysis.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Analysis.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Analysis.change_project(project)
    end
  end
end
