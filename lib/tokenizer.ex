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

defmodule OpTok do
  use Token
  def init(value), do: String.to_atom(value)
end

defmodule SpaceTok do
  use Token
  def init(value), do: value
end

defmodule AtomTok do
  use Token
  def init(value), do: String.to_atom(value)
end

defmodule ListTok do
  use Token

  def init(value) do
    case value do
      "(" -> :start
      ")" -> :end
    end
  end
end

defmodule StringTok do
  use Token

  def init(value) do
    # drop quotation marks and replace nulls with quotation marks
    value
    |> String.slice(1..-2//1)
    |> String.replace(<<0>>, ~s("))
  end
end

defmodule NumberTok do
  use Token

  def init(value) do
    try do
      String.to_float(value)
    catch
      _, _ -> String.to_integer(value)
    end
  end
end

defmodule TokenizationError do
  defexception [:message]

  def exception({input, charnum}) do
    indicator = String.duplicate(" ", max(0, charnum - 1)) <> "^^"
    message = EEx.eval_string("
<%= input %>
<%= indicator %>
", input: input, indicator: indicator)
    %TokenizationError{message: message}
  end
end

defmodule ParserError do
  defexception [:message]

  def exception({message, input, charnum}) do
    indicator = String.duplicate(" ", charnum) <> "^"
    message = EEx.eval_string("
<%= message %>
<%= input %>
<%= indicator %>
", message: message, input: input, indicator: indicator)
    %ParserError{message: message}
  end
end

defmodule Tokenizer do
  @moduledoc """
  An s-expression tokenizer.

  Accepts a string containg s-expressions and returns a List of ints, floats, atoms, and strings.

  Valid tokens are:

  grouping tokens:

    ( ) [ ]

  operators:
    
    = + - / *

  integers:

    0 300 -44

  floats:

    33.9 -44.39

  atoms:

    first true maxAge x2

  strings:

    "blue" "he said \"no worries\" but I didn't trust it"

  """

  def read_token(input) do
    patterns = [
      # float
      {NumberTok, ~r/^-?[0-9]+\.[0-9]+/},
      # int
      {NumberTok, ~r/^-?[0-9]+/},
      {AtomTok, ~r/^[a-zA-Z_][a-zA-Z0-9]*/},
      {StringTok, ~r/^".*?"/},
      {ListTok, ~r/^[()]/},
      {OpTok, ~r(^[=+-/*])},
      {SpaceTok, ~r/^\s+/}
    ]

    # run patterns until one is found
    Enum.reduce(patterns, nil, fn {type, pattern}, acc ->
      if acc do
        # return the first match
        acc
      else
        case Regex.run(pattern, input) do
          [match] ->
            token = Kernel.apply(type, :from_string, [match])
            {token, String.length(match)}

          _ ->
            nil
        end
      end
    end)
  end

  def tokenize!(input) do
    case tokenize(input) do
      {:ok, tokens} -> tokens
      {:error, linenum} -> raise TokenizationError, {input, linenum}
    end
  end

  def tokenize(input) do
    input = String.replace(input, ~s(\\"), <<0>>)
    tokenize(input, [], 0)
  end

  def tokenize("", stack, _) do
    stack =
      Enum.reduce(stack, [], fn
        %SpaceTok{}, acc -> acc
        token, acc -> [token | acc]
      end)

    {:ok, stack}
  end

  def tokenize(input, stack, position) do
    case read_token(input) do
      nil ->
        {:error, position}

      {token, consumed} ->
        token = %{token | char: position}
        input = String.slice(input, consumed..-1//1)
        position = position + consumed

        stack =
          case {token, stack} do
            {_, []} -> [token | stack]
            {_, [%ListTok{} | _]} -> [token | stack]
            {%ListTok{}, _} -> [token | stack]
            {%SpaceTok{}, _} -> [token | stack]
            {_, [%SpaceTok{} | _]} -> [token | stack]
            _ -> {:error, position}
          end

        case stack do
          {:error, p} -> {:error, p}
          _ -> tokenize(input, stack, position)
        end
    end
  end

  def parse(input) when is_binary(input) do
    tokens = tokenize!(input)

    try do
      parse(tokens)
    catch
      {:error, message, charnum} -> raise ParserError, {message, input, charnum}
    end
  end

  def parse(%ListTok{val: :end, char: char}) do
    throw({:error, "extra paren", char})
  end

  def parse([t = %ListTok{val: :start} | rest]) do
    case parse_list(rest, [], t) do
      {tokens, []} -> tokens
      {_, [%{char: charnum} | _]} -> throw({:error, "syntax error", charnum})
    end
  end

  def parse([token]), do: token
  def parse(token), do: token

  def parse_list([%ListTok{val: :end} | rest], collected, opener) do
    {{opener, Enum.reverse(collected)}, rest}
  end

  def parse_list([t = %ListTok{val: :start} | rest], collected, opener) do
    {inner_list, remaining} = parse_list(rest, [], t)
    parse_list(remaining, [inner_list | collected], opener)
  end

  def parse_list([], _, opener) do
    throw({:error, "unclosed paren", opener.char})
  end

  def parse_list([token | rest], collected, opener) do
    parse_list(rest, [parse(token) | collected], opener)
  end
end
