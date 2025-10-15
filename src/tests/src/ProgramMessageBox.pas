{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

{$APPTYPE GUI}

program ProgramMessageBox;

function MessageBoxW(hWnd: Cardinal; lpText: PChar; lpCaption: PChar; uType: Cardinal): Integer; 
  stdcall; external 'user32.dll';

begin
  MessageBoxW(0, 'Hello from NitroPascal!', 'Test', 0);
end.