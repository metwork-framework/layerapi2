DEBUG=yes
ifeq ($(DEBUG),yes)
	DEBUG_CFLAGS=-g
else
	DEBUG_CFLAGS=-O2 -Os
endif
FORCE_RPATH=
ifeq ($(FORCE_RPATH),)
	FORCE_RPATH_STR=
else
	FORCE_RPATH_STR=-Wl,-rpath=$(FORCE_RPATH)
endif
PREFIX=/usr/local

ifeq ($(COVERAGE),yes)
    COVERAGE_CFLAGS=-fprofile-arcs -ftest-coverage
else
    COVERAGE_CFLAGS=
endif
_LDFLAGS=$(LDFLAGS) -L. $(shell pkg-config --libs glib-2.0) $(FORCE_RPATH_STR)
_CFLAGS=$(CFLAGS) -I. $(shell pkg-config --cflags glib-2.0) -fPIC -Wall -std=c99 -Wextra -pedantic -Werror -Wshadow -Wstrict-overflow -Wno-cast-function-type -fno-strict-aliasing -DG_LOG_DOMAIN=\"layerapi2\" $(DEBUG_CFLAGS) $(COVERAGE_CFLAGS)

CC=gcc

.PHONY: coverage leak check clean all

LIBS=liblayerapi2.so
INCLUDES=layerapi2.h
_BINS=layers test_layerapi2 layer_load_bash_cmds layer_unload_bash_cmds is_layer_loaded is_layer_installed layer_wrapper get_layer_home
BINS=$(_BINS)
VALGRIND=./valgrind.sh

OBJECTS=util.o log.o layer.o layerapi2.o wrapper.o

all:: $(BINS) $(LIBS) $(INCLUDES) layerapi2.pc

install: all
	mkdir -p $(PREFIX)/lib/pkgconfig
	mkdir -p $(PREFIX)/bin
	mkdir -p $(PREFIX)/include
	cp -f $(LIBS) $(PREFIX)/lib/
	cp -f $(BINS) $(PREFIX)/bin/
	cp -f layerapi2.pc $(PREFIX)/lib/pkgconfig/
	cp -f $(INCLUDES) $(PREFIX)/include/

layerapi2.pc: layerapi2.pc.template
	if ! test -d $(PREFIX)/lib/pkgconfig/; then mkdir -p $(PREFIX)/lib/pkgconfig; fi
	echo $(PREFIX)
	cat $< |sed s@{{PREFIX}}@$(PREFIX)@g >$@

clean::
	rm -f $(OBJECTS) $(_BINS) $(LIBS)
	rm -Rf coverage core.*
	rm -f app.info *.gcno *.gcda

layer.o: layer.c layer.h
	$(CC) -c $(_CFLAGS) $(_INCLUDES) $<

wrapper.o: wrapper.c wrapper.h
	$(CC) -c $(_CFLAGS) $(_INCLUDES) $<

layerapi2.o: layerapi2.c layerapi2.h
	$(CC) -c $(_CFLAGS) $(_INCLUDES) $<

util.o: util.c util.h
	$(CC) -c $(_CFLAGS) $(_INCLUDES) $<

log.o: log.c log.h
	$(CC) -c $(_CFLAGS) $(_INCLUDES) $<

liblayerapi2.so: $(OBJECTS)
	$(CC) -shared $(_CFLAGS) $(_INCLUDES) $(_LDFLAGS) -o $@ $^

layers: layers.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

is_layer_loaded: is_layer_loaded.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

get_layer_home: get_layer_home.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

is_layer_installed: is_layer_installed.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

layer_wrapper: layer_wrapper.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

layer_load_bash_cmds: layer_load_bash_cmds.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

layer_unload_bash_cmds: layer_unload_bash_cmds.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

test_layerapi2: test_layerapi2.c $(OBJECTS)
	$(CC) -o $@ $(_CFLAGS) $(_INCLUDES) $^ $(_LDFLAGS)

check: test_layerapi2
	./test_layerapi2 && echo "OK"

leak: test_layerapi2
	$(VALGRIND) ./test_layerapi2 && echo "OK"

coverage:
	$(MAKE) clean
	$(MAKE) COVERAGE=yes test_layerapi2
	rm -Rf coverage/* app*.info && lcov --directory . --zerocounters
	./test_layerapi2
	lcov --directory . --capture --output-file app.info
	if ! test -d coverage; then mkdir coverage; fi; genhtml --output-directory coverage app.info
