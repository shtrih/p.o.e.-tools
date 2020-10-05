#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Hitagi

 Script Function:
    Move prophecies from inventory to stash
#ce ----------------------------------------------------------------------------
#pragma compile(Console, false)
#pragma compile(x64, true)
#pragma compile(Icon, "ProphecyOrbRed.ico")
#pragma compile(Out, "build/AutoMoveProph.exe")

#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>
#include "include/Inventory.au3"
#include "include/Stash.au3"
#include "include/StashQuad.au3"
#include "include/Log_.au3"
#include <Array.au3>

HotKeySet("^,", "Start")
HotKeySet("^.", "Stop")

Global $hWnd
Global $isStarted = False
Global $inventoryNeedRescan = False

Main()

Func Main()
   $hWnd = WinGetHandle("Path of Exile")
   ;$hWnd = WinGetHandle("XnView")

   If @error Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occurred when trying to retrieve the window handle PoE")
     Exit
   EndIf

   Log_(@ScriptName & ' is ready. Press Ctrl+, to start or Ctrl+. to pause!')

   $aInventory = False

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

         If Not IsArray($aInventory) Or $inventoryNeedRescan Then
            $inventoryNeedRescan = False
            Log_('Scanning inventory...')
            InitInventorySettings()
            $aInventory = StorageScan($COLOR_PROPHECY, $COLOR_PROPHECY_SHADE)
            ;_ArrayDisplay($aInventory)

            Log_('Start moving items...')
            StorageCtrlClickItem($aInventory, $isStarted)
         EndIf

         Stop('End')
      EndIf
   WEnd
EndFunc

Func Start($state = True)
   $state = IsDeclared('state') ? $state : True ; Because HotKeySet ignore default values of arguments too!

   $inventoryNeedRescan = True
   $isStarted = $state
   Log_('Started: ' & $isStarted)

   Beep($isStarted ? 250 : 200, 250)
;   Beep(41.204, 250)
;   Beep(55, 250)
;   Beep(73.416, 250)
;   Beep(97.999, 250)
EndFunc

Func Stop($reason = '')
   $reason = IsDeclared('reason') ? $reason : 'User command' ; Because HotKeySet ignore default values of arguments too!

   If $reason Then Log_($reason)
   Log_('Stopping the script...')

   Start(False)
   ; ContinueLoop ; "ExitLoop/ContinueLoop" statements only valid from inside a For/Do/While loop.
EndFunc

Func StorageCtrlClickItem(ByRef $aInventory, ByRef $bIsStarted)
   Send('{CTRLDOWN}')

   For $i = 0 To UBound($aInventory) - 1
      If Not $bIsStarted Then
         ExitLoop
      EndIf

      StorageClickItem($aInventory[$i][0], $aInventory[$i][1])
      Sleep(150)

      If Not CellCheckIsEmpty($aInventory[$i][0], $aInventory[$i][1]) Then
         Stop('Looks like stash is full')
         ExitLoop
      EndIf
   Next

   Send('{CTRLUP}')
EndFunc
