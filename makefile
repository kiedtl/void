NAME	= void
SRC	= lex.c y.tab.c
OBJ	= $(SRC:.c=.o)

$(NAME): $(OBJ)
	gcc $(OBJ) -o $(NAME)

y.tab.h: y.tab.c

y.tab.c: parse.yy
	yacc -d parse.yy

lex.c: lex.l y.tab.h
	flex -o lex.c lex.l
