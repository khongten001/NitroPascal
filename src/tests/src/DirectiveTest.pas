{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

{$OPTIMIZATION "releasesmall"}

{$APPTYPE CONSOLE}
//{$APPTYPE GUI}

program DirectiveTest;

{$IFDEF GUI_APP}
function MessageBoxW(hWnd: Cardinal; lpText: PChar; lpCaption: PChar; uType: Cardinal): Integer;
  stdcall; external 'user32.dll';
{$ENDIF}

// Test conditional compilation
{$IFDEF DEBUG}
const
  BuildMode = 'Debug Build';
{$ELSE}
const
  BuildMode = 'Release Build';
{$ENDIF}

{$IFDEF CONSOLE_APP}
const
  AppType = 'CONSOLE';
{$ENDIF}

{$IFDEF GUI_APP}
const
  AppType = 'GUI';
{$ENDIF}

{$IFDEF WIN32}
const
  Platform = 'Windows 32-bit';
{$ENDIF}

{$IFDEF WIN64}
const
  Platform = 'Windows 64-bit';
{$ENDIF}

{$IFDEF MSWINDOWS}
const
  OS = 'Windows';
{$ENDIF}

{$IFDEF LINUX}
const
  OS = 'Linux';
{$ENDIF}

begin
  {$IFDEF CONSOLE_APP}
  WriteLn('=== NitroPascal Directive Test ===');
  WriteLn('');
  WriteLn('Build Mode: ', BuildMode);
  WriteLn('Optimization: ReleaseSmall');
  WriteLn('AppType: ', AppType);
  WriteLn('');
  
  {$IFDEF WIN32}
  WriteLn('Platform: ', Platform);
  {$ENDIF}
  
  {$IFDEF WIN64}
  WriteLn('Platform: ', Platform);
  {$ENDIF}
  
  {$IFDEF MSWINDOWS}
  WriteLn('OS: ', OS);
  {$ENDIF}
  
  {$IFDEF LINUX}
  WriteLn('OS: ', OS);
  {$ENDIF}
  
  WriteLn('');
  {$IFDEF DEBUG}
  WriteLn('Debug mode is active!');
  {$ELSE}
  WriteLn('Release mode is active!');
  {$ENDIF}
  
  WriteLn('');
  WriteLn('All directives processed successfully!');
  {$ENDIF}
  
  {$IFDEF GUI_APP}
  MessageBoxW(0, 'NitroPascal Directive Test passed!', 'DirectiveTest', 0);
  {$ENDIF}
end.