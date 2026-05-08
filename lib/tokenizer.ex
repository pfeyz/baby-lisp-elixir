defmodule TokenizationError do
  defexception [:message]

  @doc " Shows the user the character in the input where the error occured "
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
  Tokenizer defines a tokenize! function that accepts a string and returns


  a list of Token objects.
  """

  @spec read_token(String.t()) :: {Token.t(), integer()} | nil
  @doc """
  Returns {token, chars_consumed}, where chars_consumed is the length of the string
  that matched to produce the token
  """
  def read_token(input) do
    patterns = [
      # float
      {Tok.Num, ~r/^-?[0-9]+\.[0-9]+/},
      # int
      {Tok.Num, ~r/^-?[0-9]+/},
      {Tok.Atom, ~r/^[a-zA-Z_][a-zA-Z0-9]*/},
      # strs can have embedded quotes
      {Tok.Str, ~r/^"(?:\\"|.)*?"/},
      {Tok.Seq, ~r/^[()]/},
      {Tok.Op, ~r(^[=+-/*])},
      {Tok.Space, ~r/^\s+/}
    ]

    # run patterns until one is found
    Enum.reduce(patterns, nil, fn {type, pattern}, acc ->
      if acc do
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

  @spec tokenize!(String.t()) :: [Token.t()]
  def tokenize!(input) do
    case tokenize(input) do
      {:ok, tokens} -> tokens
      {:error, linenum} -> raise TokenizationError, {input, linenum}
    end
  end

  def tokenize(input) do
    tokenize(input, [], 0)
  end

  def tokenize("", stack, _) do
    stack =
      Enum.reduce(stack, [], fn
        # drop all whitespace tokens
        %Tok.Space{}, acc -> acc
        token, acc -> [token | acc]
      end)

    {:ok, stack}
  end

  def tokenize(input, stack, position) do
    case read_token(input) do
      nil ->
        {:error, position}

      {token, chars_consumed} ->
        token = %{token | char: position}
        input = String.slice(input, chars_consumed..-1//1)
        position = position + chars_consumed

        # whitespace and seq/paren tokens can be concatenated with any other token.
        # any other concatenations are invalid.
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
