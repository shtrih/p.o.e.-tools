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
#include <StringConstants.au3>
#include <Array.au3>
#include <Crypt.au3>
#include <File.au3>
#include <Date.au3>

#include "include/Stash.au3"
#include "include/StashQuad.au3"
#include "include/Log_.au3"
#include "include/NinjaAPIProphecies.au3"
#include "include/CSVPrefilledPrices.au3"
#include "include/CSV.au3"

HotKeySet("^i", "Start")
HotKeySet("^o", "Stop")

Global $hWnd
Global $isStarted = False

; From FileClose() DOCS: Upon termination, AutoIt automatically closes any files it opened, but calling FileClose() is still a good idea.
; Yep, it closes automatically. So, don't care of it.
Global $g_hCsvHwnd

Main()

Func Main()
   $hWnd = WinGetHandle("Path of " & 'E' & 'x' & 'i' & 'l' & 'e')
   ;$hWnd = WinGetHandle("XnView")

   If @error Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
     Exit
   EndIf

   $pos = WinGetPos($hWnd)
   If @error Then
      MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the $windowHeight")
      Exit
   EndIf

   Global $g_iWindowOffsetLeft = $pos[0]
   Global $g_iWindowOffsetTop = $pos[1]
   Global $g_iWindowWidth = $pos[2]
   Global $g_iWindowHeight = $pos[3]

   Log_(@ScriptName & ' is ready. Press Ctrl+I to start or Ctrl+O to pause!')

   $oDictPrices = FetchPropheciesPrices()
   ;CsvDumpProphPrices(@ScriptDir & '\ProphPrices\_prefilled-prices.tsv', $oDictPrices)
   $oDictPrefilledPrices = GetPrefilledPricesDict(@ScriptDir & '\ProphPrices\_prefilled-prices.tsv')

   ;CsvClear(GetCsvPath())
   $sCsvPath = GetCsvPath()
   $bCsvHeaderAdded = False

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
      Local $aResult[0][6]

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
                  Local $fChaos = '-', $fEx = '-'
                  If IsArray($aItemPrice) Then
                     $fChaos = $aItemPrice[0]
                     $fEx = $aItemPrice[1]
                  Else
                     Logv('Error getting price', VarGetType($aItemPrice), $aItemPrice, $name & $text, $sHash)
                  EndIf

                  $sPrefilledPrice = $oDictPrefilledPrices.item($sHash)
                  $fActualPrice = ApplyPrefilledPrice($sPrefilledPrice, $fChaos)

                  If IsNumber($fActualPrice) Then
                     Log_('Set item price')
                     ItemSetPrice($fActualPrice, $sNote, $x, $iSnakeY)
                  EndIf

                  Local $aResultSub[1][6] = [[ _
                     $name, _
                     $text, _
                     $x & 'x' & $iSnakeY, _
                     Round($fChaos, 1), _
                     $fEx, _
                     $sHash _
                  ]]

                  _ArrayAdd($aResult, $aResultSub)
                  If @error Then
                     LogE('Error: ' & @error)
                  EndIf
               EndIf
            EndIf
         Next
      Next

      Beep(100, 100)
      ;_ArrayDisplay($aResult, "Ценность пророчеств", Default,Default,Default, "Название|Описание|Позиция в стеше|Цена (хаос)|Цена (екзоль)|Хеш")

      ; Not append if user interrupted or error occured
      If $isStarted Then
         Log_('Appending CSV...')

         Local $aHeader[0][6]
         If Not $bCsvHeaderAdded Then
             Local $aHeader[1][6] = [['Name', 'Title', 'Cell', 'Chaos', 'Exalted', 'Hash']]
             $bCsvHeaderAdded = True
         EndIf

         CsvAppend($aResult, $aHeader, $sCsvPath, $g_hCsvHwnd)
      EndIf

      Stop()
      ;ExitLoop
   WEnd
EndFunc

Func Start($state = True)
   $state = IsDeclared('state') ? $state : True ; Because HotKeySet ignore default values of arguments too!

   Beep($isStarted ? 250 : 200, 250)
   If $state Then
      ; Move out cursor to neutral zone
      MouseMove($g_iWindowWidth / 2 + $g_iWindowOffsetLeft, $g_iWindowHeight / 2 + $g_iWindowOffsetTop)
      Sleep(2000)
   EndIf

   $inventoryNeedRescan = True
   $isStarted = $state
   Log_('Started: ' & $isStarted)
EndFunc

Func Stop($reason = '')
   $reason = IsDeclared('reason') ? $reason : 'User interrupt' ; Because HotKeySet ignore default values of arguments too!

   If $reason Then LogE($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc

Func ItemSetPrice($fPrice, $sNote, $cellX, $cellY)
   $sNewNote = '~b/o ' & Round($fPrice, 1) & ' chaos'

   If $sNote = $sNewNote Then
      Log_('Skip SetPrice', $LOG_LEVEL_DEBUG)
      Return
   EndIf

   MouseClick($MOUSE_CLICK_RIGHT)

   If $sNote Then
      Log_('Rewrite exist price', $LOG_LEVEL_DEBUG)

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

Func GetCsvPath()
   Return @ScriptDir & '\ProphPrices\prices-' & StringFormat('%s-%s-%s_%s-%s.tsv', @YEAR, @MON, @MDAY, @HOUR, @MIN)
EndFunc
