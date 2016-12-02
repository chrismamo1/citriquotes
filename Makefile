all: citriquotes.native

citriquotes.native: citriquotes.ml Makefile
	ocamlbuild -tag 'debug' -pkgs uri,opium.unix,lwt,ppx_deriving_yojson -use-ocamlfind $@

api_test.native: citriquotes.ml
	ocamlbuild -pkgs lwt,lwt.ppx,cohttp.lwt,ppx_deriving,ppx_deriving_yojson,ppx_netblob -j 0 -use-ocamlfind api_test.native

test: citriquotes.native
	OCAMLRUNPARAM=b ./citriquotes.native -p 9009 -d

run: citriquotes.native
	./citriquotes.native -p 80

clean:
	ocamlbuild -clean
