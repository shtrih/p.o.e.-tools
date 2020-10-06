#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Hitagi

 Script Function:
    Check prices of Prophecies and save results to a file
#ce ----------------------------------------------------------------------------
#pragma compile(Console, true)
#pragma compile(x64, true)
#pragma compile(Icon, "ProphecyOrbRed.ico")
#pragma compile(Out, "build/StashScanProphPrices.exe")

#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <Crypt.au3>
#include <File.au3>

#include "include/Stash.au3"
#include "include/StashQuad.au3"
#include "include/Log_.au3"
#include "include/NinjaAPIProphecies.au3"

HotKeySet("^i", "Start")
HotKeySet("^o", "Stop")

Global $hWnd
Global $isStarted = False

Main()

Func Main()
   $hWnd = WinGetHandle("Path of Exile")
   ;$hWnd = WinGetHandle("XnView")

   If @error Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
     Exit
   EndIf

   Log_(@ScriptName & ' is ready. Press Ctrl+I to start or Ctrl+O to pause!')

   Local $aStash = False

   While True
      Sleep(100)
      WinWaitActive($hWnd)

      If $isStarted Then
         InitStashSettings()
         If Not IsStorageVisible() Then
            InitStashQuadSettings()
            If Not IsStorageVisible() Then
               Stop('No stash visible')
               ContinueLoop
            EndIf
         EndIf

         $aStash = StorageScanItemsInfo($COLOR_EMPTY, $COLOR_EMPTY_SHADE, $isStarted)
         Beep(100, 100)

         ;_ArrayDisplay($aStash)

         If Not $isStarted Then
            ContinueLoop
         EndIf

         $oDictPrices = FetchPropheciesPrices()
         Local $aResult[1][6] = [['Name', 'Title', 'Cell', 'Chaos', 'Exalted', 'Hash']]

         For $i = 0 To UBound($aStash) - 1
            If $aStash[$i][2] Then
               $info = SplitProphecyInfo($aStash[$i][2])
               If @error Then
                  Logv('Error parsing item info. Skipping...', $aStash[$i][0] & 'x' & $aStash[$i][1], $aStash[$i][2])
                  ContinueLoop
               EndIf

               $name = $info[0]
               $text = $info[1]

               $sHash = String(_Crypt_HashData($name & $text, $CALG_MD5))

               $aItemPrice = $oDictPrices.item($sHash)
               Local $iChaos, $iEx
               If IsArray($aItemPrice) Then
                  $iChaos = $aItemPrice[0]
                  $iEx = $aItemPrice[1]
               Else
                  Logv('Error getting price', VarGetType($aItemPrice), $aItemPrice, $name & $text, $sHash)
               EndIf

               Local $aResultSub[1][6] = [[ _
                  $name, _
                  $text, _
                  $aStash[$i][0] & 'x' & $aStash[$i][1], _
                  $iChaos, _
                  $iEx, _
                  $sHash _
               ]]

               _ArrayAdd($aResult, $aResultSub)
               If @error Then
                  Log_('Error: ' & @error)
               EndIf
            EndIf
         Next
         Beep(100, 100)
         ;_ArrayDisplay($aResult, "Ценность пророчеств", Default,Default,Default, "Название|Описание|Позиция в стеше|Цена (хаос)|Цена (екзоль)|Хеш")

         _FileWriteFromArray(@ScriptFullPath & '.tsv', $aResult, Default, Default, Chr(9)); Tab
         If @error Then
            Logv('Error write file: ', @error)
         EndIf

         Stop()
         ;ExitLoop
      EndIf
   WEnd
EndFunc

Func SplitProphecyInfo($sItemInfo)
   ;Rarity: Normal
   ;Erased from Memory
   ;--------
   ;A foe feared for an aeon falls and is scoured from the pages of history.
   ;--------
   ;You will slay a very powerful foe and it will drop an Orb of Scouring.
   ;--------
   ;Right-click to add this prophecy to your character.
   $info = StringSplit($sItemInfo, @LF)
   $iSize = UBound($info)

   If @error Or $iSize < 8 Then
      Return SetError(1, 0, '')
   EndIf

   Local $result[2] = [StringRegExpReplace($info[2], '(\r\n|\n|\x0b|\f|\r|\x85)', ''), StringRegExpReplace($info[6], '((\r\n|\n|\x0b|\f|\r|\x85)|\s+$)', '')]

   Return $result
EndFunc

Func Start($state = True)
   $state = IsDeclared('state') ? $state : True ; Because HotKeySet ignore default values of arguments too!

   $inventoryNeedRescan = True
   $isStarted = $state
   Log_('Started: ' & $isStarted)

   Beep($isStarted ? 250 : 200, 250)
EndFunc

Func Stop($reason = '')
   $reason = IsDeclared('reason') ? $reason : 'User command' ; Because HotKeySet ignore default values of arguments too!

   If $reason Then Log_($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc
