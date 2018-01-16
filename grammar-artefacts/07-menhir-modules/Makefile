

all: series2 series3

series2: 2.0.ml 2.2.ml 2.4.ml 2.4.3.ml 2.5.ml 2.6.ml 2.7.ml
series3: 3.0.ml 3.1.ml 3.2.ml 3.3.0.ml 3.5.0.ml 3.6.0.ml

%.ml: 
	menhir --infer --base $* ../ebnfmacros.mly *_$*_*.mly


clean:
	$(RM) *.ml *.mli
