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

   Local $aLatestPos[2] = [0, 0]
   Local $aLatestResult
   $bLatestResuming = False

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
      $iHorMax = $g_horCount - 1
      $iVertMax = $g_vertCount - 1

      If ($aLatestPos[0] > 0 Or $aLatestPos[1] > 0) And ($aLatestPos[0] < $iHorMax Or $aLatestPos[1] > 0) Then
         $sPos = StringFormat(' from pos [%s, %s]', $aLatestPos[0], $aLatestPos[1])
         $iResult = MsgBox($MB_OKCANCEL, 'Do you want to resume scanning?', 'Do you want to resume scanning' & $sPos)

         If $iResult = $IDCANCEL Then
            $aLatestPos[0] = 0
            $aLatestPos[1] = 0
            $aLatestResult = null
            Log_('Previous scan data is discarded')
         EndIf

         If $iResult = $IDOK Then
            $bLatestResuming = True
            Log_('Resume scanning' & $sPos)
         EndIf

         Sleep(100)
      EndIf

      For $x = $aLatestPos[0] to $iHorMax
         $isInverted = Mod($x, 2) = 0 ? False : True

         For $y = $aLatestPos[1] to $iVertMax
            If $bLatestResuming Then
               $aLatestPos[1] = 0
               $bLatestResuming = False
            EndIf
            If Not $isStarted Then
               $aLatestPos[0] = $x
               $aLatestPos[1] = $y

               If IsArray($aLatestResult) Then
                  _ArrayConcatenate($aLatestResult, $aResult)
                  If @error Then
                     Local $aErrorDesc[7]
                     $aErrorDesc[1] = '$aArrayTarget is not an array'
                     $aErrorDesc[2] = '$aArraySource is not an array'
                     $aErrorDesc[3] = '$aArrayTarget is not a 1D or 2D array'
                     $aErrorDesc[4] = '$aArrayTarget and $aArraySource 1D/2D mismatch'
                     $aErrorDesc[5] = '$aArrayTarget and $aArraySource column number mismatch (2D only)'
                     $aErrorDesc[6] = '$iStart outside array bounds'

                     $sError = $aErrorDesc[@error]
                     LogE(StringFormat('Error $aResult concat: %s', $sError))
                  EndIf
               Else
                  $aLatestResult = $aResult
               EndIf

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
                     Log_('Set item price', $LOG_LEVEL_DEBUG)
                     ItemSetPrice($fActualPrice, $sNote, $x, $iSnakeY)
                  EndIf

                  Local $aResultSub[1][6] = [[ _
                     $name, _
                     $text, _
                     $x & 'x' & $iSnakeY, _
                     $fActualPrice, _ ; Round($fChaos, 1), _
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

         ;Local $aHeader[0][6]
         ;If Not $bCsvHeaderAdded Then
             Local $aHeader[1][6] = [['Name', 'Title', 'Cell', 'Chaos', 'Exalted', 'Hash']]
         ;    $bCsvHeaderAdded = True
         ;EndIf

         If IsArray($aLatestResult) Then
            _ArrayConcatenate($aResult, $aLatestResult)
            If @error Then
               Local $aErrorDesc[7]
               $aErrorDesc[1] = '$aArrayTarget is not an array'
               $aErrorDesc[2] = '$aArraySource is not an array'
               $aErrorDesc[3] = '$aArrayTarget is not a 1D or 2D array'
               $aErrorDesc[4] = '$aArrayTarget and $aArraySource 1D/2D mismatch'
               $aErrorDesc[5] = '$aArrayTarget and $aArraySource column number mismatch (2D only)'
               $aErrorDesc[6] = '$iStart outside array bounds'

               $sError = $aErrorDesc[@error]
               LogE(StringFormat('Error $aLatestResult concat: %s', $sError))
            EndIf

            $aLatestResult = null
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
