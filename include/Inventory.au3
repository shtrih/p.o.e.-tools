#include-once

#include <AutoItConstants.au3>
#include "Log_.au3"
#include "Storage.au3"
#include <Array.au3>

;$hWnd = WinGetHandle("XnView")
;WinWaitActive($hWnd)
;Beep(250, 250)
;InitInventorySettings()
;$aStash = InventoryScan()
;_ArrayDisplay($aStash)
;Log_(IsInventoryVisible())
;Beep(250, 250)

Func InitInventorySettings()
   Const $iBorderWidth   = 2
   Const $iCellWidth     = 50.5 ; Because cell size is sometimes 50 or 51
   Const $iCellStartPosX = 1269
   Const $iCellStartPosY = 585
   Const $iHorCount      = 12
   Const $iVertCount     = 5

   InitStorageSettings($iBorderWidth, $iCellWidth, $iCellStartPosX, $iCellStartPosY, $iHorCount, $iVertCount)
EndFunc

Func InventoryScan()
   Return StorageScan($COLOR_EMPTY, $COLOR_EMPTY_SHADE)
EndFunc

Func IsInventoryVisible()
   Return IsStorageVisible()
EndFunc
