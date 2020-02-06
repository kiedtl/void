#ifndef COMMON_H
#define COMMON_H

enum {
	NString = 32,
	NGlo = 256,
	NVar = 512,
	NStr = 256,
};

enum { /* types */
	NIL,
	INT,
	LNG,
	PTR,
	FUN,
};

typedef struct Symb Symb;
typedef struct Node Node;
typedef struct Stmt Stmt;

struct Symb {
	enum {
		Con,
		Tmp,
		Var,
		Glo,
	} t;

	union {
		int n;
		char v[NString];
	} u;

	unsigned long ctyp;
};

struct Node {
	char op;
	union {
		int n;
		char v[NString];
		Symb s;
	} u;
	Node *l, *r;
};

struct Stmt {
	enum {
		If,
		While,
		Seq,
		Expr,
		Break,
		Ret,
	} t;

	void *p1, *p2, *p3;
};

int line;
int nglo;
char *ini[NGlo];

/* function prototypes */
void die(const char *fmt, ...);

#endif /* #ifndef COMMON_H */
