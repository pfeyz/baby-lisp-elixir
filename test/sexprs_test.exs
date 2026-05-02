defmodule SexprsTest do
  use ExUnit.Case
  doctest Tokenizer

  test "toknize an input" do
    assert Tokenizer.tokenize(~s<(first (list -33.05 5.3 "yel\\"low" 0 -3 4))>) ==
             {:ok,
              [
                %ListTok{val: :start, char: 0},
                %AtomTok{val: :first, char: 1},
                %ListTok{val: :start, char: 7},
                %AtomTok{val: :list, char: 8},
                %NumberTok{val: -33.05, char: 13},
                %NumberTok{val: 5.3, char: 20},
                %StringTok{val: "yel\"low", char: 24},
                %NumberTok{val: 0, char: 34},
                %NumberTok{val: -3, char: 36},
                %NumberTok{val: 4, char: 39},
                %ListTok{val: :end, char: 40},
                %ListTok{val: :end, char: 41}
              ]}
  end
end
