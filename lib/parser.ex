defmodule ParserError do
  defexception [:message]

  @doc " Shows the user the character in the input where the error occured "
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

defmodule Parser do
  @spec parse!(String.t()) :: [Token.t() | {%Tok.Seq{}, [Token.t()]}]
  @doc """
  Parses a string into a single Token or sequence of Tokens.

  Sequnces of tokens are represented as a 2-tuple of a Tok.Seq struct and a list of tokens.
  This allows parsing error to point the error back to the source in the input string/file.
  """
  def parse!(input) when is_binary(input) do
    tokens = Tokenizer.tokenize!(input)

    try do
      parse(tokens)
    catch
      {:error, message, charnum} -> raise ParserError, {message, input, charnum}
    end
  end

  def parse(%Tok.Seq{val: :end, char: char}) do
    throw({:error, "extra paren", char})
  end

  def parse([t = %Tok.Seq{val: :start} | rest]) do
    case parse_list(rest, [], t) do
      {tokens, []} -> tokens
      # there should not be any tokens after the closing paren
      {_, [%{char: charnum} | _]} -> throw({:error, "syntax error", charnum})
    end
  end

  # all other token types pass through
  def parse(token), do: token

  # opener is the Tok.Seq that started this parsing branch
  def parse_list([%Tok.Seq{val: :end} | rest], collected, opener) do
    {{opener, Enum.reverse(collected)}, rest}
  end
  # 
  # reached the end of the list without a closing paren
  def parse_list([], _, opener) do
    throw({:error, "unclosed paren", opener.char})
  end

  # we found an inner list
  def parse_list([t = %Tok.Seq{val: :start} | rest], collected, opener) do
    {inner_list, remaining} = parse_list(rest, [], t)
    parse_list(remaining, [inner_list | collected], opener)
  end

  def parse_list([token | rest], collected, opener) do
    parse_list(rest, [parse(token) | collected], opener)
  end
end
