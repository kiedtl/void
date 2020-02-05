CC      = clang
CFLAGS  = -O0
LDFLAGS = -fuse-ld=gold

NAME    = void
SRC     = lex.c y.tab.c    # generated files
OBJ     = $(SRC:.c=.o)

all: $(NAME)

$(NAME): $(OBJ)
	$(CC) $(OBJ) -o $(NAME) $(LDFLAGS)

y.tab.h: y.tab.c

y.tab.c: yacc.yy
	yacc -d yacc.yy

lex.c: lex.l y.tab.h
	flex -o lex.c lex.l

clean:
	rm -f $(NAME) $(OBJ) $(SRC)

.PHONY: all clean
