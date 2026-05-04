defmodule Token do
  @moduledoc """
  A Token type is a struct that contains :val and :char keys.

  A module that implements the Token behaviour must implement an `init` function
  that accepts a string and returns the data structure the token is meant to
  represent. This will be stored as :value in the struct.

  :char is used to store an integer index of where the token appeared in
  the input string to allow for informative error messages.

    iex> Tokenizer.tokenize!("1 -2 0.334 -99.1 () ( ) + / name _var ok123")
    [
    %Tok.Num{val: 1, char: 0},
    %Tok.Num{val: -2, char: 2},
    %Tok.Num{val: 0.334, char: 5},
    %Tok.Num{val: -99.1, char: 11},
    %Tok.Seq{val: :start, char: 17},
    %Tok.Seq{val: :end, char: 18},
    %Tok.Seq{val: :start, char: 20},
    %Tok.Seq{val: :end, char: 22},
    %Tok.Op{val: :+, char: 24},
    %Tok.Op{val: :/, char: 26},
    %Tok.Atom{val: :name, char: 28},
    %Tok.Atom{val: :_var, char: 33},
    %Tok.Atom{val: :ok123, char: 38}
    ]

  """

  @callback init(value :: String.t()) :: term
  @type t :: %{val: term, char: integer() | nil}
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
    @moduledoc "Operators that invoke functions, like *"
    use Token
    def init(value), do: String.to_atom(value)
  end

  defmodule Space do
    @moduledoc "Whitespace tokens"
    use Token
    def init(value), do: value
  end

  defmodule Atom do
    use Token
    def init(value), do: String.to_atom(value)
  end

  defmodule Seq do
    @moduledoc " Sequence delimiters. Correspond to open and close parenthesis "
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
