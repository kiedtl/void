#ifndef TOKENS_H
#define TOKENS_H

enum {
	/* conditional/loop keywords */
	TOK_COND_IF,
	TOK_COND_ELIF,
	TOK_COND_ELSE,
	TOK_WHILE,

	/* foreign/include keywords */
	TOK_FOREIGN,
	TOK_INCLUDE,
	
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

	/* operators */
	TOK_UNARY_OP,
	TOK_OP,

	/* parenthesis */
	TOK_PAREN_OPEN,
	TOK_PAREN_CLOSE,

	/* temporary */
	TOK_TMP_WRITE,

	/* return */
	TOK_NORETURN,
	TOK_RETURN,
}

#endif
