all: citriquotes.native

citriquotes.native: citriquotes.ml Makefile
	ocamlbuild -tag 'debug' -pkgs opium.unix,lwt,ppx_deriving_yojson -use-ocamlfind $@

test: citriquotes.native
	OCAMLRUNPARAM=b ./citriquotes.native -p 9009 -d

run: citriquotes.native
	./citriquotes.native -p 80

clean:
	ocamlbuild -clean
