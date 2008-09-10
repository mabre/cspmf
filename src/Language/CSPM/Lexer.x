{
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
module Language.CSPM.Lexer 
(
scanner
,Lexeme(..)
,LexemeClass(..),AlexPosn(..),LexError(..)
,alexLine,alexCol,alexPos
,pprintAlexPosn
,tokenSentinel
,alexMove
,showToken
)
where
import Language.CSPM.Token
import Language.CSPM.AlexWrapper
}

$whitechar = [\ \t\n\r\f\v]
$special   = [\(\)\,\;\[\]\`\{\}]

$ascdigit  = 0-9
$unidigit  = [] -- TODO
$digit     = [$ascdigit $unidigit]

$ascsymbol = [\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\-\~]
$unisymbol = [] -- TODO
$symbol    = [$ascsymbol $unisymbol] # [$special \_\:\"\']

--$large     = [A-Z \xc0-\xd6 \xd8-\xde]
--$small     = [a-z \xdf-\xf6 \xf8-\xff \_]
$large     = [A-Z]
$small     = [a-z]
$alpha     = [$small $large]

$graphic   = [$small $large $symbol $digit $special \:\"\']

$octit	   = 0-7
$hexit     = [0-9 A-F a-f]
$idchar    = [$alpha $digit \' \_]
$symchar   = [$symbol \:]
$nl        = [\n\r]

@cspid = 
        channel|datatype|nametype|subtype
        | assert |pragma|transparent|external|print
        | STOP|SKIP|true|false|if|then|else|let|within
        | not | and | or | Int | Bool
        | Events

@cspbi =
  CHAOS
  | union | inter | diff | Union | Inter | member | card
  | empty | set | Set | Seq
  | null | head | tail | concat | elem | length

@cspsym = 
     "(" | ")" | "<" | ">" | "[" | "]" | "[[" | "]]" | "[|" | "|]"
     | "{" | "}" | "{|" | "|}"
     | "[>" | "[]" | "|~|" | "\" | "|" | "||" | "|||"
     | "->" | "<-" | "<->" 
     | ":" | "/\" | "&" | ";" | ".."
     | "." | "?" | "!" | "@" | "," | "=" | "@@"
     | "==" | ">=" | "<=" | "!="
     | "+" | "-" | "*" | "/" | "%" | "#" | "^"
     | "_"
     | "[FD=" | "[F=" | "[T="

@ident = $alpha $idchar*

@varid  = $small $idchar*
@conid  = $large $idchar*
@varsym = $symbol $symchar*
@consym = \: $symchar*

@decimal     = $digit+
@octal       = $octit+
@hexadecimal = $hexit+
@exponent    = [eE] [\-\+] @decimal

$cntrl   = [$large \@\[\\\]\^\_]
@ascii   = \^ $cntrl | NUL | SOH | STX | ETX | EOT | ENQ | ACK
	 | BEL | BS | HT | LF | VT | FF | CR | SO | SI | DLE
	 | DC1 | DC2 | DC3 | DC4 | NAK | SYN | ETB | CAN | EM
	 | SUB | ESC | FS | GS | RS | US | SP | DEL
$charesc = [abfnrtv\\\"\'\&]
@escape  = \\ ($charesc | @ascii | @decimal | o @octal | x @hexadecimal)
@gap     = \\ $whitechar+ \\
@string  = $graphic # [\"\\] | " " | @escape | @gap

@assertExts = $whitechar+ "[FD]" | $whitechar+ "[F]"
@assertCore = "deterministic" @assertExts?
            | "livelock" $whitechar+ "free" @assertExts?
            | "deadlock" $whitechar+ "free" @assertExts?
            | "divergence" $whitechar+ "free" @assertExts?

csp :-

<0> $white+			{ skip }
<0> "--".*			{ mkL LLComment }
"{-"				{ block_comment }
--<0> "include"\-*[^$symbol].*    { mkL LCSPFDR }


-- Fixme : tread this properly
<0> ":[" $whitechar* @assertCore $whitechar* "]"    { mkL LCSPFDR }

<0> "include"                   { mkL LInclude }

<0> @cspid			{ mkL LCspId }

<0> @cspbi			{ mkL LCspBI }

<0> @cspsym                     { mkL LCspsym} -- ambiguity for wildcardpattern _

<0> @ident                      { mkL LIdent}  -- ambiguity for wildcardpattern _

<0> @decimal 
  | 0[oO] @octal
  | 0[xX] @hexadecimal		{ mkL LInteger }


-- <0> \' ($graphic # [\'\\] | " " | @escape) \' { mkL LChar }

   <0> \" @string* \"		{ mkL LString }

{
alexMonadScan = do
  inp <- alexGetInput
  sc <- alexGetStartCode
  case alexScan inp sc of
    AlexEOF -> alexEOF
    AlexError (pos,chr,h:rest)
         -> lexError $ "lexical error"
    AlexSkip  inp' len -> do
	alexSetInput inp'
	alexMonadScan
    AlexToken inp' len action -> do
	alexSetInput inp'
	action inp len

scanner str = runAlex str $ do
  let loop i = do tok@(L _ _ _ cl _) <- alexMonadScan; 
		  if cl == LEOF
			then return i
			else do loop $! (tok:i)
  loop []

-- just ignore this token and scan another one
-- skip :: AlexAction result
skip input len = alexMonadScan

-- ignore this token, but set the start code to a new value
-- begin :: Int -> AlexAction result
begin code input len = do alexSetStartCode code; alexMonadScan

}
