defmodule Tok do
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
        %Tok.Symbol{val: :+, char: 24},
        %Tok.Symbol{val: :/, char: 26},
        %Tok.Symbol{val: :name, char: 28},
        %Tok.Symbol{val: :_var, char: 33},
        %Tok.Symbol{val: :ok123, char: 38}
        ]

    """

    # just "use"ed by individual Tok modules
    defmodule Token do
      @callback init(value :: String.t()) :: term
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

  @type t :: Space | Symbol | Seq | Str | Num

  defmodule Space do
    @moduledoc "Whitespace tokens"
    use Token
    def init(value), do: value
  end

  defmodule Symbol do
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
