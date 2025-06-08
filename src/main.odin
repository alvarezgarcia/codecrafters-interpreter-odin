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
    EOF,
}

Token :: struct {
    type: TokenType,
    lexeme: string
}

Scanner :: struct {
    tokens: [dynamic]Token
}

scanner_init :: proc(scanner: ^Scanner) {
    scanner.tokens = make([dynamic]Token)
}

scanner_tokenize :: proc(scanner: ^Scanner, file_contents: []u8)  {
    content := string(file_contents)

    for c in content {
        switch c {
            case '(':
                append(&scanner.tokens, Token { type = TokenType.LEFT_PAREN, lexeme = "(" })
            case ')':
                append(&scanner.tokens, Token { type = TokenType.RIGHT_PAREN, lexeme = ")" })
            case '{':
                append(&scanner.tokens, Token { type = TokenType.LEFT_BRACE, lexeme = "{" })
            case '}':
                append(&scanner.tokens, Token { type = TokenType.RIGHT_BRACE, lexeme = "}" })
            case '+':
                append(&scanner.tokens, Token { type = TokenType.PLUS, lexeme = "+" })
            case '-':
                append(&scanner.tokens, Token { type = TokenType.MINUS, lexeme = "-" })
            case '*':
                append(&scanner.tokens, Token { type = TokenType.STAR, lexeme = "*" })
            case '/':
                append(&scanner.tokens, Token { type = TokenType.SLASH, lexeme = "/" })
            case ';':
                append(&scanner.tokens, Token { type = TokenType.SEMICOLON, lexeme = ";" })
            case '.':
                append(&scanner.tokens, Token { type = TokenType.DOT, lexeme = "." })
            case ',':
                append(&scanner.tokens, Token { type = TokenType.COMMA, lexeme = "," })
        }
    }

    append(&scanner.tokens, Token { type = TokenType.EOF })
}

scanner_free :: proc(scanner: ^Scanner) {
    delete(scanner.tokens)
}

scanner_print :: proc(scanner: ^Scanner) {
    for token in scanner.tokens {
        fmt.printf("%s %s null\n", token.type, token.lexeme)
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
        fmt.eprintf("Failed to read file: %s\n", filename)
        os.exit(1)
    }

    if len(file_contents) == 0 {
        fmt.eprintf("Empty file: %s\n", filename)
        os.exit(-1)
    }

    scanner: Scanner;
    defer scanner_free(&scanner)

    scanner_init(&scanner)
    scanner_tokenize(&scanner, file_contents)
    scanner_print(&scanner)
}
