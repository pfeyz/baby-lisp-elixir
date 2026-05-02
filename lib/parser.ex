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

defmodule Parser do
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
      {_, [%{char: charnum} | _]} -> throw({:error, "syntax error", charnum})
    end
  end

  def parse([token]), do: token
  def parse(token), do: token

  def parse_list([%Tok.Seq{val: :end} | rest], collected, opener) do
    {{opener, Enum.reverse(collected)}, rest}
  end

  def parse_list([t = %Tok.Seq{val: :start} | rest], collected, opener) do
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
