%token TOK_TMP_WRITE
%token TOK_IDENT TOK_INT_LIT TOK_FLOAT_LIT TOK_CHAR_LIT TOK_STRING_LIT
%token TOK_COLON TOK_BLK_START TOK_SEMICOLON TOK_BLK_END
%token TOK_PAREN_OPEN TOK_PAREN_CLOSE
%token TOK_OP
%token TOK_NORETURN

%%

value_lit:
	 TOK_INT_LIT
	 | TOK_FLOAT_LIT
	 | TOK_CHAR_LIT
	 | TOK_STRING_LIT
	 ;

expression:
	  TOK_IDENT
	  | single_value_lit
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
     TOK_BLK_START statement_list TOK_SEMICOLON
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

fn_decl:
       fn_type_specifiers TOK_IDENT
       | fn_type_specifiers TOK_IDENT TOK_COLON fn_decl_arg_list
       ;

fn_call:
       TOK_IDENT TOK_PAREN_OPEN expressions TOK_PAREN_CLOSE
       | TOK_IDENT TOK_PAREN_OPEN TOK_PAREN_CLOSE
