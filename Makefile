all: .metwork-framework/README.md
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

coverage:
	cd src && $(MAKE) coverage

.metwork-framework/README.md: .metwork-framework/README.md.template
	cat $< |./bootstrap/bin/penvtpl --reduce-multi-blank-lines >$@ 2>&1 || ( echo "ERROR during generation" ; echo "===== Output =====" ; cat $@ ; echo "===== /Output =====" ; rm -f $@ )
