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

Func CellIsEmpty($numX, $numY, $checkColor, $shadeVariation)
   Const $DELTA_X = 3
   Const $DELTA_Y = 1
   $cellPixelPositions = CellNum2PixelPos($numX, $numY)
   Const $POSITION_X = $cellPixelPositions[0] + Ceiling($g_cellWidth/2 - $DELTA_X/2)
   Const $POSITION_Y = $cellPixelPositions[1] + Ceiling($g_cellWidth/2 - $DELTA_Y/2)

   Log_(StringFormat('CellIsEmpty(%s, %s)(%s, %s, %s, %s)', $numX, $numY, $POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y), $LOG_LEVEL_DEBUG)

   PixelSearch($POSITION_X, $POSITION_Y, $POSITION_X + $DELTA_X, $POSITION_Y + $DELTA_Y, $checkColor, $shadeVariation)

   Return Not @error
EndFunc

Func StorageScan($checkColor, $shadeVariation)
   Local $result[$g_horCount * $g_vertCount]

   Local $counter = 0
   For $x = 0 to ($g_horCount - 1)
      For $y = 0 to ($g_vertCount - 1)
         If CellIsEmpty($x, $y, $checkColor, $shadeVariation) Then
            Local $cell[2] = [$x, $y]
            $result[$counter] = $cell

            $counter += 1
         EndIf
      Next
   Next

   Return $result
EndFunc

Func StorageFindEmptySpace($inventory)
   Local $result[2]

   For $i = 0 To UBound($inventory) - 1
      If IsArray($inventory[$i]) Then
         $result[0] = $i
         $result[1] = $inventory[$i]

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

   $inventory[ $invKey ] = False

   $mousePos = CellNum2PixelPos($cellPos[0], $cellPos[1])
   Const $x = Random($mousePos[0], $mousePos[0] + $g_cellWidth, 1)
   Const $y = Random($mousePos[1], $mousePos[1] + $g_cellWidth, 1)
   Const $speed = Random(10, 20, 1)

   Log_(StringFormat('InventoryPutItem(%s, %s)(%s, %s)', $cellPos[0], $cellPos[1], $x, $y), $LOG_LEVEL_DEBUG)
   MouseClick($MOUSE_CLICK_LEFT, $x, $y, 1, $speed)
EndFunc
