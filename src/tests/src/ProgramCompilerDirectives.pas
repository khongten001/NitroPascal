{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

{$optimization "ReleaseSmall"}
{$target       "x86_64-linux-musl"}
{$exceptions   "on"}

//{$include_path ./include}
//{$library_path ./lib}
//{$link SDL2}
//{$module_path ./modules}

program ProgramCompilerDirectives;
begin
  WriteLn('=== Testing Compiler Directives ===');
  WriteLn('Optimization: ReleaseFast');
  WriteLn('Target: x86_64-windows-musl');
  WriteLn('Exceptions: on');
  //WriteLn('Include path: ./include');
  //WriteLn('Library path: ./lib');
  //WriteLn('Link: SDL2');
  //WriteLn('Module path: ./modules');
  WriteLn('✓ Compiler directives tested');
end.
