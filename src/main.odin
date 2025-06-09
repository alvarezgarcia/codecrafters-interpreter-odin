package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:mem"

TokenType :: enum {
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    PLUS,
    MINUS,
    STAR,
    SLASH,
    SEMICOLON,
    COMMA,
    DOT,
    UNEXPECTED,
    EOF,
}

Token :: struct {
    type: TokenType,
    lexeme: string,
    line_number: int
}

Scanner :: struct {
    tokens: [dynamic]Token
}

scanner_init :: proc(scanner: ^Scanner) {
    scanner.tokens = make([dynamic]Token)
}

scanner_tokenize :: proc(scanner: ^Scanner, file_contents: []u8) -> bool {
    content := string(file_contents)
    current_line_number := 1
    lexical_errors_found := false

    for c in content {
        current_token := Token {
            line_number = current_line_number,
        }

        switch c {
            case '(':
                current_token.lexeme = "("
                current_token.type = TokenType.LEFT_PAREN
            case ')':
                current_token.lexeme = ")"
                current_token.type = TokenType.RIGHT_PAREN
            case '{':
                current_token.lexeme = "{"
                current_token.type = TokenType.LEFT_BRACE
            case '}':
                current_token.lexeme = "}"
                current_token.type = TokenType.RIGHT_BRACE
            case '+':
                current_token.lexeme = "+"
                current_token.type = TokenType.PLUS
            case '-':
                current_token.lexeme = "-"
                current_token.type = TokenType.MINUS
            case '*':
                current_token.lexeme = "*"
                current_token.type = TokenType.STAR
            case '/':
                current_token.lexeme = "/"
                current_token.type = TokenType.SLASH
            case ';':
                current_token.lexeme = ";"
                current_token.type = TokenType.SEMICOLON
            case '.':
                current_token.lexeme = "."
                current_token.type = TokenType.DOT
            case ',':
                current_token.lexeme = ","
                current_token.type = TokenType.COMMA
            case '\n':
                current_line_number += 1
                continue
            case:
                current_token.lexeme = fmt.tprintf("%c", c)
                current_token.type = TokenType.UNEXPECTED
                lexical_errors_found = true
        }

        append(&scanner.tokens, current_token)
    }

    append(&scanner.tokens, Token { type = TokenType.EOF, line_number = current_line_number })

    return lexical_errors_found
}

scanner_free :: proc(scanner: ^Scanner) {
    delete(scanner.tokens)
}

scanner_print :: proc(scanner: ^Scanner) {
    for token in scanner.tokens {
        if token.type == TokenType.UNEXPECTED {
            fmt.fprintf(os.stderr, "[line %d] Error: Unexpected character: %s\n", token.line_number, token.lexeme)
        } else {
            fmt.fprintf(os.stdout, "%s %s null\n", token.type, token.lexeme)
        }
    }
}

init_track_mem_allocator :: proc(track: ^mem.Tracking_Allocator) {
    mem.tracking_allocator_init(track, context.allocator)
    context.allocator = mem.tracking_allocator(track)
}

track_memory_leaks :: proc(track: ^mem.Tracking_Allocator) {
    if len(track.allocation_map) > 0 {
        fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
        for _, entry in track.allocation_map {
            fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
        }
    }
    if len(track.bad_free_array) > 0 {
        fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
        for entry in track.bad_free_array {
            fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
        }
    }
    mem.tracking_allocator_destroy(track)
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer track_memory_leaks(&track)

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
    defer delete(file_contents)

    if !ok {
        os.exit(0)
    }

    scanner: Scanner;
    defer scanner_free(&scanner)

    scanner_init(&scanner)
    errors := scanner_tokenize(&scanner, file_contents)
    scanner_print(&scanner)

    if (errors) {
        os.exit(65)
    } else {
        os.exit(0)
    }
}
