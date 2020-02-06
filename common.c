#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"

void
die(const char *fmt, ...)
{
	va_list args;

	va_start(args, fmt);
	fprintf(stderr, fmt, args);
	va_end(args);

	if (fmt[0] && fmt[strlen(fmt) - 1] == ':') {
		fputc(' ', stderr);
		perror(NULL);
	} else {
		fputc('\n', stderr);
	}

	exit(1);
}
