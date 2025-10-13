{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

library LibraryWithExports;

function Add(const A, B: Integer): Integer;
begin
  Result := A + B;
end;

function Multiply(const A, B: Integer): Integer;
begin
  Result := A * B;
end;

procedure SetValue(var AValue: Integer; const ANewValue: Integer);
begin
  AValue := ANewValue;
end;

exports
  Add,
  Multiply,
  SetValue;

end.
