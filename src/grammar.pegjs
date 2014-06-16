/* Precedence order is as below...

     1 - |
     2 - >, >>
     3 - &&
     4 - ;

   With {} brackets used to explictly group commands. */

{
  var Node = require('./nodes');
}

start
  = prog:seq? { return prog; }

seq
  = l:conjunction ';' r:seq ws? { return new Node.SeqOp(l,r); }
  / conjunction

conjunction
  = h:redirect '&&' t:seq ws? { return new Node.ConjunctionOp(h,t); }
  / redirect

redirect
  = l:pipe op:rOp ws? r:file ws? tail:seq {
    return new op(l,r);
  }
  / pipe

rOp
  = '>>' { return Node.RedirectOp; }
  / '>'  { return Node.AppendOp; }

pipe
  = l:cmd '|' r:cmd { return new Node.PipeOp(l,r); }
  / cmd

cmd
  = ws? bin:path args:token* ws? { return new Node.Cmd(bin,args); }
  / ws? { return null; }


token
  = ws word:word { return word; }
  / ws line:line { return line; }

/* grep
   /path/to/bin
   ../relative/bin
   bin\ with\ escaped
   ../mix/of\ all */
path
  = '~' tail:pathTail? { return PATH.resolve('~'+(pathTail || '')) }
  / path:pathTail { return PATH.resolve(path); }
pathTail
  = segs:('/' filename)+ { return segs.join(''); }

/* Any token that could be considered to be a component of a unix path,
   as a single file segment. */
filename
  = '.' / '..'
  / cs:chars+ { return cs.join(''); }

/* Match on any escaped special character, or on
   anything that is not null, space, !, `, &, *, (, ), +, / or \. */
chars
  = "\\" spec:[ !$*()+] { return "\\"+spec; }
  / c:[^\0 !`&*()+\/\\] { return c; }

line
  = '"' content:[^"]+ '"' { return '"'+content.join('')+'"'; }
  / "'" content:[^']+ "'" { return '"'+content.join('')+'"'; }

file
  = char:[^ ]+ { return new Node.FileNode(char.join('')); }

/* TODO - More comprehensive, less limiting character selection */
word
  = letters:[A-Za-z0-9-_+\[\]()]+ { return letters.join(''); }

ws
  = [ ]+
