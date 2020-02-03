#ifndef TOKENS_H
#define TOKENS_H

enum token_type {
	/* conditional/loop keywords */
	TOK_COND_IF,
	TOK_COND_ELIF,
	TOK_COND_ELSE,
	TOK_WHILE,

	/* foreign/include keywords */
	TOK_FOREIGN,
	TOK_INCLUDE,
	
	/* const keyword */
	TOK_CONST,

	/* type keywords */
	TOK_ISIZE,
	TOK_I8
	TOK_I16,
	TOK_I32,
	TOK_I64,
	TOK_USIZE,
	TOK_U8,
	TOK_U16,
	TOK_U32,
	TOK_U64,
	TOK_FSIZE,
	TOK_F8,
	TOK_F16,
	TOK_F32,
	TOK_F64,

	/* literals */
	TOK_FLOAT_LIT,
	TOK_INT_LIT,
	TOK_CHAR_LIT,
	TOK_STRING_LIT,

	/* function, constant, or variable identifier */
	TOK_IDENT,

	/* colon (':') */
	TOK_COLON,

	/* comma (',') */
	TOK_COMMA,

	/* block start ('=>') */
	TOK_BLK_START,

	/* block end ('end') */
	TOK_BLK_END,

	/* semicolon */
	TOK_SEMICOLON,

	/* assignment operator */
	TOK_ASSIGN_OP,

	/* logical operators */
	TOK_LOG_AND,
	TOK_LOG_OR,
	TOK_LOG_EQ,
	TOK_LOG_NEQ,
	TOK_LOG_LT,
	TOK_LOG_GT,
	TOK_LOG_LTE,
	TOK_LOG_GTE,

	/* bitwise operators */
	TOK_BW_SHIFTLEFT,
	TOK_BW_SHIFTRIGHT,
	TOK_BW_AND,
	TOK_BW_OR,
	TOK_BW_XOR,
	TOK_BW_NOT,

	/* bitwise assignment operators */
	TOK_ASSIGN_BW_SHIFTLEFT,
	TOK_ASSIGN_BW_SHIFTRIGHT,
	TOK_ASSIGN_BW_AND,
	TOK_ASSIGN_BW_OR,
	TOK_ASSIGN_BW_XOR,
	TOK_ASSIGN_BW_NOT,
}

typedef struct token {
	enum token_type type;
	char *data;
	struct token *next;
} token;

#endif
