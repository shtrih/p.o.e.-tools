#include-once

#include <File.au3>

#include "Log_.au3"

; $sFilePath — file path or FileOpen handle
Func CsvAppend(ByRef $aSource, ByRef $aHeader, $sFilePath, ByRef $hFileHandle)
   If Not IsPtr($hFileHandle) Then
      $hFileHandle = CsvFileOpen($sFilePath)
      If @error Then
         $sError = 'An error occurred while opening the file.'
         LogE(StringFormat('Error CsvAppend(%s): %s', $sFilePath, $sError))

         Return False
      EndIf
   EndIf

   _ArrayConcatenate($aHeader, $aSource)
   If @error Then
      Local $aErrorDesc[7]
      $aErrorDesc[1] = '$aArrayTarget is not an array'
      $aErrorDesc[2] = '$aArraySource is not an array'
      $aErrorDesc[3] = '$aArrayTarget is not a 1D or 2D array'
      $aErrorDesc[4] = '$aArrayTarget and $aArraySource 1D/2D mismatch'
      $aErrorDesc[5] = '$aArrayTarget and $aArraySource column number mismatch (2D only)'
      $aErrorDesc[6] = '$iStart outside array bounds'

      $sError = $aErrorDesc[@error]
      LogE(StringFormat('Error CsvAppend(%s): %s', $sFilePath, $sError))

      Return False
   EndIf

   _FileWriteFromArray($hFileHandle, $aHeader, Default, Default, @TAB)
   If @error Then
      Local $aErrorDesc[6]
      $aErrorDesc[1] = 'Error opening specified file'
      $aErrorDesc[2] = '$aArray is not an array'
      $aErrorDesc[3] = 'Error writing to file'
      $aErrorDesc[4] = '$aArray is not a 1D or 2D array'
      $aErrorDesc[5] = 'Start index is greater than the $iUbound parameter'

      $sError = $aErrorDesc[@error]
      LogE(StringFormat('Error SaveCsv(%s): %s', $sFilePath, $sError))

      Return False
   EndIf

   Return True
EndFunc

Func CsvFileOpen($sFilePath)
   $hCsvHwnd = FileOpen($sFilePath, $FO_APPEND)
   If @error Then
      SetError(@error)

      Return False
   EndIf

   Return $hCsvHwnd
EndFunc

Func CsvClear($sFilePath)
   $hFileOpen = FileOpen($sFilePath, $FO_OVERWRITE)
   FileWrite($hFileOpen, '')
   FileClose($hFileOpen)
EndFunc
