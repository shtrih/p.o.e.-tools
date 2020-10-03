#include-once

#include <AutoItConstants.au3>
#include "Log_.au3"

Global $g_initStorage = False
Global $g_borderWidth
Global $g_cellWidth
Global $g_cellStartPosX
Global $g_cellStartPosY
Global $g_horCount
Global $g_vertCount

Func InitStorageSettings($borderWidth=2, $cellWidth=50, $cellStartPosX=1269, $cellStartPosY=585, $HorCellCount=12, $VertCellCount=5)
   $g_borderWidth   = $borderWidth
   $g_cellWidth     = $cellWidth
   $g_cellStartPosX = $cellStartPosX
   $g_cellStartPosY = $cellStartPosY
   $g_horCount      = $HorCellCount
   $g_vertCount     = $VertCellCount
   $g_initStorage   = True
EndFunc

Func CellNum2PixelPos($numX, $numY)
   $posX = $g_cellStartPosX + ($g_cellWidth * $numX) + ($g_borderWidth * ($numX + 1))
   $posY = $g_cellStartPosY + ($g_cellWidth * $numY) + ($g_borderWidth * ($numY + 1))

   Local $result[2] = [$posX, $posY]

   Return $result
EndFunc

Func CellCenterPixel()
   Return $g_cellWidth/2
EndFunc

Func CellCheckColor($numX, $numY, $checkColor, $shadeVariation)
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   $cellPixelPositions = CellNum2PixelPos($numX, $numY)
   Const $POSITION_X = Ceiling($cellPixelPositions[0] + $g_cellWidth/2 - $DELTA_X/2)
   Const $POSITION_Y = Ceiling($cellPixelPositions[1] + $g_cellWidth/2 - $DELTA_Y/2)

   Log_(StringFormat('CellCheckColor(%s, %s)(%s, %s, %s, %s)', $numX, $numY, $POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y), $LOG_LEVEL_DEBUG)

   ;MouseMove($POSITION_X, $POSITION_Y, 1)

   PixelSearch($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, $checkColor, $shadeVariation)

   Return Not @error
EndFunc

Func StorageScan($checkColor, $shadeVariation)
   Local $result[$g_horCount * $g_vertCount][2]

   Local $counter = 0
   For $x = 0 to ($g_horCount - 1)
      For $y = 0 to ($g_vertCount - 1)
         If CellCheckColor($x, $y, $checkColor, $shadeVariation) Then
            $result[$counter][0] = $x
            $result[$counter][1] = $y

            $counter += 1
         EndIf
      Next
   Next

   Return $result
EndFunc

Func StorageFindEmptySpace($inventory)
   Local $result[2]

   For $i = 0 To UBound($inventory) - 1
      If IsNumber($inventory[$i][0]) Then
         Local $pos[2] = [$inventory[$i][0], $inventory[$i][1]]
         $result[0] = $i
         $result[1] = $pos

         Return $result
      EndIf
   Next

   Return False
EndFunc

Func StoragePutItem(ByRef $inventory)
   $cell = StorageFindEmptySpace($inventory)

   If $cell = False Then
      Return SetError(1, 0, 0)
   EndIf

   $invKey = $cell[0]
   $cellPos = $cell[1]

   $inventory[ $invKey ][0] = False

   $mousePos = CellNum2PixelPos($cellPos[0], $cellPos[1])
   Const $x = Random($mousePos[0], $mousePos[0] + $g_cellWidth, 1)
   Const $y = Random($mousePos[1], $mousePos[1] + $g_cellWidth, 1)
   Const $speed = Random(10, 20, 1)

   Log_(StringFormat('InventoryPutItem(%s, %s)(%s, %s)', $cellPos[0], $cellPos[1], $x, $y), $LOG_LEVEL_DEBUG)
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc

Func IsStorageVisible()
   $x = $g_cellStartPosX + $g_borderWidth + $g_cellWidth + 1
   $y = $g_cellStartPosY + $g_borderWidth + 1

   $pos = PixelSearch($x, $y, $x + 1, $y + 1, 0x1c1522, 2) ; color with item
   If Not @error Then
      ;LogV($pos[0], $pos[1])
      Return True
   EndIf

   PixelSearch($x, $y, $x + 1, $y + 1, 0x2a2117, 2) ; empty cell color
   $bResult = Not @error

   Return $bResult
EndFunc

Func CellMove($numX, $numY)
   $pos = CellNum2PixelPos($numX, $numY)
   $mousePosX = Random($pos[0] + 5, $pos[0] + $g_cellWidth - 5, 1)
   $mousePosY = Random($pos[1] + 5, $pos[1] + $g_cellWidth - 5, 1)
   $mouseSpeed = Random(5, 10, 1)

   MouseMove($mousePosX, $mousePosY, $mouseSpeed)
EndFunc

Func GetItemInfo()
   Send('^c')
   Sleep(100)

   $sItemInfo = ClipGet()
;Logv('Item: ', $numX, $numY, $sItemInfo)
   If @error Then
      Return SetError(@error, 0, '')
   EndIf

   Return $sItemInfo
EndFunc

Func StorageScanItemsInfo($checkColor, $shadeVariation)
   Local $result[$g_horCount * $g_vertCount][3]

   Local $counter = 0
   Local $isPrevWithItem = True
   For $x = 0 to ($g_horCount - 1)
      For $y = 0 to ($g_vertCount - 1)
         If Not CellCheckColor($x, $y, $checkColor, $shadeVariation) Then
            CellMove($x, $y)
            $result[$counter][0] = $x
            $result[$counter][1] = $y
            $result[$counter][2] = GetItemInfo()

            $counter += 1
            $isPrevWithItem = True
         Else
            If $isPrevWithItem Then
               CellMove($x, $y)
               $isPrevWithItem = False
            EndIf
         EndIf
      Next
   Next

   Return $result
EndFunc
