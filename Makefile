### Configuration section

# The name of the Zlib library.  Usually -lz
ZLIB_LIB=-lz

# The directory containing the Zlib library (libz.a or libz.so)
ZLIB_LIBDIR=/usr/lib

# The directory containing the Zlib header file (zlib.h)
ZLIB_INCLUDE=/usr/include

# Where to install the library. By default: OCaml's standard library directory.
INSTALLDIR=`$(OCAMLC) -where`

# Flags for the C compiler.  -fomit-frame-pointer works around a gcc bug
# in RedHat 7.2 and Mandrake 8
CFLAGS=-O -I$(ZLIB_INCLUDE) -fomit-frame-pointer

### End of configuration section


# Modify to reflect the location of the include file <zlib.h>
ZLIBINCLUDE=-I/usr/include
# Modify to reflect the location and name of the zlib library libz.a or libz.so
ZLIBLIB=-lz

OCAMLRUN=ocamlrun
OCAMLC=ocamlc -g
OCAMLOPT=ocamlopt
OCAMLDEP=ocamldep
MKLIB=ocamlmklib
OCAMLDOC=ocamldoc

C_OBJS=\
  rijndael-alg-fst.o stubs-aes.o \
  d3des.o stubs-des.o \
  arcfour.o stubs-arcfour.o \
  sha1.o stubs-sha1.o \
  stubs-md5.o \
  stubs-zlib.o \
  stubs-misc.o

CAML_OBJS=cryptokit.cmo

all: libcryptokit.a cryptokit.cmi cryptokit.cma 

allopt: libcryptokit.a cryptokit.cmi cryptokit.cmxa 

libcryptokit.a: $(C_OBJS)
	$(MKLIB) -o cryptokit $(C_OBJS) -L$(ZLIB_LIBDIR) $(ZLIB_LIB)

cryptokit.cma: $(CAML_OBJS)
	$(MKLIB) -o cryptokit $(CAML_OBJS) -L$(ZLIB_LIBDIR) $(ZLIB_LIB)

cryptokit.cmxa: $(CAML_OBJS:.cmo=.cmx)
	$(MKLIB) -o cryptokit $(CAML_OBJS:.cmo=.cmx) -L$(ZLIB_LIBDIR) $(ZLIB_LIB)

test: test.byt
	$(OCAMLRUN) -I . ./test.byt

test.byt: libcryptokit.a cryptokit.cma test.ml
	$(OCAMLC) -o test.byt unix.cma nums.cma cryptokit.cma test.ml

clean::
	rm -f test.byt

speedtest: libcryptokit.a cryptokit.cmxa speedtest.ml
	$(OCAMLOPT) -o speedtest -ccopt -L. \
                unix.cmxa nums.cmxa cryptokit.cmxa speedtest.ml

clean::
	rm -f speedtest

install:
	cp cryptokit.cmi cryptokit.cma cryptokit.mli $(INSTALLDIR)
	cp libcryptokit.a $(INSTALLDIR)
	if test -f dllcryptokit.so; then cp dllcryptokit.so $(INSTALLDIR); fi
	if test -f cryptokit.cmxa; then cp cryptokit.cmxa cryptokit.cmx cryptokit.a $(INSTALLDIR); fi

doc: FORCE
	cd doc; $(OCAMLDOC) -html -I .. ../cryptokit.mli

FORCE:

.SUFFIXES: .ml .mli .cmo .cmi .cmx

.mli.cmi:
	$(OCAMLC) -c $(COMPFLAGS) $<

.ml.cmo:
	$(OCAMLC) -c $(COMPFLAGS) $<

.ml.cmx:
	$(OCAMLOPT) -c $(COMPFLAGS) $<

.c.o:
	$(OCAMLC) -c -ccopt "$(CFLAGS)" $<

clean::
	rm -f *.cm* *.o *.a *.so

depend:
	gcc -MM *.c > .depend
	$(OCAMLDEP) *.mli *.ml >> .depend

include .depend
