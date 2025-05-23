type pos = Tokens.linenum
type lexresult = Tokens.token

val lineNum = ErrorMsg.lineNum
val linePos = ErrorMsg.linePos
val commentLevel = ref 0
val stringBuffer = ref ""
val stringStart = ref 0
val inString = ref false

fun err(p1,p2) = ErrorMsg.error p1

fun newLine pos = 
  let val oldPos = !linePos
  in lineNum := !lineNum + 1;
     linePos := pos :: oldPos
  end

fun eof() = 
  let 
    val pos = hd(!linePos)
  in 
    if !commentLevel > 0 
    then (ErrorMsg.error pos "Unclosed comment"; Tokens.EOF(pos,pos))
    else if !inString
    then (ErrorMsg.error pos "Unclosed string"; Tokens.EOF(pos,pos))
    else Tokens.EOF(pos,pos)
  end

%%
%header (functor TigerLexFun(structure Tokens: Tiger_TOKENS));
%s COMMENT STRING;

digit=[0-9];
alpha=[a-zA-Z];
whitespace=[\t\ ];
eol=[\n\r];

%%
<INITIAL,COMMENT>{eol}   => (newLine yypos; continue());
<INITIAL>{whitespace}    => (continue());

<INITIAL>"/*"           => (commentLevel := !commentLevel + 1; 
                           YYBEGIN COMMENT; 
                           continue());
<COMMENT>"/*"           => (commentLevel := !commentLevel + 1; 
                           continue());
<COMMENT>"*/"           => (commentLevel := !commentLevel - 1;
                           if !commentLevel = 0 then YYBEGIN INITIAL else ();
                           continue());
<COMMENT>.              => (continue());

<INITIAL>type           => (Tokens.TYPE(yypos,yypos+4));
<INITIAL>var            => (Tokens.VAR(yypos,yypos+3));
<INITIAL>function       => (Tokens.FUNCTION(yypos,yypos+8));
<INITIAL>break          => (Tokens.BREAK(yypos,yypos+5));
<INITIAL>of             => (Tokens.OF(yypos,yypos+2));
<INITIAL>end            => (Tokens.END(yypos,yypos+3));
<INITIAL>in             => (Tokens.IN(yypos,yypos+2));
<INITIAL>nil            => (Tokens.NIL(yypos,yypos+3));
<INITIAL>let            => (Tokens.LET(yypos,yypos+3));
<INITIAL>do             => (Tokens.DO(yypos,yypos+2));
<INITIAL>to             => (Tokens.TO(yypos,yypos+2));
<INITIAL>for            => (Tokens.FOR(yypos,yypos+3));
<INITIAL>while          => (Tokens.WHILE(yypos,yypos+5));
<INITIAL>else           => (Tokens.ELSE(yypos,yypos+4));
<INITIAL>then           => (Tokens.THEN(yypos,yypos+4));
<INITIAL>if             => (Tokens.IF(yypos,yypos+2));
<INITIAL>array          => (Tokens.ARRAY(yypos,yypos+5));

<INITIAL>","            => (Tokens.COMMA(yypos,yypos+1));
<INITIAL>":"            => (Tokens.COLON(yypos,yypos+1));
<INITIAL>";"            => (Tokens.SEMICOLON(yypos,yypos+1));
<INITIAL>"("            => (Tokens.LPAREN(yypos,yypos+1));
<INITIAL>")"            => (Tokens.RPAREN(yypos,yypos+1));
<INITIAL>"["            => (Tokens.LBRACK(yypos,yypos+1));
<INITIAL>"]"            => (Tokens.RBRACK(yypos,yypos+1));
<INITIAL>"{"            => (Tokens.LBRACE(yypos,yypos+1));
<INITIAL>"}"            => (Tokens.RBRACE(yypos,yypos+1));
<INITIAL>"."            => (Tokens.DOT(yypos,yypos+1));
<INITIAL>"+"            => (Tokens.PLUS(yypos,yypos+1));
<INITIAL>"-"            => (Tokens.MINUS(yypos,yypos+1));
<INITIAL>"*"            => (Tokens.TIMES(yypos,yypos+1));
<INITIAL>"/"            => (Tokens.DIVIDE(yypos,yypos+1));
<INITIAL>"="            => (Tokens.EQ(yypos,yypos+1));
<INITIAL>"<>"           => (Tokens.NEQ(yypos,yypos+2));
<INITIAL>"<"            => (Tokens.LT(yypos,yypos+1));
<INITIAL>"<="           => (Tokens.LE(yypos,yypos+2));
<INITIAL>">"            => (Tokens.GT(yypos,yypos+1));
<INITIAL>">="           => (Tokens.GE(yypos,yypos+2));
<INITIAL>"&"            => (Tokens.AND(yypos,yypos+1));
<INITIAL>"|"            => (Tokens.OR(yypos,yypos+1));
<INITIAL>":="           => (Tokens.ASSIGN(yypos,yypos+2));

<INITIAL>{digit}+       => (Tokens.INT(valOf(Int.fromString yytext), 
                                     yypos, yypos+size yytext));

<INITIAL>{alpha}({alpha}|{digit}|_)*  => (Tokens.ID(yytext, yypos, 
                                                   yypos+size yytext));

<INITIAL>\"            => (YYBEGIN STRING; 
                          stringStart := yypos;
                          stringBuffer := "";
                          inString := true;
                          continue());
<STRING>\"             => (YYBEGIN INITIAL;
                          inString := false;
                          Tokens.STRING(!stringBuffer, !stringStart, yypos+1));
<STRING>\\n            => (stringBuffer := !stringBuffer ^ "\n"; continue());
<STRING>\\t            => (stringBuffer := !stringBuffer ^ "\t"; continue());
<STRING>\\             => (stringBuffer := !stringBuffer ^ "\\"; continue());
<STRING>\\\"           => (stringBuffer := !stringBuffer ^ "\""; continue());
<STRING>[^\\"]+        => (stringBuffer := !stringBuffer ^ yytext; continue());

.                      => (ErrorMsg.error yypos ("Illegal character " ^ yytext); 
                          continue());
