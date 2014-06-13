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
  = ws? bin:word args:token* ws? { return new Node.Cmd(bin,args); }
  / ws? { return null; }


token
  = ws word:word { return word; }
  / ws line:line { return line; }

line
  = '"' content:[^"]+ '"' { return '"'+content.join('')+'"'; }
  / "'" content:[^']+ "'" { return '"'+content.join('')+'"'; }

file
  = char:[^ ]+ { return new Node.FileNode(char.join('')); }

word
  = letters:[A-Za-z0-9-_+]+ { return letters.join(''); }

ws
  = [ ]+
