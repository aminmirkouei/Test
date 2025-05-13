defmodule SmartAnalysisWeb.Component do
  @moduledoc """
  The entrypoint for defining UI components.

  This can be used in your components as:

    use SmartAnalysisWeb.Component

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  defmacro __using__(_) do
    quote do
      use Phoenix.Component

      import SmartAnalysisWeb.ComponentHelpers

      alias Phoenix.LiveView.JS

      defp classes(input) do
        TwMerge.merge(input)
      end
    end
  end
end
