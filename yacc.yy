%{
#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
extern char yytext[];
void yyerror(const char *s);

%}

/* temporary: TOK_TMP_WRITE = write syscall */
%token TOK_TMP_WRITE

%token TOK_IDENT         /* identifer */
%token TOK_INT_LIT       /* integer literal */
%token TOK_FLOAT_LIT     /* float literal */
%token TOK_CHAR_LIT      /* character literal */
%token TOK_STRING_LIT    /* string literal */
%token TOK_NULL          /* the '_' (underscore) token */
%token TOK_COLON         /* the ':' (colon) token */
%token TOK_COMMA         /* the ',' (comma) token */
%token TOK_BLK_START     /* the '=>' token */
%token TOK_SEMICOLON     /* the ';' (semicolon) token */
%token TOK_BLK_END       /* the 'end' token */
%token TOK_PAREN_OPEN    /* the '(' token */
%token TOK_PAREN_CLOSE   /* the ')' token */
%token TOK_OP            /* operators */
%token TOK_NORETURN      /* the '_Noreturn' token (as in C99) */
%token TOK_RETURN        /* the '@' (at) token */

%union {
	int token;
	char *string;
	int i64;
	float f64;
}

%define parse.error verbose
%start program
%%

program: /* empty */
       | fn_decl
       ;

value_lit:
	 TOK_INT_LIT
	 | TOK_FLOAT_LIT
	 | TOK_CHAR_LIT
	 | TOK_STRING_LIT
	 ;

expression:
	  TOK_IDENT
	  | value_lit
	  | value_lit TOK_OP value_lit
	  | TOK_PAREN_OPEN expression TOK_PAREN_CLOSE
	  ;

expression_statement:
		    TOK_SEMICOLON
		    | expression TOK_SEMICOLON
		    ;

return_statement: TOK_RETURN TOK_INT_LIT TOK_SEMICOLON ;

statement:
	 expression_statement
	 | return_statement
	 | fn_call
	 ;

statement_list:
	      statement
	      | statement_list statement
	      ;

block:
     TOK_BLK_START statement_list TOK_BLK_END
     | TOK_BLK_START statement_list TOK_SEMICOLON
     ;

fn_type_specifiers:
		  TOK_NORETURN TOK_IDENT
		  | TOK_IDENT
		  ;

fn_decl_arg:
      TOK_IDENT TOK_IDENT
      ;

fn_decl_arg_list:
	fn_decl_arg
	| fn_decl_arg_list TOK_COMMA
	| TOK_NULL
	;

fn_decl:
       fn_type_specifiers TOK_IDENT block
       | fn_type_specifiers TOK_IDENT TOK_COLON fn_decl_arg_list block
       ;

fn_call:
       TOK_IDENT TOK_PAREN_OPEN expression TOK_PAREN_CLOSE
       | TOK_IDENT TOK_PAREN_OPEN TOK_PAREN_CLOSE
       ;

%%

void
yyerror(const char *s)
{
	fprintf(stderr, "=> error: %s\n", s);
}

int
yywrap(void)
{
	return 1;
}

int
main(int argc, char **argv)
{
	yyin = stdin;

	if (yyin == NULL) {
		fprintf(stderr, "error: '%s': couldn't open: ", argv[0]);
		perror(NULL);
		exit(1);
	}

	yyparse();
}
