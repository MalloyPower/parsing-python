%%
  
%public %inline _optional(X):
  /* nothing */ {}
| X {}
;

%public %inline _choice(X):
  X {}
;

%public _star(X):
  /* nothing */ {}
| _star(X) X  {}
;

%public _plus(X):
  X {}
| _plus(X) X {}
;

