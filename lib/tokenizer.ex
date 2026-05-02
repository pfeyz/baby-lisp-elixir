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
      {Tok.Num, ~r/^-?[0-9]+\.[0-9]+/},
      # int
      {Tok.Num, ~r/^-?[0-9]+/},
      {Tok.Sym, ~r/^[a-zA-Z_][a-zA-Z0-9]*/},
      {Tok.Str, ~r/^".*?"/},
      {Tok.Seq, ~r/^[()]/},
      {Tok.Op, ~r(^[=+-/*])},
      {Tok.Space, ~r/^\s+/}
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
        %Tok.Space{}, acc -> acc
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
            {_, [%Tok.Seq{} | _]} -> [token | stack]
            {%Tok.Seq{}, _} -> [token | stack]
            {%Tok.Space{}, _} -> [token | stack]
            {_, [%Tok.Space{} | _]} -> [token | stack]
            _ -> {:error, position}
          end

        case stack do
          {:error, p} -> {:error, p}
          _ -> tokenize(input, stack, position)
        end
    end
  end
end
