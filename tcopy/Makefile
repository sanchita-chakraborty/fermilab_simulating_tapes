# Makefile for linux port of Tcopy
# By Nicholas Harbour, 2000

CURDIR = "../"
include ../config.mk

BINARY=tcopy
MANPAGE=tcopy.1
BIN_PATH=$(PREFIX)/bin/
MAN_PATH=$(PREFIX)/$(MANDIR)/man1/
OBJS=tcopy.o
CC=gcc
OPTS=-Wall

all: tcopy install

tcopy: clean $(OBJS)
	$(CC) $(OPTS) -o $(BINARY) $(OBJS) 

install:	tcopy
	cp $(BINARY) $(BIN_PATH)
	cp $(MANPAGE) $(MAN_PATH)

clean:
	rm -f $(OBJS) tcopy

