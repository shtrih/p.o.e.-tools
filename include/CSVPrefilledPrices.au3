#include-once

#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <File.au3>

#include "Log_.au3"

Func CsvRead($sFilePath)
   Local $vResult[0]

   _FileReadToArray($sFilePath, $vResult, $FRTA_NOCOUNT, @TAB)
   If @error Then
      Local $aErrorDesc[5]
      $aErrorDesc[1] = 'Error opening specified file'
      $aErrorDesc[2] = 'Unable to split the file'
      $aErrorDesc[3] = 'File lines have different numbers of fields (only if $FRTA_INTARRAYS flag not set)'
      $aErrorDesc[4] = 'No delimiters found (only if $FRTA_INTARRAYS flag not set)'

      LogE(StringFormat('Error CsvRead(%s): %s', $sFilePath, $aErrorDesc[@error]))
   EndIf

   Return $vResult
EndFunc

; name[0], desc[1], chaos[2], is_deleted[3], hash[4]
Func GetPrefilledPricesDict($sFilePath)
   $aList = CsvRead($sFilePath)

   $oDict = ObjCreate("Scripting.Dictionary")
   For $i = 0 To Ubound($aList) - 1
      If Not $aList[$i][3] Then
         $oDict.add($aList[$i][4], $aList[$i][2])
      EndIf
   Next

   Return $oDict
EndFunc

; return Array[2] or 0
Func ParsePrefilledPrice($sPrefilledPrice)
   $aMatches = StringRegExp($sPrefilledPrice, '^([+x]?)\s*(\d+[.]?\d*)$', $STR_REGEXPARRAYMATCH)
   If @error = 2 Then
      LogE('ParsePrice: ' & @error)
   EndIf

   Return $aMatches
EndFunc

Func ApplyPrefilledPrice($sPrefilledPrice, $fPrice)
   $fResult = $fPrice

   $aPrefPrice = ParsePrefilledPrice($sPrefilledPrice)
   If Not IsArray($aPrefPrice) Then
      Return $fResult
   EndIf

   If $aPrefPrice[0] = 'x' Then
      $fResult *= $aPrefPrice[1]
   ElseIf $aPrefPrice[0] = '+' Then
      $fResult += $aPrefPrice[1]
   ElseIf $aPrefPrice[0] = '' Then
      $fResult = Number($aPrefPrice[1], $NUMBER_DOUBLE)
   EndIf

   Return $fResult
EndFunc
