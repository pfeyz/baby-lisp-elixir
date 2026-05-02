defmodule SexprsTest do
  use ExUnit.Case
  doctest Tokenizer

  test "toknize an input" do
    assert Tokenizer.tokenize(~s<(first (list -33.05 5.3 "yel\\"low" 0 -3 4))>) ==
             {
               :ok,
               [
                 {:paren, :open, 0},
                 {:atom, :first, 1},
                 {:paren, :open, 7},
                 {:atom, :list, 8},
                 {:float, -33.05, 13},
                 {:float, 5.3, 20},
                 {:string, "yel\"low", 24},
                 {:int, 0, 34},
                 {:int, -3, 36},
                 {:int, 4, 39},
                 {:paren, :close, 40},
                 {:paren, :close, 41}
               ]
             }
  end
end
