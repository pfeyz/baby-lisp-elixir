defmodule Token do
  @moduledoc """
  A Token is a module that defines a struct with :value and :char keys
  and defines an init function. 

  The init function takes the string representation of the token and 
  returns it as a valid data structure that's stored in :value

  :char is used to store an integer index of where the token appeared in
  the input string to allow for informative error messages.
  """

  @callback init(value :: String) :: term
  @type t :: struct()
  defmacro __using__(__ops) do
    quote do
      defstruct [:val, :char]
      @behaviour Token
      def from_string(value) do
        %__MODULE__{val: init(value)}
      end
    end
  end
end

# the tokens used in the codebase
defmodule Tok do
  defmodule Op do
    use Token
    def init(value), do: String.to_atom(value)
  end

  defmodule Space do
    use Token
    def init(value), do: value
  end

  defmodule Sym do
    use Token
    def init(value), do: String.to_atom(value)
  end

  defmodule Seq do
    use Token

    def init(value) do
      case value do
        "(" -> :start
        ")" -> :end
      end
    end
  end

  defmodule Str do
    use Token

    def init(value) do
      # drop outer quotation marks and replace nulls with inner quotation marks
      value
      |> String.slice(1..-2//1)
      |> String.replace(<<0>>, ~s("))
    end
  end

  defmodule Num do
    use Token

    def init(value) do
      try do
        String.to_float(value)
      catch
        _, _ -> String.to_integer(value)
      end
    end
  end
end
