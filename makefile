NAME	= void
SRC	= lex.c y.tab.c
OBJ	= $(SRC:.c=.o)

all: $(NAME)

$(NAME): $(OBJ)
	gcc $(OBJ) -o $(NAME)

y.tab.h: y.tab.c

y.tab.c: yacc.yy
	yacc -d yacc.yy

lex.c: lex.l y.tab.h
	flex -o lex.c lex.l

clean:
	rm -f a.out $(NAME) $(OBJ)

.PHONY: all clean
