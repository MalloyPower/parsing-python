CC = gcc
LEX = flex
YACC = bison
CFLAGS = -Wall -std=c99
CXXFLAGS = -Wall -std=c++11
NOWARN = -Wno-unused -Wno-sign-compare
MV = /bin/mv

LFLAGS =  # -d for debugging
YFLAGS = -td --locations   # -v for parse table

OBJS = main.o parse.tab.o lex.yy.o

PARSER_DIR = ../grammar-artefacts/06-conflictfree-parsers
SCANNER_DIR = ./scanners
PREFIX=pyparse

SERIES2 = 2.0 2.2 2.3 2.4.3 2.4 2.5 2.6 2.7.2 2.7
SERIES3 = 3.0 3.1 3.2 3.3.0 3.5.0 3.6.0

default: $(PREFIX)-2.7.2 $(PREFIX)-3.6.0

all:
	for v in $(SERIES2) $(SERIES3); do $(MAKE) $(PREFIX)-$$v; done

$(PREFIX)-%: %.tab.o %.yy.o %.main.o 
	$(CXX) $(CXXFLAGS) --output $@ $^
	$(RM) parse.tab.h

%.main.o: main.c
	$(CXX) $(CXXFLAGS) -c $< --output $@

%.tab.c: $(PARSER_DIR)/%.y
	$(YACC) $(YFLAGS) --output=parse.tab.c $<
	$(MV) parse.tab.c $@

%.tab.o: %.tab.c
	$(CXX) $(CXXFLAGS) -c $<

%.yy.c: $(SCANNER_DIR)/%.l 
	$(LEX) $(LFLAGS) --outfile=$@ $<

%.yy.o: %.yy.c 
	$(CXX) $(CXXFLAGS) $(NOWARN) -c $<

clean:
	$(RM) $(PREFIX)-* *.o 
	$(RM) *.yy.c *.tab.h *.tab.c 
	$(RM) *.output
