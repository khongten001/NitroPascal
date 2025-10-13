{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

library LibrarySimple;

function LibAdd(A: Integer; B: Integer): Integer; stdcall;
begin
  Result := A + B;
end;

function LibMultiply(A: Integer; B: Integer): Integer; stdcall;
begin
  Result := A * B;
end;

exports
  LibAdd,
  LibMultiply;

begin
end.
