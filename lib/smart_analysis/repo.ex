defmodule SmartAnalysis.Repo do
  use Ecto.Repo,
    otp_app: :smart_analysis,
    adapter: Ecto.Adapters.Postgres
end
