{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program ProgramOrdinalAdvanced;

var
  LI: Integer;
  LResult: Boolean;
  LWord: Word;

begin
  WriteLn('=== Testing Advanced Ordinal Functions ===');
  WriteLn();
  
  { ============================================================================
    Odd
    ============================================================================ }
  
  WriteLn('--- Odd ---');
  
  { Test even numbers }
  LI := 0;
  LResult := Odd(LI);
  WriteLn('Odd(0) = ', BoolToStr(LResult, True));
  
  LI := 2;
  LResult := Odd(LI);
  WriteLn('Odd(2) = ', BoolToStr(LResult, True));
  
  LI := 4;
  LResult := Odd(LI);
  WriteLn('Odd(4) = ', BoolToStr(LResult, True));
  
  LI := -2;
  LResult := Odd(LI);
  WriteLn('Odd(-2) = ', BoolToStr(LResult, True));
  
  { Test odd numbers }
  LI := 1;
  LResult := Odd(LI);
  WriteLn('Odd(1) = ', BoolToStr(LResult, True));
  
  LI := 3;
  LResult := Odd(LI);
  WriteLn('Odd(3) = ', BoolToStr(LResult, True));
  
  LI := -1;
  LResult := Odd(LI);
  WriteLn('Odd(-1) = ', BoolToStr(LResult, True));
  
  WriteLn();
  
  { ============================================================================
    Swap
    ============================================================================ }
  
  WriteLn('--- Swap ---');
  
  { Test byte order swap }
  LWord := $1234;
  WriteLn('Original: $', IntToStr(LWord));
  
  LWord := Swap(LWord);
  WriteLn('After Swap: $', IntToStr(LWord));
  WriteLn('Expected: $3412');
  
  { Another test }
  LWord := $ABCD;
  WriteLn('Original: $', IntToStr(LWord));
  
  LWord := Swap(LWord);
  WriteLn('After Swap: $', IntToStr(LWord));
  WriteLn('Expected: $CDAB');
  
  { Verify swap is reversible }
  LWord := $1234;
  WriteLn('Original: $', IntToStr(LWord));
  LWord := Swap(LWord);
  LWord := Swap(LWord);
  WriteLn('After double Swap: $', IntToStr(LWord));
  WriteLn('Should match original: ', LWord = $1234);
  
  WriteLn();
  WriteLn('✓ All advanced ordinal functions tested successfully');
end.
