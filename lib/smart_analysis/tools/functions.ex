defmodule SmartAnalysis.Tools.Functions do
  require Logger
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Pythonx

  def speed() do
    Function.new!(%{
      name: "speed",
      description: """
      Calculates speed using distance and time.
      Parameters:
      - D: distance (float)
      - T: time (float)
      Ask questions if you need more details.
      """,
      parameters: [
        FunctionParam.new!(%{
          name: "D",
          type: "number",
          description: "distance",
          required: true
        }),
        FunctionParam.new!(%{
          name: "T",
          type: "number",
          description: "time",
          required: true
        })
      ],
      function: &speed/2
    })
  end

  def speed(%{"D" => d, "T" => t}, _context) do
    # IO.inspect(a, label: "Location A")
    # IO.inspect(b, label: "Location B")
    result = d / t
    # IO.inspect(result, label: "Emission Result")
    "#{result}"

    # Pythonx.eval("""
    # def emission(a: float, b: float) -> float:
    #   returns a/b
    # """)
    # function_python_file_location = "./priv/functions/emission.py"
    # Pythonx.eval(File.read!(function_python_file_location))
  end

  def calculator() do
    Function.new!(%{
      name: "calculator",
      description: """
      Performs basic addition, subtraction, multiplication, or division.
      Parameters:
      - A: first number (float)
      - B: second number (float)
      - Op: operation ('add', 'subtract', 'multiply', 'divide')
      """,
      parameters: [
        FunctionParam.new!(%{
          name: "A",
          type: "number",
          description: "first number",
          required: true
        }),
        FunctionParam.new!(%{
          name: "B",
          type: "number",
          description: "second number",
          required: true
        }),
        FunctionParam.new!(%{
          name: "Op",
          type: "string",
          description: "operation type",
          required: true
        })
      ],
      function: &calculator/2
    })
  end

  def calculator(%{"A" => a, "B" => b, "Op" => op}, _context) do
    case op do
      "add" -> "#{a + b}"
      "subtract" -> "#{a - b}"
      "multiply" -> "#{a * b}"
      "divide" -> if b != 0, do: "#{a / b}", else: "Error: Division by zero"
      _ -> "Error: Invalid operation"
    end
  end


  # add new functions here

end
