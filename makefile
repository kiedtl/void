# NOTES: CFLAGS contains -Wno-implicit-function-declaration
# to silence errors arising from compiling y.tab.c

CC      = clang
CFLAGS  = -O0 -Wno-implicit-function-declaration
LDFLAGS = -fuse-ld=gold

NAME    = void
SRC     = lex.c y.tab.c    # generated files
OBJ     = $(SRC:.c=.o)

all: $(NAME)

$(NAME): $(OBJ)
	$(CC) $(OBJ) -o $(NAME) $(LDFLAGS)

y.tab.h: y.tab.c

y.tab.c: yacc.yy
	yacc -dWno-yacc yacc.yy $(YFLAGS)

lex.c: lex.l y.tab.h
	flex -o lex.c lex.l

clean:
	rm -f $(NAME) $(OBJ) $(SRC)

test: $(NAME)
	./void < basic.vd

.PHONY: all clean test
