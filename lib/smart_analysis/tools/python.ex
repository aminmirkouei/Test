defmodule SmartAnalysis.Tools.Python do
  require Logger
  alias LangChain.Function
  alias Pythonx

  @persistent_key {:pythonx_uv, :initialized}
  @install_script """
  import subprocess
  import sys

  def install(package):
      command =  [sys.executable, "-m", "pip", "install", package]
      process = subprocess.Popen(
          command,
          stdout=subprocess.PIPE,
          stderr=subprocess.STDOUT,
          text=True
      )
      process.wait()
      if process.returncode == 0:
          print(f"Installed {package}")
      else:
          print(f"Error: failed to install {package}")
  """



  @spec new() :: {:ok, Function.t()} | {:error, Ecto.Changeset.t()}
  def new() do
    Function.new(%{
      name: "python_executor",
      description: """
      Executes Python code in an isolated uv environment.
      Parameters:
      - dependencies: a list of strings, e.g. ["numpy>=2.2", "pillow==8.0.0"]
      - code: the Python code to execute (string).
      You may pass in additional bindings via the context map.
      """,
      parameters_schema: %{
        type: "object",
        properties: %{
          dependencies: %{
            type: "array",
            items: %{type: "string"},
            description: "List of pip-style dependency specs to install"
          },
          code: %{
            type: "string",
            description: "Python code block to execute"
          }
        },
        required: ["dependencies", "code"]
      },
      function: &execute/2
    })
  end

  @spec new!() :: Function.t() | no_return()
  def new!() do
    case new() do
      {:ok, function} -> function
      {:error, changeset} -> raise LangChain.LangChainError, changeset
    end
  end


  @spec execute(args :: %{String.t() => any()}, context :: map()) ::
          {:ok, String.t()} | {:error, String.t()}
  def execute(%{"dependencies" => deps, "code" => code}, _context) when is_list(deps) do
    uv_toml = """
    [project]
    name = "project"
    version = "0.0.0"
    requires-python = "==3.13.*"
    dependencies = [
      "pip",
    #{Enum.map_join(deps, ",\n", fn dep -> ~s|  "#{dep}"| end)}
    ]
    """

    try do
      ensure_uv_initialized(uv_toml)
      script = inject_install_script(deps) <> code

      IO.puts("==================================")
      IO.puts("SCRIPT:")
      IO.puts(script)
      IO.puts("==================================")

      {result, _} = Pythonx.eval(script, %{})
      output = result
        |> Pythonx.decode()
        |> inspect()
        |> extract_content()
        |> String.trim()
      {:ok, output}

    rescue
      err ->
        Logger.error("PythonExecutor exception: #{inspect(err)}")
        {:error, "Python exception: #{inspect(err)}"}
    end
  end

  def execute(_invalid_args, _context) do
    {:error, "Invalid arguments: expected keys \"dependencies\" (list) and \"code\" (string)."}
  end

  def inject_install_script(deps) do
    @install_script <> "\n#{Enum.map_join(deps, ",\n", fn dep -> ~s|install("#{dep}")| end)}\n"
  end

  def extract_content(string) do
    # Match the opening pattern and capture everything after it until the end
    case Regex.run(~r/\{#Pythonx\.Object<(.+)\}$/s, string) do
      [_, content] -> content
      nil -> string  # Return original string if pattern doesn't match
    end
  end

  defp ensure_uv_initialized(uv_toml) do
    case :persistent_term.get(@persistent_key, false) do
      true ->
        :ok

      false ->
        # First‐time init (or retry if flag wasn’t set)
        result =
          try do
            Pythonx.uv_init(uv_toml)
          rescue
           _ ->
              :ok
          end

        case result do
          :ok ->
            :persistent_term.put(@persistent_key, true)
            :ok

          {:error, reason} ->
            Logger.error("Failed to uv_init Pythonx: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

end
