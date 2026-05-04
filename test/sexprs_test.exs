defmodule SexprsTest do
  use ExUnit.Case
  doctest Tokenizer

  test "basic token test" do
    assert Tokenizer.tokenize!(~s<1 -2 0.334 -99.1 () ( ) + / name _var ok123 "welcome">) ==
      [
        %Tok.Num{val: 1, char: 0},
        %Tok.Num{val: -2, char: 2},
        %Tok.Num{val: 0.334, char: 5},
        %Tok.Num{val: -99.1, char: 11},
        %Tok.Seq{val: :start, char: 17},
        %Tok.Seq{val: :end, char: 18},
        %Tok.Seq{val: :start, char: 20},
        %Tok.Seq{val: :end, char: 22},
        %Tok.Op{val: :+, char: 24},
        %Tok.Op{val: :/, char: 26},
        %Tok.Atom{val: :name, char: 28},
        %Tok.Atom{val: :_var, char: 33},
        %Tok.Atom{val: :ok123, char: 38},
        %Tok.Str{val: "welcome", char: 44}
      ]
  end 

  test "tokenize a valid list" do
    assert Tokenizer.tokenize(~s<(first (list -33.05 5.3 "yel\\"low" 0 -3 4))>) ==
             {:ok,
              [
                %Tok.Seq{val: :start, char: 0},
                %Tok.Atom{val: :first, char: 1},
                %Tok.Seq{val: :start, char: 7},
                %Tok.Atom{val: :list, char: 8},
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

  test "parse an input" do
    assert Parser.parse!(~s<(first (list 1 (* 3 4) "ok"))>) ==
             {%Tok.Seq{val: :start, char: 0},
              [
                %Tok.Atom{val: :first, char: 1},
                {%Tok.Seq{val: :start, char: 7},
                 [
                   %Tok.Atom{val: :list, char: 8},
                   %Tok.Num{val: 1, char: 13},
                   {%Tok.Seq{val: :start, char: 15},
                    [
                      %Tok.Op{val: :*, char: 16},
                      %Tok.Num{val: 3, char: 18},
                      %Tok.Num{val: 4, char: 20}
                    ]},
                   %Tok.Str{val: "ok", char: 23}
                 ]}
              ]}
  end

  test "reject empty expression" do
    assert_raise ParserError, ~r".*empty.*", fn ->
      Parser.parse!("")
    end
  end

  test "reject token sequence outside of list" do
    assert_raise ParserError, ~r".*tokens may not be sequenced.*", fn ->
      Parser.parse!("3 4 5")
    end
  end

  test "detect unclosed parens" do
    assert_raise ParserError, ~r".*unclosed paren.*", fn ->
      Parser.parse!("(+ (first ( 1 2 ) 3)")
    end
  end

  test "reject empty input" do
    assert_raise ParserError, ~r"empty", fn ->
      Parser.parse!("")
    end
  end
end
