%{
#include <stdio.h>
#include "y.tab.h"

#define SAVE      yylval.string = yytext;
#define TOK(t)    yylval.token = t;
#define ERR(fmt)  fprintf(stderr, fmt, yytext);
%}

%%
'write'                  SAVE; return TOK_TMP_WRITE;
'_Noreturn'              SAVE; return TOK(TOK_NORETURN);

#[.]+\n                  ;        // comments
[ \t\n]                  ;        // whitespace

[a-zA-Z][a-zA-Z0-9/]*    SAVE; return TOK_IDENT;

[0-9]+                   SAVE; return TOK(TOK_INT_LIT);
[0-9]+\.[0-9]*           SAVE; return TOK(TOK_FLOAT_LIT);
\'[.]\'                  SAVE; return TOK(TOK_CHAR_LIT);
\"[.]+\"                 SAVE; return TOK_STRING_LIT;
\_                       SAVE; return TOK(TOK_NULL);

:                        SAVE; return TOK(TOK_COLON);
=>                       SAVE; return TOK(TOK_BLK_START);
\;                       SAVE; return TOK(TOK_SEMICOLON);
'end'                    SAVE; return TOK(TOK_BLK_END);

\(                       SAVE; return TOK(TOK_PAREN_OPEN);
\)                       SAVE; return TOK(TOK_PAREN_CLOSE);

,                        SAVE; return TOK(TOK_COMMA);

'ret'                    SAVE; return TOK(TOK_RETURN);

\<\<                     SAVE; return TOK(TOK_OP);

%%
