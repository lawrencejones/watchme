/* Precedence order is as below...

     1 - |
     2 - >, >>
     3 - &&
     4 - ;

   With {} brackets used to explictly group commands. */

{
  var Nodes = arguments[1] || require('./Nodes'),
      PATH = require('path');
}

start
  = prog:seq? { return prog; }

seq
  = l:conjunction ';' r:seq ws? { return new Nodes.SeqOp(l,r); }
  / conjunction

conjunction
  = h:redirect '&&' t:seq ws? { return new Nodes.ConjOp(h,t); }
  / redirect

redirect
  = l:pipe ws? op:rOp ws? r:file {
    return new op(l,r);
  }
  / pipe

rOp
  = '>>' { return Nodes.AppendOp; }
  / '>'  { return Nodes.RedirectOp; }

pipe
  = l:cmd '|' r:cmd { return new Nodes.PipeOp(l,r); }
  / cmd

/* Represents a command of form BIN ARGS+ */
cmd
  = ws? bin:token args:argToken* ws? { return new Nodes.Cmd(bin,args); }
  / ws? { return new Nodes.NoOp(); }

/* The smallest argument granularity. */
argToken
  = ws l:line { return l; }
  / ws t:token &{
    return !/^(>|>>|\||&&|;)$/.test(t);
  } { return t; }

/* Detects a file path */
file
  = file:token { return new Nodes.FileNode(file); }

/* Represents a quote escaped line */
line
  = "'" td:token+ "'" { return '!'+td.join(''); }
  / '"' ts:token+ '"' { return ts.join(''); }

/* Matches a single word token, considered to be a singular arguments. */
token
  = cs:chars+ { return cs.join(''); }

/* Match on any escaped special character, or on
   anything that is not null, space, !, `, &, *, (, ), +, / or \. */
chars
  = "\\" spec:[ ;!$*()+] { return "\\"+spec; }
  / c:[^\0 !`&*()+\\;] { return c; }


/* Whitespace, any amount of spaces */
ws
  = [ ]+
