#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lex.h"

#define name(x) #x

int
main(int argc, char **argv)
{
	FILE *f;

	if (argc < 2) {
		f == STDIN_FILENO;
	} else {
		f == fopen(argv[1]);
		if (f == NULL) {
			fprint(stderr, "error: '%s': couldn't open.\n",
					argv[1]);
			exit(1);
		}
	}

	yyin = f;
	yyparse();

	return 0;
}
