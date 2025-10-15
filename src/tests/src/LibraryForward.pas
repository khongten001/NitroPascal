{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

library LibraryForward;

function Add(A, B: Integer): Integer; forward;
function Multiply(A, B: Integer): Integer; forward;

function Add(A, B: Integer): Integer;
begin
  Result := A + B;
end;

function Multiply(A, B: Integer): Integer;
begin
  Result := A * B;
end;

exports
  Add,
  Multiply;

end.