#include <Inet.au3>
#include <StringConstants.au3>
#include "json/json.au3" ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include "Log_.au3"
#include <Crypt.au3>

Func FetchApi($test = False)
   Const $URL = "https://"&'po'&'e.n'&'in'&"ja/api/data/itemoverview?league=Heist&type=Prophecy&language=en"

   If $test Then
      Local $result = FileRead(@ScriptDir & "\fixtures\prophecies-ninja-api.json")
   Else
      Local $result = BinaryToString(InetRead($URL), $SB_UTF8)
   EndIf

   Return $result
EndFunc

Func FetchPropheciesPrices()
   $data = FetchApi($DEBUG)

   Local $oMyError = ObjEvent("AutoIt.Error", "ErrFunc")
   $oDict = ObjCreate("Scripting.Dictionary")
   ;$oDict.CompareMode = 1; "Text Mode"

   $object = json_decode($data)
   If @error Then
      Log_('Json decode error: ' & @error)
   EndIf

   ;Json_Dump($data)

   Local $i = 0
   While 1
      $name = json_get($object, '.lines[' & $i & '].name')
      If @error Then
         ;Log_('error ' & @error)
         ExitLoop
      EndIf
      $chaosValue = json_get($object, '.lines[' & $i & '].chaosValue')
      $exaltedValue = json_get($object, '.lines[' & $i & '].exaltedValue')
      $prophecyText = json_get($object, '.lines[' & $i & '].prophecyText')

      Local $arr[4] = [$chaosValue, $exaltedValue, $name, $prophecyText]
      $sHash = String(_Crypt_HashData($name & $prophecyText, $CALG_MD5))

      $oDict.add($sHash, $arr)

      ;Logv($sHash, $name & $prophecyText)
      ;Log_(StringFormat('%s) %s (%schaos, %sexalted)', $i+1, $name, $chaosValue, $exaltedValue))

      $i += 1
   WEnd

   Return $oDict
EndFunc

Func CsvDumpProphPrices($sFilePath, $oDict)
   Local $aResult[1][5] = [['Name', 'Title', 'Chaos', 'Is Deleted', 'Hash']]

   For $sKey in $oDict.keys
      $aItem = $oDict.Item($sKey)
      Local $aResultSub[1][5] = [[$aItem[2], $aItem[3], $aItem[0], '', $sKey]]

      _ArrayAdd($aResult, $aResultSub)
      If @error Then
         Local $aErrorDesc[7]
         $aErrorDesc[1] = '$aArray is not an array'
         $aErrorDesc[2] = '$aArray is not a 1 or 2 dimensional array'
         $aErrorDesc[3] = '$vValue has too many columns to fit into $aArray'
         $aErrorDesc[4] = '$iStart outside array bounds (2D only)'
         $aErrorDesc[5] = 'Number of dimensions for $avArray and $vValue arrays do not match'

         $sError = $aErrorDesc[@error]
         LogE(StringFormat('Error CsvDumpProphPrices(%s): %s', $sFilePath, $sError))

         Return False
      EndIf
   Next

   _FileWriteFromArray($sFilePath, $aResult, Default, Default, @TAB)
   If @error Then
      Local $aErrorDesc[6]
      $aErrorDesc[1] = 'Error opening specified file'
      $aErrorDesc[2] = '$aArray is not an array'
      $aErrorDesc[3] = 'Error writing to file'
      $aErrorDesc[4] = '$aArray is not a 1D or 2D array'
      $aErrorDesc[5] = 'Start index is greater than the $iUbound parameter'

      $sError = $aErrorDesc[@error]
      LogE(StringFormat('Error CsvDumpProphPrices(%s): %s', $sFilePath, $sError))

      Return False
   EndIf

   Return True
EndFunc

Func ErrFunc($oError)
   Logv("We intercepted a COM Error !", _
      "Number: 0x" & Hex($oError.number, 8) & @CRLF & _
      "Description: " & $oError.windescription & _
      "At line: " & $oError.scriptline)
EndFunc
