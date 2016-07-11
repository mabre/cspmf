:- dynamic parserVersionNum/1, parserVersionStr/1, parseResult/5.
:- dynamic module/4.
'parserVersionStr'('0.6.1.1').
'parseResult'('ok','',0,0,0).
:- dynamic channel/2, bindval/3, agent/3.
:- dynamic agent_curry/3, symbol/4.
:- dynamic dataTypeDef/2, subTypeDef/2, nameType/2.
:- dynamic cspTransparent/1.
:- dynamic cspPrint/1.
:- dynamic pragma/1.
:- dynamic comment/2.
:- dynamic assertBool/1, assertRef/5, assertTauPrio/6.
:- dynamic assertModelCheckExt/4, assertModelCheck/3.
:- dynamic assertLtl/4, assertCtl/4.
'parserVersionNum'([0,11,0,1]).
'parserVersionStr'('CSPM-Frontent-0.11.0.1').
'dataTypeDef'('FRUIT',['constructor'('apples'),'constructor'('oranges')]).
'comment'('lineComment'('-- Simple demonstration of FDR2'),'src_position'(1,1,0,31)).
'symbol'('FRUIT','FRUIT','src_span'(2,10,2,15,41,5),'Datatype').
'symbol'('apples','apples','src_span'(2,18,2,24,49,6),'Constructor of Datatype').
'symbol'('oranges','oranges','src_span'(2,27,2,34,58,7),'Constructor of Datatype').