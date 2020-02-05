%{
#include <stdio.h>
#include "y.tab.h"

#define SAVE_STR     yylval.string = yytext;
#define TOK(t)       yylval.token = t;
#define ERR(fmt)     fprintf(stderr, fmt, yytext);
%}

%%
'write'                  SAVE_STR; return TOK_TMP_WRITE;
'_Noreturn'              return TOK(TOK_NORETURN);

#[.]+\n                  ;        // comments
[ \t\n]                  ;        // whitespace

[a-zA-Z_][a-zA-Z0-9/_]*  SAVE_STR; return TOK_IDENT;

[0-9]+                   SAVE_STR; return TOK_INT_LIT;
[0-9]+.[0-9]*            SAVE_STR; return TOK_FLOAT_LIT;
\'[.]\'                  SAVE_STR; return TOK_CHAR_LIT;
\"[.]+\"                 SAVE_STR; return TOK_STRING_LIT;
'_'                      return TOK(TOK_NULL);

':'                      return TOK(TOK_COLON);
'=>'                     return TOK(TOK_BLK_START);
';'                      return TOK(TOK_SEMICOLON);
'end'                    return TOK(TOK_BLK_END);

\(                       return TOK(TOK_PAREN_OPEN);
\)                       return TOK(TOK_PAREN_CLOSE);

'@'                      return TOK(TOK_RETURN);

'<<'                     SAVE_STR; return TOK(TOK_OP);

.                        ERR("error: '%s': unknown token.\n"); yyterminate();

%%
