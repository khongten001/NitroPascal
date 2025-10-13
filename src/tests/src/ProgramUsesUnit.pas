{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program ProgramUsesUnit;

uses
  UnitSimple;

var
  GResult: Integer;

begin
  WriteLn('=== ProgramUsesUnit ===');
  
  GResult := Add(10, 20);
  WriteLn('Add(10, 20) = ', GResult);
  
  GResult := Multiply(5, 6);
  WriteLn('Multiply(5, 6) = ', GResult);
end.
