CC     ?= gcc
CFLAGS ?= -O2 -fPIC -Wall -Wextra
PYTHON ?= python3

all: libsha512.so

libsha512.so: sha512.s
	$(CC) $(CFLAGS) -shared -o $@ $<

test: libsha512.so
	$(PYTHON) tests/test_sha512.py

clean:
	rm -f libsha512.so

.PHONY: all test clean
