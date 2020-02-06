%{

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "lex.h"

#define IDIR(x) (((x) << 3) + PTR)
#define FUNC(x) (((x) << 3) + FUN)
#define DREF(x) ((x) >> 3)
#define KIND(x) ((x) & 7)
#define SIZE(x)                                    \
	(x == NIL ? (die("%d: void has no size", line), 0) : \
	 x == INT ? 4 : 8)

typedef struct Node Node;
typedef struct Symb Symb;
typedef struct Stmt Stmt;

void yyerror(const char *s);
Symb expr(Node *), lval(Node *);
void bool(Node *, int, int);

FILE *of;
int lbl, tmp;

struct {
	char v[NString];
	unsigned ctyp;
	int glo;
} varh[NVar];

void *
alloc(size_t s)
{
	void *p;

	p = malloc(s);
	if (!p)
		die("%d: out of memory", line);
	return p;
}

unsigned
hash(char *s)
{
	unsigned h;

	h = 42;
	while (*s)
		h += 11 * h + *s++;
	return h % NVar;
}

void
varclr()
{
	unsigned h;

	for (h=0; h<NVar; h++)
		if (!varh[h].glo)
			varh[h].v[0] = 0;
}

void
varadd(char *v, int glo, unsigned ctyp)
{
	unsigned h0, h;

	h0 = hash(v);
	h = h0;
	do {
		if (varh[h].v[0] == 0) {
			strcpy(varh[h].v, v);
			varh[h].glo = glo;
			varh[h].ctyp = ctyp;
			return;
		}
		if (strcmp(varh[h].v, v) == 0)
			die("%d: double definition", line);
		h = (h+1) % NVar;
	} while(h != h0);
	die("%d: too many variables", line);
}

Symb *
varget(char *v)
{
	static Symb s;
	unsigned h0, h;

	h0 = hash(v);
	h = h0;
	do {
		if (strcmp(varh[h].v, v) == 0) {
			if (!varh[h].glo) {
				s.t = Var;
				strcpy(s.u.v, v);
			} else {
				s.t = Glo;
				s.u.n = varh[h].glo;
			}
			s.ctyp = varh[h].ctyp;
			return &s;
		}
		h = (h+1) % NVar;
	} while (h != h0 && varh[h].v[0] != 0);
	return 0;
}

char
irtyp(unsigned ctyp)
{
	return SIZE(ctyp) == 8 ? 'l' : 'w';
}

void
psymb(Symb s)
{
	switch (s.t) {
	case Tmp:
		fprintf(of, "%%t%d", s.u.n);
		break;
	case Var:
		fprintf(of, "%%%s", s.u.v);
		break;
	case Glo:
		fprintf(of, "$glo%d", s.u.n);
		break;
	case Con:
		fprintf(of, "%d", s.u.n);
		break;
	}
}

void
sext(Symb *s)
{
	fprintf(of, "\t%%t%d =l extsw ", tmp);
	psymb(*s);
	fprintf(of, "\n");
	s->t = Tmp;
	s->ctyp = LNG;
	s->u.n = tmp++;
}

unsigned
prom(int op, Symb *l, Symb *r)
{
	Symb *t;
	int sz;

	if (l->ctyp == r->ctyp && KIND(l->ctyp) != PTR)
		return l->ctyp;

	if (l->ctyp == LNG && r->ctyp == INT) {
		sext(r);
		return LNG;
	}
	if (l->ctyp == INT && r->ctyp == LNG) {
		sext(l);
		return LNG;
	}

	if (op == '+') {
		if (KIND(r->ctyp) == PTR) {
			t = l;
			l = r;
			r = t;
		}
		if (KIND(r->ctyp) == PTR)
			die("%d: pointers added", line);
		goto Scale;
	}

	if (op == '-') {
		if (KIND(l->ctyp) != PTR)
			die("%d: pointer substracted from integer", line);
		if (KIND(r->ctyp) != PTR)
			goto Scale;
		if (l->ctyp != r->ctyp)
			die("%d: non-homogeneous pointers in substraction", line);
		return LNG;
	}

Scale:
	sz = SIZE(DREF(l->ctyp));
	if (r->t == Con)
		r->u.n *= sz;
	else {
		if (irtyp(r->ctyp) != 'l')
			sext(r);
		fprintf(of, "\t%%t%d =l mul %d, ", tmp, sz);
		psymb(*r);
		fprintf(of, "\n");
		r->u.n = tmp++;
	}
	return l->ctyp;
}

void
load(Symb d, Symb s)
{
	char t;

	fprintf(of, "\t");
	psymb(d);
	t = irtyp(d.ctyp);
	fprintf(of, " =%c load%c ", t, t);
	psymb(s);
	fprintf(of, "\n");
}

void
call(Node *n, Symb *sr)
{
	Node *a;
	char *f;
	unsigned ft;

	f = n->l->u.v;
	if (varget(f)) {
		ft = varget(f)->ctyp;
		if (KIND(ft) != FUN)
			die("%d: invalid call", line);
	} else
		ft = FUNC(INT);
	sr->ctyp = DREF(ft);
	for (a=n->r; a; a=a->r)
		a->u.s = expr(a->l);
	fprintf(of, "\t");
	psymb(*sr);
	fprintf(of, " =%c call $%s(", irtyp(sr->ctyp), f);
	for (a=n->r; a; a=a->r) {
		fprintf(of, "%c ", irtyp(a->u.s.ctyp));
		psymb(a->u.s);
		fprintf(of, ", ");
	}
	fprintf(of, "...)\n");
}

Symb
expr(Node *n)
{
	static char *otoa[] = {
		['+'] = "add",
		['-'] = "sub",
		['*'] = "mul",
		['/'] = "div",
		['%'] = "rem",
		['&'] = "and",
		['<'] = "cslt",  /* meeeeh, wrong for pointers! */
		['l'] = "csle",
		['e'] = "ceq",
		['n'] = "cne",
	};
	Symb sr, s0, s1, sl;
	int o, l;
	char ty[2];

	sr.t = Tmp;
	sr.u.n = tmp++;

	switch (n->op) {

	case 0:
		abort();

	case 'o':
	case 'a':
		l = lbl;
		lbl += 3;
		bool(n, l, l+1);
		fprintf(of, "@l%d\n", l);
		fprintf(of, "\tjmp @l%d\n", l+2);
		fprintf(of, "@l%d\n", l+1);
		fprintf(of, "\tjmp @l%d\n", l+2);
		fprintf(of, "@l%d\n", l+2);
		fprintf(of, "\t");
		sr.ctyp = INT;
		psymb(sr);
		fprintf(of, " =w phi @l%d 1, @l%d 0\n", l, l+1);
		break;

	case 'V':
		s0 = lval(n);
		sr.ctyp = s0.ctyp;
		load(sr, s0);
		break;

	case 'N':
		sr.t = Con;
		sr.u.n = n->u.n;
		sr.ctyp = INT;
		break;

	case 'S':
		sr.t = Glo;
		sr.u.n = n->u.n;
		sr.ctyp = IDIR(INT);
		break;

	case 'C':
		call(n, &sr);
		break;

	case '@':
		s0 = expr(n->l);
		if (KIND(s0.ctyp) != PTR)
			die("%d: dereference of a non-pointer", line);
		sr.ctyp = DREF(s0.ctyp);
		load(sr, s0);
		break;

	case 'A':
		sr = lval(n->l);
		sr.ctyp = IDIR(sr.ctyp);
		break;

	case '=':
		s0 = expr(n->r);
		s1 = lval(n->l);
		sr = s0;
		if (s1.ctyp == LNG &&  s0.ctyp == INT)
			sext(&s0);
		if (s0.ctyp != IDIR(NIL) || KIND(s1.ctyp) != PTR)
		if (s1.ctyp != IDIR(NIL) || KIND(s0.ctyp) != PTR)
		if (s1.ctyp != s0.ctyp)
			die("%d: invalid assignment", line);
		fprintf(of, "\tstore%c ", irtyp(s1.ctyp));
		goto Args;

	case 'P':
	case 'M':
		o = n->op == 'P' ? '+' : '-';
		sl = lval(n->l);
		s0.t = Tmp;
		s0.u.n = tmp++;
		s0.ctyp = sl.ctyp;
		load(s0, sl);
		s1.t = Con;
		s1.u.n = 1;
		s1.ctyp = INT;
		goto Binop;

	default:
		s0 = expr(n->l);
		s1 = expr(n->r);
		o = n->op;
	Binop:
		sr.ctyp = prom(o, &s0, &s1);
		if (strchr("ne<l", n->op)) {
			sprintf(ty, "%c", irtyp(sr.ctyp));
			sr.ctyp = INT;
		} else
			strcpy(ty, "");
		fprintf(of, "\t");
		psymb(sr);
		fprintf(of, " =%c", irtyp(sr.ctyp));
		fprintf(of, " %s%s ", otoa[o], ty);
	Args:
		psymb(s0);
		fprintf(of, ", ");
		psymb(s1);
		fprintf(of, "\n");
		break;

	}
	if (n->op == '-'
	&&  KIND(s0.ctyp) == PTR
	&&  KIND(s1.ctyp) == PTR) {
		fprintf(of, "\t%%t%d =l div ", tmp);
		psymb(sr);
		fprintf(of, ", %d\n", SIZE(DREF(s0.ctyp)));
		sr.u.n = tmp++;
	}
	if (n->op == 'P' || n->op == 'M') {
		fprintf(of, "\tstore%c ", irtyp(sl.ctyp));
		psymb(sr);
		fprintf(of, ", ");
		psymb(sl);
		fprintf(of, "\n");
		sr = s0;
	}
	return sr;
}

Symb
lval(Node *n)
{
	Symb sr;

	switch (n->op) {
	default:
		die("%d: invalid lvalue", line);
	case 'V':
		if (!varget(n->u.v))
			die("%d: undefined variable", line);
		sr = *varget(n->u.v);
		break;
	case '@':
		sr = expr(n->l);
		if (KIND(sr.ctyp) != PTR)
			die("%d: dereference of a non-pointer", line);
		sr.ctyp = DREF(sr.ctyp);
		break;
	}
	return sr;
}

void
bool(Node *n, int lt, int lf)
{
	Symb s;
	int l;

	switch (n->op) {
	default:
		s = expr(n); /* TODO: insert comparison to 0 with proper type */
		fprintf(of, "\tjnz ");
		psymb(s);
		fprintf(of, ", @l%d, @l%d\n", lt, lf);
		break;
	case 'o':
		l = lbl;
		lbl += 1;
		bool(n->l, lt, l);
		fprintf(of, "@l%d\n", l);
		bool(n->r, lt, lf);
		break;
	case 'a':
		l = lbl;
		lbl += 1;
		bool(n->l, l, lf);
		fprintf(of, "@l%d\n", l);
		bool(n->r, lt, lf);
		break;
	}
}

int
stmt(Stmt *s, int b)
{
	int l, r;
	Symb x;

	if (!s)
		return 0;

	switch (s->t) {
	case Ret:
		x = expr(s->p1);
		fprintf(of, "\tret ");
		psymb(x);
		fprintf(of, "\n");
		return 1;
	case Break:
		if (b < 0)
			die("%d: break not in loop", line);
		fprintf(of, "\tjmp @l%d\n", b);
		return 1;
	case Expr:
		expr(s->p1);
		return 0;
	case Seq:
		return stmt(s->p1, b) || stmt(s->p2, b);
	case If:
		l = lbl;
		lbl += 3;
		bool(s->p1, l, l+1);
		fprintf(of, "@l%d\n", l);
		if (!(r=stmt(s->p2, b)))
		if (s->p3)
			fprintf(of, "\tjmp @l%d\n", l+2);
		fprintf(of, "@l%d\n", l+1);
		if (s->p3)
		if (!(r &= stmt(s->p3, b)))
			fprintf(of, "@l%d\n", l+2);
		return s->p3 && r;
	case While:
		l = lbl;
		lbl += 3;
		fprintf(of, "@l%d\n", l);
		bool(s->p1, l+1, l+2);
		fprintf(of, "@l%d\n", l+1);
		if (!stmt(s->p2, l+2))
			fprintf(of, "\tjmp @l%d\n", l);
		fprintf(of, "@l%d\n", l+2);
		return 0;
	}
}

Node*
mknode(char op, Node *l, Node *r)
{
	Node *n;

	n = alloc(sizeof *n);
	n->op = op;
	n->l = l;
	n->r = r;
	return n;
}

Node *
mkidx(Node *a, Node *i)
{
	Node *n;

	n = mknode('+', a, i);
	n = mknode('@', n, 0);
	return n;
}

Node *
mkneg(Node *n)
{
	static Node *z;

	if (!z) {
		z = mknode('N', 0, 0);
		z->u.n = 0;
	}
	return mknode('-', z, n);
}

Stmt *
mkstmt(int t, void *p1, void *p2, void *p3)
{
	Stmt *s;

	s = alloc(sizeof *s);
	s->t = t;
	s->p1 = p1;
	s->p2 = p2;
	s->p3 = p3;
	return s;
}

Node *
param(char *v, unsigned ctyp, Node *pl)
{
	Node *n;

	if (ctyp == NIL)
		die("%d: invalid void declaration", line);
	n = mknode(0, 0, pl);
	varadd(v, 0, ctyp);
	strcpy(n->u.v, v);
	return n;
}

Stmt *
mkfor(Node *ini, Node *tst, Node *inc, Stmt *s)
{
	Stmt *s1, *s2;

	if (ini)
		s1 = mkstmt(Expr, ini, 0, 0);
	else
		s1 = 0;
	if (inc) {
		s2 = mkstmt(Expr, inc, 0, 0);
		s2 = mkstmt(Seq, s, s2, 0);
	} else
		s2 = s;
	if (!tst) {
		tst = mknode('N', 0, 0);
		tst->u.n = 1;
	}
	s2 = mkstmt(While, tst, s2, 0);
	if (s1)
		return mkstmt(Seq, s1, s2, 0);
	else
		return s2;
}

%}

%union {
	Node *n;
	Stmt *s;
	unsigned u;
}

%token <n> NUM
%token <n> STR
%token <n> IDENT
%token PP MM LE GE SIZEOF

%token TVOID TINT TLNG
%token IF ELSE FOR BREAK RETURN

%right '='
%left OR
%left AND
%left '&'
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'

%type <u> type
%type <s> stmt stmts
%type <n> expr exp0 pref post arg0 arg1 par0 par1

%%

prog: func prog | fdcl prog | idcl prog | ;

fdcl: type IDENT '(' ')' ';'
{
	varadd($2->u.v, 1, FUNC($1));
};

idcl: type IDENT ';'
{
	if ($1 == NIL)
		die("%d: invalid void declaration", line);
	if (nglo == NGlo)
		die("%d: too many string literals", line);
	ini[nglo] = alloc(sizeof "{ x 0 }");
	sprintf(ini[nglo], "{ %c 0 }", irtyp($1));
	varadd($2->u.v, nglo++, $1);
};

init:
{
	varclr();
	tmp = 0;
};

func: init prot '{' dcls stmts '}'
{
	if (!stmt($5, -1))
		fprintf(of, "\tret 0\n");
	fprintf(of, "}\n\n");
};

prot: IDENT '(' par0 ')'
{
	Symb *s;
	Node *n;
	int t, m;

	varadd($1->u.v, 1, FUNC(INT));
	fprintf(of, "export function w $%s(", $1->u.v);
	n = $3;
	if (n)
		for (;;) {
			s = varget(n->u.v);
			fprintf(of, "%c ", irtyp(s->ctyp));
			fprintf(of, "%%t%d", tmp++);
			n = n->r;
			if (n)
				fprintf(of, ", ");
			else
				break;
		}
	fprintf(of, ") {\n");
	fprintf(of, "@l%d\n", lbl++);
	for (t=0, n=$3; n; t++, n=n->r) {
		s = varget(n->u.v);
		m = SIZE(s->ctyp);
		fprintf(of, "\t%%%s =l alloc%d %d\n", n->u.v, m, m);
		fprintf(of, "\tstore%c %%t%d", irtyp(s->ctyp), t);
		fprintf(of, ", %%%s\n", n->u.v);
	}
};

par0: par1
    |                     { $$ = 0; }
    ;
par1: type IDENT ',' par1 { $$ = param($2->u.v, $1, $4); }
    | type IDENT          { $$ = param($2->u.v, $1, 0); }
    ;


dcls: | dcls type IDENT ';'
{
	int s;
	char *v;

	if ($2 == NIL)
		die("%d: invalid void declaration", line);
	v = $3->u.v;
	s = SIZE($2);
	varadd(v, 0, $2);
	fprintf(of, "\t%%%s =l alloc%d %d\n", v, s, s);
};

type: type '*' { $$ = IDIR($1); }
    | TINT     { $$ = INT; }
    | TLNG     { $$ = LNG; }
    | TVOID    { $$ = NIL; }
    ;

stmt: ';'                            { $$ = 0; }
    | '{' stmts '}'                  { $$ = $2; }
    | BREAK ';'                      { $$ = mkstmt(Break, 0, 0, 0); }
    | RETURN expr ';'                { $$ = mkstmt(Ret, $2, 0, 0); }
    | expr ';'                       { $$ = mkstmt(Expr, $1, 0, 0); }
    | IF '(' expr ')' stmt ELSE stmt { $$ = mkstmt(If, $3, $5, $7); }
    | IF '(' expr ')' stmt           { $$ = mkstmt(If, $3, $5, 0); }
    | FOR '(' exp0 ';' exp0 ';' exp0 ')' stmt
                                     { $$ = mkfor($3, $5, $7, $9); }
    ;

stmts: stmts stmt { $$ = mkstmt(Seq, $1, $2, 0); }
     |            { $$ = 0; }
     ;

expr: pref
    | expr '=' expr     { $$ = mknode('=', $1, $3); }
    | expr '+' expr     { $$ = mknode('+', $1, $3); }
    | expr '-' expr     { $$ = mknode('-', $1, $3); }
    | expr '*' expr     { $$ = mknode('*', $1, $3); }
    | expr '/' expr     { $$ = mknode('/', $1, $3); }
    | expr '%' expr     { $$ = mknode('%', $1, $3); }
    | expr '<' expr     { $$ = mknode('<', $1, $3); }
    | expr '>' expr     { $$ = mknode('<', $3, $1); }
    | expr LE expr      { $$ = mknode('l', $1, $3); }
    | expr GE expr      { $$ = mknode('l', $3, $1); }
    | expr EQ expr      { $$ = mknode('e', $1, $3); }
    | expr NE expr      { $$ = mknode('n', $1, $3); }
    | expr '&' expr     { $$ = mknode('&', $1, $3); }
    | expr AND expr     { $$ = mknode('a', $1, $3); }
    | expr OR expr      { $$ = mknode('o', $1, $3); }
    ;

exp0: expr
    |                   { $$ = 0; }
    ;

pref: post
    | '-' pref          { $$ = mkneg($2); }
    | '*' pref          { $$ = mknode('@', $2, 0); }
    | '&' pref          { $$ = mknode('A', $2, 0); }
    ;

post: NUM
    | STR
    | IDENT
    | SIZEOF '(' type ')' { $$ = mknode('N', 0, 0); $$->u.n = SIZE($3); }
    | '(' expr ')'        { $$ = $2; }
    | IDENT '(' arg0 ')'  { $$ = mknode('C', $1, $3); }
    | post '[' expr ']'   { $$ = mkidx($1, $3); }
    | post PP             { $$ = mknode('P', $1, 0); }
    | post MM             { $$ = mknode('M', $1, 0); }
    ;

arg0: arg1
    |               { $$ = 0; }
    ;
arg1: expr          { $$ = mknode(0, $1, 0); }
    | expr ',' arg1 { $$ = mknode(0, $1, $3); }
    ;

%%

void
yyerror(const char *s)
{
	die("=> %s", s);
}

int
main(void)
{
	of = stdout;
	nglo = 1;
	
	if (yyparse() != 0)
		die("=> error: unable to proceed, exiting.");
	for (int i = 1; i < nglo; i++)
		fprintf(of, "data $glo%d = %s\n", i, ini[i]);
	return 0;
}
