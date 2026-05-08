defmodule ParserError do
  defexception [:message]

  @doc " Shows the user the character in the input where the error occured "
  def exception({message, input, charnum}) do
    indicator = if charnum do
      String.duplicate(" ", charnum) <> "^"
    else
      ""
    end
    message = "
#{message}
#{input}
#{indicator}
"
    %ParserError{message: message}
  end
end

defmodule Parser do
  @spec parse!(String.t()) :: [Tok.t() | {%Tok.Seq{}, [Tok.t()]}]
  @doc """
  Parses a string into a single Token or sequence of Tokens.

  Sequnces of tokens are represented as a 2-tuple of a Tok.Seq struct and a list of tokens.
  This allows parsing error to point the error back to the source in the input string/file.


    iex()> Parser.parse!("(def (add x y) (+ x y))")
    {%Tok.Seq{val: :start, char: 0},
    [
    %Tok.Symbol{val: :def, char: 1},
    {%Tok.Seq{val: :start, char: 5},
        [
        %Tok.Symbol{val: :add, char: 6},
        %Tok.Symbol{val: :x, char: 10},
        %Tok.Symbol{val: :y, char: 12}
        ]},
    {%Tok.Seq{val: :start, char: 15},
        [
        %Tok.Op{val: :+, char: 16},
        %Tok.Symbol{val: :x, char: 18},
        %Tok.Symbol{val: :y, char: 20}
        ]}
    ]}

  """
  def parse!(input) when is_binary(input) do
    tokens = Tokenizer.tokenize!(input)

    try do
      parse(tokens)
    catch
      {:error, message, charnum} -> raise ParserError, {message, input, charnum}
    end
  end

  def parse(input) when is_binary(input) do
    try do
      case Tokenizer.tokenize(input) do
        {:ok, tokens} -> parse(tokens)
        {:error, charnum} -> {:error, :tokenizer, charnum}
      end
    catch
      {:error, message, charnum} -> {:error, :parser, message, charnum}
    end
  end

  def parse([]), do: throw {:error, "empty input", nil}

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

  # if the tokenizer recognized a single token from an input stream, unwrap it
  def parse([token]), do: token
  
  # sequences of tokens are only allowed inside a Tok.Seq 
  def parse([_, %{char: charnum} | _]), do: throw({:error, "syntax error: tokens may not be sequenced here", charnum})

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
    token = case token do
              %{} -> parse [token]
              _ -> parse token
            end
    parse_list(rest, [token | collected], opener)
  end
end
