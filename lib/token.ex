defmodule Token do
  defmacro __using__(__ops) do
    quote do
      defstruct [:val, :char]

      def from_string(value) do
        %__MODULE__{val: init(value)}
      end
    end
  end
end

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
      # drop quotation marks and replace nulls with quotation marks
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
