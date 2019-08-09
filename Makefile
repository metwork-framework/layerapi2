all:
	cd src && $(MAKE) all

clean:
	cd src && $(MAKE) clean

test:
	cd src && $(MAKE) test

install:
	cd src && $(MAKE) install

check:
	cd src && $(MAKE) check

leak:
	cd src && $(MAKE) leak
