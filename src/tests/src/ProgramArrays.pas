{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program ProgramArrays;

type
  TIntArray = array[0..4] of Integer;
  TMatrix = array[0..1, 0..2] of Integer;

var
  GArray: TIntArray;
  GMatrix: TMatrix;
  GDynamic: array of Integer;
  GIndex: Integer;
  GSum: Integer;

begin
  // Static array initialization
  GArray[0] := 10;
  GArray[1] := 20;
  GArray[2] := 30;
  
  // Array access
  GSum := GArray[0] + GArray[1];
  
  // Multi-dimensional array
  GMatrix[0, 0] := 1;
  GMatrix[0, 1] := 2;
  GMatrix[1, 2] := 3;
  
  // Dynamic array
  SetLength(GDynamic, 5);
  GDynamic[0] := 100;
  
  // Array in loop
  for GIndex := 0 to 4 do
  begin
    GArray[GIndex] := GIndex * 10;
  end;
end.
