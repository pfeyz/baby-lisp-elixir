# Baby Lisp Intepreter

This is a simple lisp interpreter exercise. At the moment only tokenization and
parsing is implemented. The parser preserves the metadata about where in the
input sting each token came from to aid in error reporting.

$ iex -S mix

    iex(1)> Parser.parse!(~s<(first (list one 2 -3.3 "fo\\"ur"))>)
    {%Tok.Seq{val: :start, char: 0},
        [
        %Tok.Sym{val: :first, char: 1},
        {%Tok.Seq{val: :start, char: 7},
            [
            %Tok.Sym{val: :list, char: 8},
            %Tok.Sym{val: :one, char: 13},
            %Tok.Num{val: 2, char: 17},
            %Tok.Num{val: -3.3, char: 19},
            %Tok.Str{val: "fo\"ur", char: 24}
            ]}
        ]}

    iex(2)> Parser.parse!(~s<(first (list one 2-3.3 "fo\\"ur"))>)
    ** (TokenizationError) 
    (first (list one 2-3.3 "fo\"ur"))
                        ^^
    iex(3)> Parser.parse!(~s<(first (list one (+ 2 3.3 "fo\\"ur"))>)
    ** (ParserError) 
    unclosed paren
    (first (list one (+ 2 3.3 "fo\"ur"))
    ^
