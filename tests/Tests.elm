module Tests exposing (..)

import Test exposing (..)
import Expect
import Csv


type alias Parser = String -> Result (List String) Csv.Csv

expectParserParses : Parser -> String -> Csv.Csv -> Expect.Expectation
expectParserParses parse input expected =
    case parse input of
        Ok res ->
            if res == expected then
                Expect.pass
            else
                Expect.fail
                    ("Parse is incorrect.\n"
                        ++ "Expected: "
                        ++ toString expected
                        ++ "\n"
                        ++ "Actual: "
                        ++ toString res
                    )

        Err err ->
            Expect.fail ("Failed to parse input: \"" ++ toString input ++ "\"\n" ++ toString err)

expectParses : String -> Csv.Csv -> Expect.Expectation
expectParses = expectParserParses Csv.parse

expectParsesWith : Char -> String -> Csv.Csv -> Expect.Expectation
expectParsesWith fieldSep = expectParserParses <| Csv.parseWith fieldSep

expectInvalid : String -> Expect.Expectation
expectInvalid input =
    case Csv.parse input of
        Ok res ->
            Expect.fail ("Expected input to fail, but it parsed successfully: " ++ toString input)

        Err _ ->
            Expect.pass


all : Test
all =
    describe "CSV Parser"
        [ describe "Value parsing"
            [ test "Empty input" <|
                \() ->
                    expectParses "" { headers = [ "" ], records = [] }
            , test "Simple values" <|
                \() ->
                    expectParses "a,1" { headers = [ "a", "1" ], records = [] }
            , test "Special characters" <|
                \() ->
                    expectParses "< £200,Allieds" { headers = [ "< £200", "Allieds" ], records = [] }
            , test "Empty value" <|
                \() ->
                    expectParses "a,,1" { headers = [ "a", "", "1" ], records = [] }
            , test "Preserves spaces" <|
                \() ->
                    expectParses "a ,  , 1" { headers = [ "a ", "  ", " 1" ], records = [] }
            , test "Quoted newlines" <|
                \() ->
                    expectParses "a,\"\nb\n\",c" { headers = [ "a", "\nb\n", "c" ], records = [] }
            , test "Quoted quotes" <|
                \() ->
                    expectParses "a,\"\"\"\",c" { headers = [ "a", "\"", "c" ], records = [] }
            , test "Quoted commas" <|
                \() ->
                    expectParses "a,\"b,b\",c" { headers = [ "a", "b,b", "c" ], records = [] }
            , test "Quotes with trailing spaces" <|
                \() ->
                    expectInvalid "\"a\" "
            , test "Quotes with leading spaces" <|
                \() ->
                    expectInvalid "  \"a\""
            ]
        , describe "Line terminators"
            [ test "NL only" <|
                \() ->
                    expectParses
                        "a,b,c\nd,e,f\ng,h,i\n"
                        { headers = [ "a", "b", "c" ], records = [ [ "d", "e", "f" ], [ "g", "h", "i" ] ] }
            , test "CR only" <|
                \() ->
                    expectParses
                        "a,b,c\rd,e,f\rg,h,i\r"
                        { headers = [ "a", "b", "c" ], records = [ [ "d", "e", "f" ], [ "g", "h", "i" ] ] }
            , test "CRNL only" <|
                \() ->
                    expectParses
                        "a,b,c\r\nd,e,f\r\ng,h,i\r\n"
                        { headers = [ "a", "b", "c" ], records = [ [ "d", "e", "f" ], [ "g", "h", "i" ] ] }
            , test "Mixed" <|
                \() ->
                    expectParses
                        "a,b,c\rd,e,f\ng,h,i\r\n"
                        { headers = [ "a", "b", "c" ], records = [ [ "d", "e", "f" ], [ "g", "h", "i" ] ] }
            ]
        , describe "Row parsing"
            [ test "Empty headers" <|
                \() ->
                    expectParses "\n" { headers = [ "" ], records = [] }
            , test "Empty headers, empty row" <|
                \() ->
                    expectParses "\n\n" { headers = [ "" ], records = [ [ "" ] ] }
            , test "Trailing newline" <|
                \() ->
                    expectParses "a\nb\n" { headers = [ "a" ], records = [ [ "b" ] ] }
            , test "Tabulated fields" <|
                \() ->
                    expectParsesWith '\t' "a\tb\naa\tbb" { headers = [ "a", "b" ], records = [ [ "aa", "bb" ] ] }
            ]
        ]
