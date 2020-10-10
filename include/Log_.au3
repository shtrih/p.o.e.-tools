#include-once

#include <Date.au3>
#include "_PrintArrayConsole.au3"

Global Const $LOG_LEVEL_INFO = 'info'
Global Const $LOG_LEVEL_DEBUG = 'debug'
Global Const $LOG_LEVEL_ERROR = 'error'

If Not IsDeclared('DEBUG') Then
   Global Const $DEBUG = $CmdLine[0] ? $CmdLine[1] = 'debug' : False
EndIf

Func Log_($data, $logLevel = $LOG_LEVEL_INFO)
   If $logLevel = $LOG_LEVEL_DEBUG And Not $DEBUG Then
      Return
   EndIf

   $sLogFunction = 'ConsoleWrite'
   If $logLevel = $LOG_LEVEL_ERROR Then
      $sLogFunction = 'ConsoleWriteError'
   EndIf

   Call($sLogFunction, _Now() & ' - ' & '[' & $logLevel & '] ' & $data & @CRLF)

   If IsArray($data) Then
      _PrintArrayConsole($data)
      If @error Then
         Call($sLogFunction, 'Array[' & UBound($data) & ']' & @CRLF)
      EndIf
   EndIf
EndFunc

Func Logv($p1, $p2 = '', $p3 = '', $p4 = '', $p5 = '', $p6 = '', $p7 = '', $p8 = '', $p9 = '', $p10 = '')
   $sValue = ''
   For $i = 1 To @NumParams
      $v = Eval("p" & $i)
      If IsArray($v) Then $v = 'Array[' & UBound($v) & ']'
      If Not ($v == '') And $i <> 1 Then $sValue &= ", "
      $sValue &= $v
   Next

   Log_($sValue)
EndFunc

Func LogE($data)
   Log_($data, $LOG_LEVEL_ERROR)
EndFunc
