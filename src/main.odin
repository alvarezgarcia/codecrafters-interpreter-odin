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
    EQUAL,
    EQUAL_EQUAL,
    BANG,
    BANG_EQUAL,
    LESS,
    LESS_EQUAL,
    GREATER,
    GREATER_EQUAL,
    STRING,
    EOF,
    ERROR_UNEXPECTED_CHAR,
    ERROR_UNTERMINATED_STRING
}

Token :: struct {
    type: TokenType,
    lexeme: []u8,
    line_number: int
}

Scanner :: struct {
    tokens: [dynamic]Token,
    source: []u8,
    pos: int,
    line_number: int,
    error: bool
}

capture_string :: proc(scanner: ^Scanner) -> bool {
    start_pos := scanner.pos + 1 // The next character after the opening "

    for peek(scanner) != '"' {
        char, ok := advance(scanner)
        if !ok {
            return false
        }
    }
    end_pos := scanner.pos + 1

    advance(scanner)
    add_token(scanner, TokenType.STRING, scanner.source[start_pos:end_pos])
    return true
}

advance :: proc(scanner: ^Scanner) -> (u8, bool) {
    if (scanner.pos + 1 == len(scanner.source)) {
        return 0, false
    }

    scanner.pos += 1
    return scanner.source[scanner.pos], true
}

peek :: proc(scanner: ^Scanner) -> u8 {
    if (scanner.pos + 1 == len(scanner.source)) {
        return 0
    }

    return scanner.source[scanner.pos+1]
}

add_token :: proc{
    add_token_simple,
    add_token_with_lexeme
}

add_token_with_lexeme :: proc(scanner: ^Scanner, type: TokenType, lexeme: []u8) {
    current_token := Token {
        line_number = scanner.line_number,
        type = type,
        lexeme = lexeme
    }

    append(&scanner.tokens, current_token)
}

add_token_simple :: proc(scanner: ^Scanner, type: TokenType) {
    current_token := Token {
        line_number = scanner.line_number,
        type = type
    }

    append(&scanner.tokens, current_token)
}

scanner_init :: proc(scanner: ^Scanner, source: []u8) {
    scanner.tokens = make([dynamic]Token)
    scanner.source = source
    scanner.pos = -1
    scanner.line_number = 1
}

scanner_tokenize :: proc(scanner: ^Scanner) -> bool {
    for {
        char, ok := advance(scanner)
        if !ok {
            break
        }

        switch char {
        case '(':
            add_token(scanner, TokenType.LEFT_PAREN)
        case ')':
            add_token(scanner, TokenType.RIGHT_PAREN)
        case '{':
            add_token(scanner, TokenType.LEFT_BRACE)
        case '}':
            add_token(scanner, TokenType.RIGHT_BRACE)
        case '+':
            add_token(scanner, TokenType.PLUS)
        case '-':
            add_token(scanner, TokenType.MINUS)
        case '*':
            add_token(scanner, TokenType.STAR)
        case ';':
            add_token(scanner, TokenType.SEMICOLON)
        case '.':
            add_token(scanner, TokenType.DOT)
        case ',':
            add_token(scanner, TokenType.COMMA)
        case '/':
            if (peek(scanner) == '/') {
                for peek(scanner) != '\n' {
                    char, ok := advance(scanner)
                    if !ok {
                        break
                    }
                }
            } else {
                add_token(scanner, TokenType.SLASH)
            }
        case '=':
            if (peek(scanner) == '=') {
                add_token(scanner, TokenType.EQUAL_EQUAL)
                advance(scanner)
            } else {
                add_token(scanner, TokenType.EQUAL)
            }
        case '!':
            if (peek(scanner) == '=') {
                add_token(scanner, TokenType.BANG_EQUAL)
                advance(scanner)
            } else {
                add_token(scanner, TokenType.BANG)
            }
        case '<':
            if (peek(scanner) == '=') {
                add_token(scanner, TokenType.LESS_EQUAL)
                advance(scanner)
            } else {
                add_token(scanner, TokenType.LESS)
            }
        case '>':
            if (peek(scanner) == '=') {
                add_token(scanner, TokenType.GREATER_EQUAL)
                advance(scanner)
            } else {
                add_token(scanner, TokenType.GREATER)
            }
        case '\n':
            scanner.line_number += 1
            continue
        case '"':
            if (capture_string(scanner) == false) {
                scanner.error = true
                add_token(scanner, TokenType.ERROR_UNTERMINATED_STRING)
            }
        case ' ', '\t':
        case:
            scanner.error = true
            add_token(scanner, TokenType.ERROR_UNEXPECTED_CHAR, scanner.source[scanner.pos:scanner.pos+1])
        }
    }

    add_token(scanner, TokenType.EOF)
    return scanner.error
}

scanner_free :: proc(scanner: ^Scanner) {
    delete(scanner.tokens)
}

// We repeat the big switch but this function will be removed in the future, is just for debugging
print_tokens :: proc(tokens: []Token) {
    for token in tokens {
        switch token.type {
        case TokenType.LEFT_PAREN:
            fmt.println("LEFT_PAREN ( null")
        case TokenType.RIGHT_PAREN:
            fmt.println("RIGHT_PAREN ) null")
        case TokenType.LEFT_BRACE:
            fmt.println("LEFT_BRACE { null")
        case TokenType.RIGHT_BRACE:
            fmt.println("RIGHT_BRACE } null")
        case TokenType.PLUS:
            fmt.println("PLUS + null")
        case TokenType.MINUS:
            fmt.println("MINUS - null")
        case TokenType.STAR:
            fmt.println("STAR * null")
        case TokenType.SLASH:
            fmt.println("SLASH / null")
        case TokenType.SEMICOLON:
            fmt.println("SEMICOLON ; null")
        case TokenType.DOT:
            fmt.println("DOT . null")
        case TokenType.COMMA:
            fmt.println("COMMA , null")
        case TokenType.EQUAL:
            fmt.println("EQUAL = null")
        case TokenType.BANG:
            fmt.println("BANG ! null")
        case TokenType.BANG_EQUAL:
            fmt.println("BANG_EQUAL != null")
        case TokenType.EQUAL_EQUAL:
            fmt.println("EQUAL_EQUAL == null")
        case TokenType.LESS:
            fmt.println("LESS < null")
        case TokenType.LESS_EQUAL:
            fmt.println("LESS_EQUAL <= null")
        case TokenType.GREATER:
            fmt.println("GREATER > null")
        case TokenType.GREATER_EQUAL:
            fmt.println("GREATER_EQUAL >= null")
        case TokenType.STRING:
            lexeme_s := string(token.lexeme)
            fmt.printf("STRING \"%s\" %s\n", lexeme_s, lexeme_s)
        case TokenType.ERROR_UNEXPECTED_CHAR:
           fmt.fprintf(os.stderr, "[line %d] Error: Unexpected character: %s\n", token.line_number, string(token.lexeme))
        case TokenType.ERROR_UNTERMINATED_STRING:
           fmt.fprintf(os.stderr, "[line %d] Error: Unterminated string.\n", token.line_number)
        case TokenType.EOF:
            fmt.println("EOF  null")
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
    // defer delete(file_contents)

    if !ok {
        os.exit(0)
    }

    scanner: Scanner
    // defer scanner_free(&scanner)

    scanner_init(&scanner, file_contents[:])
    error := scanner_tokenize(&scanner)
    print_tokens(scanner.tokens[:])

    if (error) {
        os.exit(65)
    } else {
        os.exit(0)
    }
}
