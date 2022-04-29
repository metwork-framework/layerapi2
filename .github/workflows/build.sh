#!/bin/bash

set -x

yum -y install glib2-devel glib2 make gcc valgrind which
cd /src
make
make check
make leak
make clean
make
make install
