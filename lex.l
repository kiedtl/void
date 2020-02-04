%{
#include <stdio.h>
#include "parse.tab.h"

#define SAVE_STR     yylval = yytext;
#define SAVE_TOK(t)  yylval.token = t;
#define ERR(fmt)     fprintf(stderr, fmt, yytext);
%}

%%
'write'                  SAVE_STR; return TOK_TMP_WRITE;
'_Noreturn'              return TOK_NORETURN;

#[.]+\n                  ;        // comments
[ \t\n]                  ;        // whitespace

[a-zA-Z_][a-zA-Z0-9/_]*  SAVE_STR; return TOK_IDENT;

[0-9]+                   SAVE_STR; return TOK_INT_LIT;
[0-9]+.[0-9]*            SAVE_STR; return TOK_FLOAT_LIT;
\'[.]\'                  SAVE_STR; return TOK_CHAR_LIT;
\"[.]+\"                 SAVE_STR; return TOK_STRING_LIT;

':'                      return TOK_COLON;
'=>'                     return TOK_BLK_START;
';'                      return TOK_SEMICOLON;
'end'                    return TOK_BLK_END;

\(                       return TOK_PAREN_OPEN;
\)                       return TOK_PAREN_CLOSE;

'@'                      return TOK_RETURN;

'<<'                     SAVE_STR; return TOK_OP;
.                        ERR("error: '%s': unknown token.\n"); yyterminate();

%%
