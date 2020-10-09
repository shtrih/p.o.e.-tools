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

   $oDictPrices = FetchPropheciesPrices()

   While True
      Sleep(100)
      WinWaitActive($hWnd)

      If Not $isStarted Then
         ContinueLoop
      EndIf

      InitStashSettings()
      If Not IsStorageVisible() Then
         InitStashQuadSettings()
         If Not IsStorageVisible() Then
            Stop('No stash visible')
            ContinueLoop
         EndIf
      EndIf

      Local $aStash[0][3]
      Local $aResult[1][6] = [['Name', 'Title', 'Cell', 'Chaos', 'Exalted', 'Hash']]

      $isInverted = False
      $iVertMax = $g_vertCount - 1

      For $x = 0 to ($g_horCount - 1)
         $isInverted = Mod($x, 2) = 0 ? False : True

         For $y = 0 to $iVertMax
            If Not $isStarted Then
               ExitLoop 2
            EndIf

            $iSnakeY = $isInverted ? $iVertMax - $y : $y
            CellMove($x, $iSnakeY)

            If Not CellCheckIsEmpty($x, $iSnakeY) Then
               Local $resultSub[1][3] = [[$x, $iSnakeY, GetItemInfo()]]
               _ArrayAdd($aStash, $resultSub)

               If $resultSub[0][2] Then
                  $info = SplitProphecyInfo($resultSub[0][2])
                  If @error Then
                     Logv('Error parsing item info. Skipping...', $x & 'x' & $iSnakeY, $resultSub[0][2])
                     ContinueLoop
                  EndIf

                  $name = $info[0]
                  $text = $info[1]
                  $sNote = $info[2]

                  $sHash = String(_Crypt_HashData($name & $text, $CALG_MD5))

                  $aItemPrice = $oDictPrices.item($sHash)
                  Local $iChaos = '-', $iEx = '-'
                  If IsArray($aItemPrice) Then
                     $iChaos = $aItemPrice[0]
                     $iEx = $aItemPrice[1]

                     ItemSetPrice($iChaos, $sNote, $x, $iSnakeY)
                  Else
                     Logv('Error getting price', VarGetType($aItemPrice), $aItemPrice, $name & $text, $sHash)
                  EndIf

                  Local $aResultSub[1][6] = [[ _
                     $name, _
                     $text, _
                     $x & 'x' & $iSnakeY, _
                     Round($iChaos, 1), _
                     $iEx, _
                     $sHash _
                  ]]

                  _ArrayAdd($aResult, $aResultSub)
                  If @error Then
                     Log_('Error: ' & @error)
                  EndIf
               EndIf
            EndIf
         Next
      Next

      Beep(100, 100)
      ;_ArrayDisplay($aResult, "Ценность пророчеств", Default,Default,Default, "Название|Описание|Позиция в стеше|Цена (хаос)|Цена (екзоль)|Хеш")

      _FileWriteFromArray(@ScriptFullPath & '.tsv', $aResult, Default, Default, Chr(9)); Tab
      If @error Then
         Logv('Error write file: ', @error)
      EndIf

      Stop()
      ;ExitLoop
   WEnd
EndFunc

Func SplitProphecyInfo($sItemInfo)
   ;Rarity: Normal
   ;The Karui Rebellion
   ;--------
   ;Thaumaturgy and faith clash among giant ruins; a recreation of a long-gone rebellion.
   ;--------
   ;You will defeat the Gemling Legionnaires while holding Karui Ward.
   ;--------
   ;Right-click to add this prophecy to your character.
   ;--------
   ;Note: ~b/o 1 chaos
   $info = StringSplit($sItemInfo, @LF)
   If @error Then
      Return SetError(1, 0, '')
   EndIf

   $iSize = UBound($info)
   If $iSize < 8 Then
      Return SetError(1, 0, '')
   EndIf

   $sNote = ''
   If $iSize >= 11 And StringRegExp($info[10], 'Note:') Then
      $sNote = StringRegExpReplace($info[10], '(Note:\s|\r\n|\n|\x0b|\f|\r|\x85)', '')
   EndIf

   Local $result[3] = [ _
      StringRegExpReplace($info[2], '(\r\n|\n|\x0b|\f|\r|\x85)', ''), _
      StringRegExpReplace($info[6], '((\r\n|\n|\x0b|\f|\r|\x85)|\s+$)', ''), _
      $sNote _
   ]

   Return $result
EndFunc

Func Start($state = True)
   $state = IsDeclared('state') ? $state : True ; Because HotKeySet ignore default values of arguments too!

   Beep($isStarted ? 250 : 200, 250)
   Sleep(2000)

   $inventoryNeedRescan = True
   $isStarted = $state
   Log_('Started: ' & $isStarted)
EndFunc

Func Stop($reason = '')
   $reason = IsDeclared('reason') ? $reason : 'User command' ; Because HotKeySet ignore default values of arguments too!

   If $reason Then Log_($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc

Func ItemSetPrice($fPrice, $sNote, $cellX, $cellY)
   $sNewNote = '~b/o ' & Round($fPrice, 1) & ' chaos'

   If $sNote And $sNote = $sNewNote Then
      Return
   EndIf

   MouseClick($MOUSE_CLICK_RIGHT)

   If $sNote Then
      ; по х сдвигаемся на 3 ячейки влево, если больше 3 столбца
      $cellY += 1 ; вниз от текущей ячейки
      $pos = CellNum2PixelPos($cellX, $cellY)
      $priceSelectorOffsetX = $pos[0] > 175 ? -150 : 0 ; позиция селекта
      $priceSelectorOffsetY = 60 ; позиция селекта
      $posX = $pos[0] + $priceSelectorOffsetX
      $posY = $pos[1] + $priceSelectorOffsetY

      MouseClick($MOUSE_CLICK_LEFT, $posX, $posY)

      Send('{UP}')
      Send('{UP}')
      Send('{UP}')
      Send('{ENTER}')

      $textFieldOffsetX = 200
      MouseClick($MOUSE_CLICK_LEFT, $posX + $textFieldOffsetX, $posY)

      Send('^a')
   EndIf

   Sleep(100)
   Send($sNewNote, 1)
   Sleep(100)
   Send('{ENTER}')
EndFunc
