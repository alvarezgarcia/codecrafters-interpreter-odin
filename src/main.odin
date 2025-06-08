package main

import "core:os"
import "core:fmt"
import "core:strings"

TokenType :: enum {
    LEFT_PAREN,
    RIGHT_PAREN,
    EOF,
}

Token :: struct {
    type: TokenType,
    lexeme: string
}

scan_tokens :: proc(file_contents: []u8) {
    content := string(file_contents)
    tokens := make([dynamic]Token)
    defer delete(tokens)

    for c in content {
        switch c {
            case '(':
                append(&tokens, Token { type = TokenType.LEFT_PAREN, lexeme = "(" })
            case ')':
                append(&tokens, Token { type = TokenType.LEFT_PAREN, lexeme = ")" })
        }
    }

    append(&tokens, Token { type = TokenType.EOF })
    print_tokens(tokens[:])
}

print_tokens :: proc(tokens: []Token) {
    for token in tokens {
        fmt.printf("%s %s null\n", token.type, token.lexeme)
    }
}

main :: proc() {
    if len(os.args) < 3 {
        fmt.eprintln("Usage: ./your_program.sh tokenize <filename>")
        os.exit(1)
    }

    command := os.args[1]
    filename := os.args[2]

    if command != "tokenize" {
        fmt.eprintf("Unknown command: %s\n", command)
        os.exit(1)
    }

    file_contents, ok := os.read_entire_file(filename)
    if !ok {
        fmt.eprintf("Failed to read file: %s\n", filename)
        os.exit(1)
    }

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    // fmt.eprintln("Logs from your program will appear here!")

    // Uncomment this block to pass the first stage
    if len(file_contents) > 0 {
        scan_tokens(file_contents)
    } else {
        fmt.println("EOF  null") // Placeholder, replace this line when implementing the scanner
    }
}
