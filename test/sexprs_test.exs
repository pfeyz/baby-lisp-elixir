defmodule SexprsTest do
  use ExUnit.Case
  doctest Tokenizer

  test "toknize an input" do
    assert Tokenizer.tokenize(~s<(first (list -33.05 5.3 "yel\\"low" 0 -3 4))>) ==
             {:ok,
              [
                %Tok.Seq{val: :start, char: 0},
                %Tok.Sym{val: :first, char: 1},
                %Tok.Seq{val: :start, char: 7},
                %Tok.Sym{val: :list, char: 8},
                %Tok.Num{val: -33.05, char: 13},
                %Tok.Num{val: 5.3, char: 20},
                %Tok.Str{val: "yel\"low", char: 24},
                %Tok.Num{val: 0, char: 34},
                %Tok.Num{val: -3, char: 36},
                %Tok.Num{val: 4, char: 39},
                %Tok.Seq{val: :end, char: 40},
                %Tok.Seq{val: :end, char: 41}
              ]}
  end
end
