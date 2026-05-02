defmodule TokenizationError do
  defexception [:message]

  def exception({input, charnum}) do
    indicator = String.duplicate(" ", max(0, charnum-1)) <> "^^"
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
      {:float, ~r/^-?[0-9]+\.[0-9]+/, &String.to_float(&1)},
      {:int, ~r/^-?[0-9]+/, &String.to_integer(&1)},
      {:atom, ~r/^[a-zA-Z_][a-zA-Z0-9]*/, &String.to_atom(&1)},
      {:string, ~r/^".*?"/, fn s -> s
                                 |> String.slice(1..-2//1) 
                                 |> String.replace(<<0>>, ~s("))
                                 end
      },
      {:paren, ~r/^[()]/,
       &if &1 == "(" do
         :open
       else
         :close
       end},
      {:operator, ~r(^[=+-/*]), &String.to_atom(&1)},
      {:whitespace, ~r/^\s+/, & &1}
    ]

    # run patterns until one is found
    Enum.reduce(patterns, nil, fn {type, pat, trans}, acc ->
      if acc do
        # return the first match
        acc
      else
        case Regex.run(pat, input) do
          [match] -> {{type, trans.(match)}, String.length(match)}
          _ -> nil
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
        {:whitespace, _, _}, acc -> acc
        token, acc -> [token | acc]
      end)

    {:ok, stack}
  end


  def tokenize(input, stack, position) do
    case read_token(input) do
      nil ->
        {:error, position}

      {{tok_type, value}, consumed} ->
        token = {tok_type, value, position}
        input = String.slice(input, consumed..-1//1)
        position = position + consumed

        stack =
          case {tok_type, stack} do
            {_, []} -> [token | stack]
            {_, [{:paren, _, _} | _]} -> [token | stack]
            {:paren, _} -> [token | stack]
            {:whitespace, _} -> [token | stack]
            {_, [{:whitespace, _, _} | _]} -> [token | stack]
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
      parse tokens
    catch
      {:error, message, charnum} -> raise ParserError, {message, input, charnum}
    end    
  end

  def parse([{:paren, :close, charnum}]), do: throw {:error, "extra paren", charnum}
  def parse([{:paren, :open, charnum} | rest]) do
    case parse_list(rest, [], charnum) do
      {tokens, []} -> tokens
      {_, [{_,_,charnum} | _]} -> throw {:error, "syntax error", charnum}
    end
    
  end
  def parse([token]), do: token
  def parse(token), do: token

  def parse_list([{:paren, :close, _} | rest], collected, charnum) do
    {{:list, Enum.reverse(collected), charnum}, rest}
  end

  def parse_list([{:paren, :open, inner_charnum} | rest], collected, charnum) do
    {inner_list, remaining} = parse_list(rest, [], inner_charnum)
    parse_list(remaining, [inner_list|collected], charnum)
  end

  def parse_list([], _, charnum) do
    throw {:error, "unclosed paren", charnum}
  end 

  def parse_list([token|rest], collected, charnum) do
    parse_list(rest, [parse(token) | collected], charnum)
  end

end
