traify.exe : traify.ml
	ocamlopt -thread str.cmxa unix.cmxa threads.cmxa traify.ml -o traify.exe
	rm traify.cm* traify.o
