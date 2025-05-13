defmodule SmartAnalysisWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use SmartAnalysisWeb, :html

  import SaladUI.Button

  embed_templates "page_html/*"
end
