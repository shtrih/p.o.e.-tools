#include <Inet.au3>
#include <StringConstants.au3>
#include "json/json.au3" ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include "Log_.au3"
#include <Crypt.au3>

Func FetchPoeNinjaApi($test = False)
   Const $URL = "https://poe.ninja/api/data/itemoverview?league=Heist&type=Prophecy&language=en"

   If $test Then
      Local $result = FileRead(@ScriptDir & "\fixtures\prophecies-poeninja-api.json")
   Else
      Local $result = BinaryToString(InetRead($URL), $SB_UTF8)
   EndIf

   Return $result
EndFunc

Func FetchPropheciesPrices()
   $data = FetchPoeNinjaApi()

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

      Local $arr[3] = [$chaosValue, $exaltedValue, $name]
      $sHash = String(_Crypt_HashData($name & $prophecyText, $CALG_MD5))

      $oDict.add($sHash, $arr)

      ;Logv($sHash, $name & $prophecyText)
      ;Log_(StringFormat('%s) %s (%schaos, %sexalted)', $i+1, $name, $chaosValue, $exaltedValue))

      $i += 1
   WEnd

   Return $oDict
EndFunc

Func ErrFunc($oError)
   Logv("We intercepted a COM Error !", _
      "Number: 0x" & Hex($oError.number, 8) & @CRLF & _
      "Description: " & $oError.windescription & _
      "At line: " & $oError.scriptline)
EndFunc
