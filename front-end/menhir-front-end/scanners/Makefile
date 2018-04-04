ORIG_SCANNER_V2=orig-scan-v2.mll   # 2.7.2 scanner
ORIG_SCANNER_V3=orig-scan-v3.mll   # 3.3.0 scanner


all: v2 v3

v2: 2.0.mll 2.2.mll 2.3.mll 2.4.mll 2.4.3.mll 2.5.mll 2.6.mll 2.7.mll 2.7.2.mll

v3: 3.0.mll 3.1.mll 3.2.mll 3.3.0.mll 3.5.0.mll 3.6.0.mll

# 2.5 and after are just the same as the v2 scanner:
2.5.mll 2.6.mll 2.7.mll 2.7.2.mll: $(ORIG_SCANNER_V2)
	cp $< $@

# 2.4, 2.4.3 missing keywords: as, with
2.4.mll 2.4.3.mll: $(ORIG_SCANNER_V2)
	egrep -v '^\| "(as|with)"' $< >$@

# 2.2, 2.3 also missing operator: @
2.2.mll 2.3.mll: 2.4.mll
	egrep -v '^\| "@"' $< >$@

# 2.0 also missing keyword/operators: yield, //, //= 
2.0.mll: 2.2.mll
	egrep -v '^\| "(yield|//|//=)"' $< >$@


# The v3 scanner is a 3.0 scanner by default:
3.0.mll: $(ORIG_SCANNER_V3)
	cp $< $@

# 3.1 is same as 3.0 but add operator: <>
3.1.mll: 3.0.mll
	sed -e '/^| name/i\
| "<>"      { GRLT }' $< >$@

# 3.2 has a slightly different definition of stringprefix
3.2.mll: 3.1.mll
	sed -e '/^let stringprefix/c\
let stringprefix     = bytesprefix_32 | strngprefix_32' $< >$@

# 3.2 has another slightly different definition of stringprefix
3.3.0.mll: 3.1.mll
	sed -e '/^let stringprefix/c\
let stringprefix     = bytesprefix_33 | strngprefix_33' $< >$@

# 3.5 adds keyword/operators: @=, async, await
3.5.0.mll: 3.3.0.mll
	sed -e '/^| name/i\
| "@="      { ATEQ } \
| "await"   { AWAIT } \
| "async"   { ASYNC }' $< >$@

# 3.6.0 now allows 'f' as string prefix
3.6.0.mll: 3.5.0.mll
	sed -e '/^let stringprefix/c\
let stringprefix     = bytesprefix_36 | strngprefix_36' $< >$@


clean:
	$(RM) [23].*.ml [23].*.mll


