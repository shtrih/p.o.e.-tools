#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Hitagi

 Script Function:
    Seal prophecies and put it into inventory. Works on 1920x1080 fullscreen (or borderless).
#ce ----------------------------------------------------------------------------
#pragma compile(Console, true)
#pragma compile(x64, true)
#pragma compile(Icon, "ProphecyOrbRed.ico")
#pragma compile(Out, "build/AutoCraftProph.exe")

#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>
#include <Misc.au3>
#include <Crypt.au3>

#include "include/Inventory.au3"
#include "include/Stash.au3"
#include "include/StashQuad.au3"
#include "include/Log_.au3"
#include "include/CSVPrefilledPrices.au3"
#include "include/CSV.au3"

HotKeySet("^k", "Start")
HotKeySet("^l", "Stop")

Global $hWnd
Global $g_isStarted = False
Global $g_isRestarted = True
Global $g_oDictNeededList
Global $g_sCsvDeletedPath

; From FileClose() DOCS: Upon termination, AutoIt automatically closes any files it opened, but calling FileClose() is still a good idea.
; Yep, it closes automatically. So, don't care of it.
Global $g_hCsvHwnd

Global Const $PropheciesPositions = [ [320, 256], [168,  315], [458, 315], [132, 480], [492, 480], [224, 640], [408, 640] ]
Global Const $ProphecySeekButtonPositions = [ [298, 770], [365, 787] ]
Global Const $ProphecySealButtonPositions = [ [298, 215], [365, 232], [389, 602], [458, 619] ]

#cs
WaitForStart
Only on Restart. Ask user to point Navali
 No:
   Stop Script
 Yes:
   Monitor LMB and save mouse cursor coordinates on click
Only on Restart. Ask user to point Stash
 No:
   Stop Script
 Yes:
   Monitor LMB and save mouse cursor coordinates on click
Check Prophecy Window is open
 No:
  Try click Navali position according user input
Check Prophecy Window is open
 No:
  Stop Script
Open Inventory if closed
Scan Inventory (for empty space)
If Inventory is full then
 Scan Inventory (for prophecies)
  No prophecies:
   Stop Script (inventory full)
 Try click Stash position according user input
 Check Stash is open
  No:
   Stop Script
 CtrlClick any prophecies to Stash
 If Stash is full:
  Stop Script
 ContinueLoop
Check Prophecy Exists
 Yes:
  Click Seal Button
  Check "not enough coins" dialog
   Yes:
    Stop Script
   No:
    Confirm Prophecy Sealing
    Put item to inventory
    Check if need to destroy item
     Yes:
      Destroy (with confirm)
 No:
  Click Seek Button
  Check "not enough coins" dialog
   Yes:
    Stop Script
   No:
    Move to "Check Prophecy Window is open" step (ContinueLoop)
#ce

Main()

Func Main()
   $hWnd = WinGetHandle("Path of " & 'E' & 'x' & 'i' & 'l' & 'e')
   ;$hWnd = WinGetHandle("XnView")

   If @error Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
     Exit
   EndIf

   Log_(@ScriptName & ' is ready. Open Navali Prophecies dialog and press Ctrl+K to start or Ctrl+L to pause!')

   Local $aInventory[0]

   $g_oDictNeededList = GetPrefilledPricesDict(@ScriptDir & '\ProphPrices\_prefilled-prices.tsv')
   $g_sCsvDeletedPath = GetCsvDeletedPath()
   $bCsvHeaderAdded = False

   While True
      WinWaitActive($hWnd)

      Sleep(100)

      If Not $g_isStarted Then
         ContinueLoop
      EndIf

      If $g_isRestarted Then
         Log_('Request user for Stash and Navali positions...')
         If Not AskUserToPointCharacters() Then
            Stop('The request for Stash and Navali was cancelled.')
            ContinueLoop
         EndIf

         Sleep(200)
      EndIf

      InitInventorySettings()
      If CheckInventoryClosed() Then
      ;If Not IsStorageVisible() Then
         Log_('Opening inventory...')
         Send('{i}')
      EndIf

      If Not UBound($aInventory) Or $g_isRestarted Then
         $g_isRestarted = False
         Log_('Scanning inventory...')

         ; Move cursor out of inventory
         Log_('Move cursor out of inventory (3)')
         MouseMove(Random(650, 1200, 1), Random(400, 800, 1))

         $aInventory = StorageScan($COLOR_EMPTY, $COLOR_EMPTY_SHADE)
      EndIf

      If Not UBound($aInventory) Then
         Log_('Inventory is full. Scanning inventory for Prophecies...')
         $aProphecyInventory = StorageScan($COLOR_PROPHECY, $COLOR_PROPHECY_SHADE)
         If UBound($aProphecyInventory) Then
            Log_('Trying to move Prophecies to Stash...')

            Send('{ESC}')
            Sleep(100)
            Log_('Opening Stash...')
            ClickStash()

            ; Move cursor out of Stash
            Log_('Move cursor out of Stash')
            MouseMove(Random(650, 1200, 1), Random(400, 800, 1))

            InitStashSettings()
            If Not IsStorageVisible() Then
               InitStashQuadSettings()
               If Not IsStorageVisible() Then
                  Stop('No stash visible')
                  ContinueLoop
               EndIf
            EndIf

            InitInventorySettings()
            StorageCtrlClickItem($aProphecyInventory)
            If @error Then
               Stop()
               ContinueLoop
            EndIf

            Send('{ESC}')
            Sleep(100)
         Else
            Stop('Inventory is full.')
            ContinueLoop
         EndIf
      EndIf

      If CheckProphWindowOpen() Then
         Log_('Prophecies window is Open')
      Else
         Log_('Trying to click Navali...')

         ; Move cursor out of inventory
         Log_('Move cursor out of inventory (4)')
         MouseMove(Random(650, 1200, 1), Random(400, 800, 1))

         If Not CheckInventoryClosed() Then
            Send('{ESC}')
            Sleep(100)
         EndIf

         ClickNavali()
         If Not CheckProphWindowOpen() Then
            Stop('Prophecies window is Closed.')
            ContinueLoop
         EndIf
      EndIf

      ; Move cursor out of inventory
      ;Log_('Move cursor out of inventory (2)')
      ;MouseMove(Random(300, 330, 1), Random(770, 780, 1))

      If CheckInventoryClosed() Then
      ;If Not IsStorageVisible() Then
         Log_('Opening inventory...')
         Send('{i}')
      EndIf

      If CheckProphecyExist() Then
         PressSeal()
         Sleep(100)

         If CheckEmptyWalletDialog() Then
            Stop('Not enough Silver coins to Seal.')
            ContinueLoop
         EndIf

         If CheckConfirmDialog() Then
            PressConfirmDialog()
         Else
            Stop('Unknown problem in CheckConfirmDialog.')
            ContinueLoop
         EndIf

         Log_('Put into inventory')
         $iInventoryKey = StoragePutItem($aInventory)
         If @error Then
            Stop('Inventory is full.')
            ContinueLoop
         EndIf

         Sleep(100)
         $sItemInfo = GetItemInfo()
         $aInfo = SplitProphecyInfo($sItemInfo)
         If @error Then
            ; place is occupied
            If IsNumber($iInventoryKey) Then
               _ArrayDelete($aInventory, $iInventoryKey)
            EndIf

            LogE('Error in SplitProphecyInfo()')
            ContinueLoop
         EndIf

         $sHash = String(_Crypt_HashData($aInfo[0] & $aInfo[1], $CALG_MD5))

         If $g_oDictNeededList.Exists($sHash) Then
            ; place is occupied
            If IsNumber($iInventoryKey) Then
               _ArrayDelete($aInventory, $iInventoryKey)
            EndIf
         Else
            Log_('Destroing item...')

            Local $aHeader[0][3], $aRow[1][3] = [[$aInfo[0], $aInfo[1], $sHash]]
            If Not $bCsvHeaderAdded Then
                Local $aHeader[1][3] = [['Name', 'Title', 'Hash']]
                $bCsvHeaderAdded = True
            EndIf

            CsvAppend($aRow, $aHeader, $g_sCsvDeletedPath, $g_hCsvHwnd)

            MouseClick($MOUSE_CLICK_LEFT)
            Sleep(50)
            MouseClick($MOUSE_CLICK_LEFT, Random(1230, 1244, 1), MouseGetPos(1) + Random(0, 10, 1))
            Sleep(120)

            ; confirm dialog
            If PixelGetColor(1170, 570) = 0x612f07 Then
               Send('{ENTER}')
               ;Send('{ESC}')
               Sleep(10)
            EndIf
         EndIf
         ; Move cursor out of inventory
         ;Log_('Move cursor out of inventory (1)')
         ;MouseMove(Random(650, 1200, 1), Random(400, 800, 1))

         ;Stop('TODO.')
         ;ContinueLoop
      Else
         PressSeek()
         Sleep(100)

         If CheckEmptyWalletDialog() Then
            Stop('Not enough Silver coins to Seek.')
            ContinueLoop
         EndIf

         ;ContinueLoop
      EndIf
   WEnd
EndFunc

Func Start($state = True)
   $state = IsDeclared('state') ? $state : True ; Because HotKeySet ignore default values of arguments too!

   $g_isRestarted = True
   $g_isStarted = $state
   Log_('Started: ' & $g_isStarted)

   Beep($g_isStarted ? 250 : 200, 250)
EndFunc

Func Stop($reason = '')
   $reason = IsDeclared('reason') ? $reason : 'User interrupt' ; Because HotKeySet ignore default values of arguments too!

   If $reason Then Log_($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc

Func CheckProphWindowOpen()
   $left = $ProphecySeekButtonPositions[0][0]
   $top = $ProphecySeekButtonPositions[0][1]
   $right = $left + 3
   $bottom = $top + 1
   ; Used 'Seek' button to check. It have 3 states...
   Const $CHECKSUM = 409076213
   Const $CHECKSUM_HOVER = 778699702
   Const $CHECKSUM_DISABLED = 299827555

   $checksumActual = PixelChecksum($left, $top, $right, $bottom, 1, $hWnd)
   Log_('CheckProphWindowOpen: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM = $checksumActual Or $CHECKSUM_HOVER = $checksumActual Or $CHECKSUM_DISABLED = $checksumActual
EndFunc

Func CheckProphecyExist()
   $left = $PropheciesPositions[6][0]
   $top = $PropheciesPositions[6][1]
   $right = $left + 3
   $bottom = $top + 1
   Const $CHECKSUM = 1554450471

   $checksumActual = PixelChecksum($left, $top, $right, $bottom, 1, $hWnd)
   Log_('CheckProphecyExist: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM = $checksumActual
EndFunc

Func PressSeek()
   $x = Random($ProphecySeekButtonPositions[0][0], $ProphecySeekButtonPositions[1][0], 1)
   $y = Random($ProphecySeekButtonPositions[0][1], $ProphecySeekButtonPositions[1][1], 1)
   $speed = Random(10, 20, 1)

   Log_('PressSeek')
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func PressSeal()
   $x = Random($ProphecySealButtonPositions[2][0], $ProphecySealButtonPositions[3][0], 1)
   $y = Random($ProphecySealButtonPositions[2][1], $ProphecySealButtonPositions[3][1], 1)
   $speed = Random(10, 20, 1)

   Log_('PressSeal')
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func CheckEmptyWalletDialog()
   Const $POSITION_X = 962
   Const $POSITION_Y = 508
   Const $DELTA_X = 16
   Const $DELTA_Y = 1
   Const $CHECKSUM = 3145278307

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   Log_('CheckEmptyWalletDialog: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM = $checksumActual
EndFunc

Func CheckConfirmDialog()
   Const $POSITION_X = 820
   Const $POSITION_Y = 541
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   Const $CHECKSUM = 1266288032

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   Log_('CheckConfirmDialog: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM = $checksumActual
EndFunc

Func PressConfirmDialog()
   $x = Random(777, 896, 1)
   $y = Random(542, 568, 1)
   $speed = Random(10, 20, 1)

   Log_('PressConfirmDialog')
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func CheckInventoryClosed()
   Const $POSITION_X = 1415
   Const $POSITION_Y = 74
   Const $DELTA_X = 7
   Const $DELTA_Y = 1
   Const $CHECKSUM = 3809219403

   $checksumActual = PixelChecksum($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, 1, $hWnd)
   Log_('CheckInventoryClosed: ' & $checksumActual, $LOG_LEVEL_DEBUG)

   Return $CHECKSUM <> $checksumActual
EndFunc

Func AskUserToPointCharacters()
   If Not IsDeclared('g_aNavaliPos') Then
      Global $g_aNavaliPos[0]
   EndIf
   If Not IsDeclared('g_aStashPos') Then
      Global $g_aStashPos[0]
   EndIf

   $iResult = MsgBox(UBound($g_aNavaliPos) ? $MB_CANCELTRYCONTINUE : $MB_OKCANCEL, 'Set position of NAVALI', _
      'Close all ingame dialogs (Esc) and mouse click on the NAVALI.' & @CRLF & @CRLF & _
      'Make sure NAVALI and Stash are close enough so that the character doesn''t move when you click on both.' & @CRLF & @CRLF & _
      'Ok (Continue) to set the position, Cancel to adjust positions, Retry to use previous positions.')

   If $iResult = $IDCANCEL Then
      Return False
   EndIf

   If $iResult = $IDCONTINUE Or $iResult = $IDOK Then
      $g_aNavaliPos = ListenForUserACtion()
      If @error Then
         Return False
      EndIf
   EndIf

   $iResult = MsgBox(UBound($g_aStashPos) ? $MB_CANCELTRYCONTINUE : $MB_OKCANCEL, 'Set position of STASH', _
      'Close all ingame dialogs (Esc) and mouse click on the STASH.' & @CRLF & @CRLF & _
      'Make sure STASH and Navali are close enough so that the character doesn''t move when you click on both.' & @CRLF & @CRLF & _
      'Also Make sure ACTIVE stash tab is for Prophecies purpose.' & @CRLF & @CRLF & _
      'Ok (Continue) to set the position, Cancel to adjust positions, Retry to use previous positions')

   If $iResult = $IDCANCEL Then
      Return False
   EndIf

   If $iResult = $IDCONTINUE Or $iResult = $IDOK Then
      $g_aStashPos = ListenForUserACtion()
      If @error Then
         Return False
      EndIf
   EndIf

   Return True
EndFunc

Func ClickNavali()
   Const $NAVALI_DIALOG_PROPH_POS_X = 870
   Const $NAVALI_DIALOG_PROPH_WIDTH = 180
   Const $NAVALI_DIALOG_PROPH_POS_Y = 183

   Send('{CTRLDOWN}')
   MouseClick($MOUSE_CLICK_LEFT, $g_aNavaliPos[0], $g_aNavaliPos[1])
   Send('{CTRLUP}')

   Sleep(250)
   ;MouseClick($MOUSE_CLICK_LEFT, Random($NAVALI_DIALOG_PROPH_POS_X, $NAVALI_DIALOG_PROPH_POS_X + $NAVALI_DIALOG_PROPH_WIDTH, 1), $NAVALI_DIALOG_PROPH_POS_Y)
   ;Sleep(150)
EndFunc

Func ClickStash()
   MouseClick($MOUSE_CLICK_LEFT, $g_aStashPos[0], $g_aStashPos[1])
   Sleep(150)
EndFunc

; '01' - Left mouse button {@see _IsPressed}
Func ListenForUserACtion($keyCode = '01')
   Const $USER_CANCELED = 1

   Local $hDLL = DllOpen("user32.dll")

   Local $aResult[2]

   While 1
      If _IsPressed($keyCode, $hDLL) Then
         Log_("ListenForUserACtion - Key was pressed.", $LOG_LEVEL_DEBUG)
         ; Wait until key is released.
         While _IsPressed($keyCode, $hDLL)
            Sleep(10)
         WEnd

         Log_("ListenForUserACtion - Key was released.", $LOG_LEVEL_DEBUG)
         $aResult = MouseGetPos()
         ExitLoop
      ElseIf _IsPressed("1B", $hDLL) Then
         Log_("The Esc Key was pressed, therefore we will stop listening action.", $LOG_LEVEL_DEBUG)
         SetError($USER_CANCELED)
         ExitLoop
      EndIf
      Sleep(10)
   WEnd

   DllClose($hDLL)

   Return $aResult
EndFunc

Func StorageCtrlClickItem(ByRef $aInventory)
   Const $ERROR_INTERRUPT = 1

   $isError = False

   Send('{CTRLDOWN}')

   For $i = 0 To UBound($aInventory) - 1
      If Not $g_isStarted Then
         $isError = True
         ExitLoop
      EndIf

      StorageClickItem($aInventory[$i][0], $aInventory[$i][1])
      Sleep(150)

      If Not CellCheckIsEmpty($aInventory[$i][0], $aInventory[$i][1]) Then
         Stop('Looks like stash is full')
         $isError = True
         ExitLoop
      EndIf
   Next

   Send('{CTRLUP}')

   If $isError Then
      SetError($ERROR_INTERRUPT)
   EndIf
EndFunc

Func GetCsvDeletedPath()
   Return @ScriptDir & '\ProphDeleted\' & StringFormat('%s-%s-%s_%s-%s.tsv', @YEAR, @MON, @MDAY, @HOUR, @MIN)
EndFunc
