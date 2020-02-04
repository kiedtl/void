%{
#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
extern char yytext[];

void
yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "\nerror: %s\n", s);
}

int
yywrap(void)
{
	return 1;
}

int
main(int argc, char **argv)
{
	if (argc < 2) {
		yyin = stdin;
	} else {
		yyin = fopen(argv[1], "r");
	}

	if (yyin == NULL) {
		fprintf(stderr, "error: '%s': couldn't open: ", argv[0]);
		perror(NULL);
		exit(1);
	}

	yyparse();
}
%}

%token TOK_TMP_WRITE
%token TOK_IDENT TOK_INT_LIT TOK_FLOAT_LIT TOK_CHAR_LIT TOK_STRING_LIT
%token TOK_COLON TOK_BLK_START TOK_SEMICOLON TOK_BLK_END
%token TOK_PAREN_OPEN TOK_PAREN_CLOSE
%token TOK_OP
%token TOK_NORETURN TOK_RETURN

%%

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

return_statement:
		TOK_RETURN TOK_SEMICOLON
		| TOK_RETURN expression TOK_SEMICOLON
		;

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
	| fn_decl_arg_list ','
	;

fn_decl:
       fn_type_specifiers TOK_IDENT
       | fn_type_specifiers TOK_IDENT TOK_COLON fn_decl_arg_list
       ;

fn_call:
       TOK_IDENT TOK_PAREN_OPEN expression TOK_PAREN_CLOSE
       | TOK_IDENT TOK_PAREN_OPEN TOK_PAREN_CLOSE
       ;

%%

