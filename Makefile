PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

install:
	install -Dm755 claudebar $(DESTDIR)$(BINDIR)/claudebar

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/claudebar

.PHONY: install uninstall
