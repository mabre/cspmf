{
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_GHC -cpp #-}

module Language.CSPM.Lexer 
(
scanner
)
where
import Language.CSPM.Token
import Language.CSPM.TokenClasses
import Language.CSPM.AlexWrapper
}

$whitechar = [\ \t\r\n\f\v]
$whitechar' = [\ \t\r\f\v]
$digit     = 0-9

$symbol = [\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\-\~\(\)\,\;\[\]\`\{\}\_\:\']
$symbol1 = [\_\']
--$large     = [A-Z \xc0-\xd6 \xd8-\xde]
--$small     = [a-z \xdf-\xf6 \xf8-\xff \_]
$large     = [A-Z]
$small     = [a-z]
$alpha     = [$small $large]

$graphic   = [$small $large $symbol $digit]
$graphic1  = [$small $large $symbol1 $digit]
$octit     = 0-7
$hexit     = [0-9 A-F a-f]
$idchar    = [$alpha $digit \' \_]

@ident = $alpha $idchar*

@decimal     = $digit+
@octal       = $octit+
@hexadecimal = $hexit+

@string  = $graphic # [\"\\] | " " $whitechar
@str = $graphic # [ \[ \] ]  
@w = $whitechar*
$nl = [\n]

csp :-

-- CSP-M Keywords
<0> "channel"     { mkL T_channel  }
<0> "datatype"    { mkL T_datatype }
<0> "nametype"    { mkL T_nametype }
<0> "subtype"     { mkL T_subtype }
<0> "assert"      { mkL T_assert }
<0> "pragma"      { mkL T_pragma }
<0> "transparent" { mkL T_transparent }
<0> "external"    { mkL T_external }
<0> "print"       { mkL T_print }
<0> "if"          { mkL T_if }
<0> "then"        { mkL T_then }
<0> "else"        { mkL T_else }
<0> "let"         { mkL T_let }
<0> "within"      { mkL T_within }

-- CSP-M builtIns

<0> "STOP"    { mkL T_STOP }
<0> "SKIP"    { mkL T_SKIP }
<0> "true"    { mkL T_true }
<0> "false"    { mkL T_false }
<0> "not"    { mkL T_not }
<0> "and"    { mkL T_and }
<0> "or"    { mkL T_or }
<0> "Int"    { mkL T_Int }
<0> "Bool"    { mkL T_Bool }
<0> "Proc"    { mkL T_Proc }
<0> "Events"    { mkL T_Events }
<0> "CHAOS"    { mkL T_CHAOS }
<0> "union"    { mkL T_union }
<0> "inter"    { mkL T_inter }
<0> "diff"    { mkL T_diff }
<0> "Union"    { mkL T_Union }
<0> "Inter"    { mkL T_Inter }
<0> "member"    { mkL T_member }
<0> "card"    { mkL T_card }
<0> "empty"    { mkL T_empty }
<0> "set"    { mkL T_set }
<0> "Set"    { mkL T_Set }
<0> "Seq"    { mkL T_Seq }
<0> "null"    { mkL T_null }
<0> "head"    { mkL T_head }
<0> "tail"    { mkL T_tail }
<0> "concat"    { mkL T_concat }
<0> "elem"    { mkL T_elem }
<0> "length"    { mkL T_length }

-- assetion Lists refinement operators
<0> "[=" { mkL T_Refine }
<0> "[T=" { mkL T_trace }
<0> "[F=" { mkL T_failure }
<0> "[FD=" { mkL T_failureDivergence }
<0> "[R=" { mkL T_refusalTesting }
<0> "[RD=" { mkL T_refusalTestingDiv }
<0> "[V=" { mkL T_revivalTesting }
<0> "[VD=" { mkL T_revivalTestingDiv }
<0> "[TP=" { mkL T_tauPriorityOp }
<0> ":[" { begin ref } -- jump to the other lexer specification ref

-- symbols
<0> "^" { mkL T_hat }
<0> "#" { mkL T_hash }
<0> "*" { mkL T_times }
<0> "/" { mkL T_slash }
<0> "%" { mkL T_percent }
<0> "+" { mkL T_plus }
<0> "-" { mkL T_minus }
<0> "==" { mkL T_eq }
<0> "!=" { mkL T_neq }
<0> ">=" { mkL T_ge }
<0> "<=" { mkL T_le }
<0> "<"    { mkL T_lt }
<0> ">" { mkL T_gt }
<0> "&" { mkL T_amp }
<0> ";" { mkL T_semicolon }
<0> "," { mkL T_comma }
<0> "/\" { mkL T_triangle }
<0> "[]" { mkL T_box }
<0> "[>" { mkL T_rhd }
<0> "|>" { mkL T_exp }
<0> "|~|" { mkL T_sqcap }
<0> "|||" { mkL T_interleave }
<0> "\" { mkL T_backslash }
<0> "||" { mkL T_parallel }
<0> "|" { mkL T_mid }
<0> "@" { mkL T_at }
<0> "@@" { mkL T_atat }
<0> "->" { mkL T_rightarrow }
<0> "<-" { mkL T_leftarrow }
<0> "<->" { mkL T_leftrightarrow }
<0> "." { mkL T_dot }
<0> ".." { mkL T_dotdot }
<0> "!" { mkL T_exclamation }
<0> "?" { mkL T_questionmark }
<0> ":" { mkL T_colon }
<0> "(" { mkL T_openParen }
<0> ")" { mkL T_closeParen }
<0> "{" { mkL T_openBrace }
<0> "}" { mkL T_closeBrace }
<0> "[" { mkL T_openBrack }
<0> "]" { mkL T_closeBrack }
<0> "[|" { mkL T_openOxBrack }
<0> "|]" { mkL T_closeOxBrack }
<0> "{|" { mkL T_openPBrace }
<0> "|}" { mkL T_closePBrace }
<0> "_"  { mkL T_underscore }
<0> "="  { mkL T_is }
<0> "[[" { mkL T_openBrackBrack }
<0> "]]" { mkL T_closeBrackBrack }
<0> $nl  { mkL L_Newline}
<0> $whitechar'+ { skip }
<0> "--".* { mkL L_LComment }
"{-"    { block_comment }

-- Fixme : tread this properly


<0> "include"                   { mkL L_Include }

<0> @ident                      { mkL L_Ident}  -- ambiguity for wildcardpattern _

<0> @decimal 
  | 0[oO] @octal
  | 0[xX] @hexadecimal          { mkL L_Integer }


<0> \" @string* \"              { mkL L_String }

<ref> "deadlock"      { mkL T_deadlock  }
<ref> "deterministic" { mkL T_deterministic }
<ref> "livelock"      { mkL T_livelock  }
<ref> "divergence"    { mkL T_livelock  }
<ref> "free"          { mkL T_free      }
<ref> "[FD]"          { mkL T_FD        }
<ref> "[F]"           { mkL T_F         }
<ref> "[T]"           { mkL T_T         }
<ref> "tau"           { mkL T_tau       }
<ref> "priority"      { mkL T_priority  }
<ref> "over"          { mkL T_over      }
<ref> "]:"            { begin 0         }
<ref> "]"             { begin 0         }
<ref> $white+         { skip            }
<ref> @str            { skip            }

{
alexMonadScan = do
  inp <- alexGetInput
  sc <- alexGetStartCode
  case alexScan inp sc of                    -- alexScan is jump to alexGenerated code
    AlexEOF -> alexEOF
    AlexError (pos,chr,h:rest)
         -> lexError $ "lexical error"
    AlexSkip  inp' len -> do
	alexSetInput inp'
	alexMonadScan
    AlexToken inp' len action -> do
	alexSetInput inp'
	action inp len

scanner str = runAlex str $ scannerAcc []
  where
    scannerAcc i = do
      tok <- alexMonadScan; 
      if tokenClass tok == L_EOF
        then return i
        else scannerAcc $! (tok:i)

-- just ignore this token and scan another one
-- skip :: AlexAction result
skip input len = alexMonadScan

-- ignore this token, but set the start code to a new value
-- begin :: Int -> AlexAction result
begin code input len = do alexSetStartCode code; alexMonadScan

}
