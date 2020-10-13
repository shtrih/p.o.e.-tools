#include "Log_.au3"
#include "CSVPrefilledPrices.au3"

Main()

Func Main()
   $failedtxt = ""
   For $x = 1 To 2
      ConsoleWrite("> ========= Test" & $x & " Start   =========" & @CRLF)
      If Not Call("Test" & $x) Then
         ConsoleWrite("! ========= Test" & $x & " Failed! =========" & @CRLF & @CRLF)
         $failedtxt &=  "Test" & $x & " Failed!" & @CRLF
      Else
         ConsoleWrite("+ ========= Test" & $x & " Passed! =========" & @CRLF & @CRLF)
      EndIf
   Next

   If $failedtxt = ""  Then
      ConsoleWrite('All Tests Passed.')
   Else
      ConsoleWrite('Tests failed')
   EndIf
EndFunc

Func Equals($expected, $actual, $str = @ScriptLineNumber)
   If Not ($expected == $actual) Then
      Log_(StringFormat('Equals[%s]: expected %s but got %s', $str,$expected, $actual))

      Return False
   EndIf

   Return True
EndFunc

Func Test1()
   Equals(ApplyPrefilledPrice('', 2), 2)
   Equals(ApplyPrefilledPrice('1.5', 2), 1.5)
   Equals(ApplyPrefilledPrice('+2', 2), 4)
   Equals(ApplyPrefilledPrice('x1.5', 2), 3)
   Equals(ApplyPrefilledPrice('x 1.5', 2), 3)
   Equals(ApplyPrefilledPrice('x 1.5  ', 2), 2)
   Equals(ApplyPrefilledPrice('  x  1.5', 2), 2)
   Equals(ApplyPrefilledPrice('   1', 2), 1)
   Equals(ApplyPrefilledPrice(null, 2), 2)
   Equals(ApplyPrefilledPrice(null, '-'), '-')

   Return True
EndFunc

Func Test2()
   Local $aExpectedPrices[5] = [3, 2.1, 1, 2, 2]
   $oDict = GetPrefilledPricesDict('../fixtures/prefilled-proph-prices.tsv')

   $aKeys = $oDict.keys
   ;Log_($aKeys)
   If Not IsArray($aKeys) Then Return False
   Equals(5, UBound($aKeys))

   $aItems = $oDict.items
   ;Log_($aItems)
   If Not IsArray($aItems) Then Return False
   Equals(5, UBound($aItems))

   For $i = 0 To UBound($aItems)-1
      $fPrice = ApplyPrefilledPrice($aItems[$i], 2)
      If Not Equals($fPrice, $aExpectedPrices[$i]) Then Return False
   Next

   Return True
EndFunc
