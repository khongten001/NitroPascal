{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program ProgramTypes;

type
  TPoint = record
    X: Integer;
    Y: Integer;
  end;
  
  PPoint = ^TPoint;

var
  GPoint: TPoint;
  GPointPtr: PPoint;

begin
  WriteLn('=== ProgramTypes ===');
  
  GPoint.X := 10;
  GPoint.Y := 20;
  WriteLn('GPoint: (', GPoint.X, ', ', GPoint.Y, ')');
  
  New(GPointPtr);
  GPointPtr^.X := 5;
  GPointPtr^.Y := 15;
  WriteLn('GPointPtr^: (', GPointPtr^.X, ', ', GPointPtr^.Y, ')');
  Dispose(GPointPtr);
  WriteLn('GPointPtr disposed');
end.
