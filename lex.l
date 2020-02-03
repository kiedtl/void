%{
#include <stdio.h>
#include "tokens.h"
#include "types.h"

#define SAVE_STR    yylval = yytext;
#define SAVE_TOK(t) yylval.token = t;
%}

%%

[ \t\n]                 ;
[a-zA-Z_][a-zA-Z0-9_]*  SAVE_STR; return TOK_IDENT;
[0-9]+                  SAVE_STR; return TOK_INT_LIT;
[0-9]+.[0-9]*           SAVE_STR; return TOK_FLOAT_LIT;

%%
