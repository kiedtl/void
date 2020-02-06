# NOTES: CFLAGS contains -Wno-implicit-function-declaration
# to silence errors arising from compiling y.tab.c

CC      = gcc
CFLAGS  = -Wno-implicit-function-declaration -Wno-int-conversion
LDFLAGS = -fuse-ld=gold

NAME    = void
SRC     = common.c y.tab.c lex.c   # generated files
OBJ     = $(SRC:.c=.o)

all: $(NAME)

$(NAME): $(OBJ)
	$(CC) $(OBJ) -o $(NAME) $(LDFLAGS)

y.tab.h: y.tab.c

y.tab.c: yacc.yy
	yacc -dWno-yacc yacc.yy $(YFLAGS)

clean:
	rm -f $(NAME) $(OBJ) y.tab.c y.tab.h

test:
	./void < basic.vd

.PHONY: all clean test
