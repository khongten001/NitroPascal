{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UNitro;

interface

procedure RunNitro();

implementation

uses
  System.SysUtils,
  NitroPascal.BuildSettings,
  NitroPascal.Compiler,
  NitroPascal.Utils;

const
  // ANSI color codes
  COLOR_RESET   = #27'[0m';
  COLOR_BOLD    = #27'[1m';
  COLOR_RED     = #27'[31m';
  COLOR_GREEN   = #27'[32m';
  COLOR_YELLOW  = #27'[33m';
  COLOR_BLUE    = #27'[34m';
  COLOR_CYAN    = #27'[36m';
  COLOR_WHITE   = #27'[37m';

var
  GCompiler: TNPCompiler;

procedure ShowBanner();
var
  LVersion: TNPVersionInfo;
begin
  TNPUtils.PrintLn(COLOR_CYAN + COLOR_BOLD);
  TNPUtils.PrintLn(' _  _ _ _           ___                  _ ™');
  TNPUtils.PrintLn('| \| (_) |_ _ _ ___| _ \__ _ ___ __ __ _| |');
  TNPUtils.PrintLn('| .` | |  _| ''_/ _ \  _/ _` (_-</ _/ _` | |');
  TNPUtils.PrintLn('|_|\_|_|\__|_| \___/_| \__,_/__/\__\__,_|_|');
  TNPUtils.PrintLn(COLOR_WHITE + '      Modern Pascal * C Performance' + COLOR_RESET);
  TNPUtils.PrintLn('');
  
  if TNPUtils.GetVersionInfo(LVersion) then
    TNPUtils.PrintLn(COLOR_CYAN + 'Version ' + LVersion.VersionString + COLOR_RESET)
  else
    TNPUtils.PrintLn(COLOR_CYAN + 'Version unknown' + COLOR_RESET);
    
  TNPUtils.PrintLn('');
end;

procedure ShowHelp();
begin
  ShowBanner();

  TNPUtils.PrintLn(COLOR_BOLD + 'USAGE:' + COLOR_RESET);
  TNPUtils.PrintLn('  nitro ' + COLOR_CYAN + '<COMMAND>' + COLOR_RESET + ' [OPTIONS]');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn(COLOR_BOLD + 'COMMANDS:' + COLOR_RESET);
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'init' + COLOR_RESET + ' <n> [--template <type>]');
  TNPUtils.PrintLn('                   Create a new NitroPascal project');
  TNPUtils.PrintLn('                   Templates: program (default), library, unit');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'build' + COLOR_RESET + '          Compile Pascal source to C++ and build executable');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'run' + COLOR_RESET + '            Execute the compiled program');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'clean' + COLOR_RESET + '          Remove all generated files');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'convert-header' + COLOR_RESET + ' <input.h> [options]');
  TNPUtils.PrintLn('                   Convert C header file to Pascal unit');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'version' + COLOR_RESET + '        Display version information');
  TNPUtils.PrintLn('  ' + COLOR_GREEN + 'help' + COLOR_RESET + '           Display this help message');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn(COLOR_BOLD + 'OPTIONS:' + COLOR_RESET);
  TNPUtils.PrintLn('  -h, --help       Print help information');
  TNPUtils.PrintLn('  --version        Print version information');
  TNPUtils.PrintLn('  -t, --template   Specify project template type');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn(COLOR_BOLD + 'TEMPLATE TYPES:' + COLOR_RESET);
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'program' + COLOR_RESET + '        Executable program (default)');
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'library' + COLOR_RESET + '        Shared library (.dll on Windows, .so on Linux)');
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'unit' + COLOR_RESET + '           Static library (.lib on Windows, .a on Linux)');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn(COLOR_BOLD + 'EXAMPLES:' + COLOR_RESET);
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'nitro init MyGame' + COLOR_RESET + '                Create a program project');
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'nitro init MyLib --template library' + COLOR_RESET);
  TNPUtils.PrintLn('                                    Create a shared library project');
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'nitro build' + COLOR_RESET + '                      Build the current project');
  TNPUtils.PrintLn('  ' + COLOR_CYAN + 'nitro run' + COLOR_RESET + '                        Run the compiled executable');
  TNPUtils.PrintLn('');

  TNPUtils.PrintLn('For more information, visit: ' + COLOR_BLUE + 'https://github.com/tinyBigGAMES/NitroPascal' + COLOR_RESET);
  TNPUtils.PrintLn('');
end;

procedure ShowVersion();
begin
  ShowBanner();
  TNPUtils.PrintLn('Copyright © 2025-present tinyBigGAMES™ LLC');
  TNPUtils.PrintLn('All Rights Reserved.');
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn('Licensed under BSD 3-Clause License');
  TNPUtils.PrintLn('');
end;

procedure CommandInit();
var
  LProjectName: string;
  LBaseDir: string;
  LTemplate: TNPTemplate;
  LTemplateStr: string;
  LIndex: Integer;
begin
  if ParamCount < 2 then
  begin
    TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Project name required');
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Usage: ' + COLOR_CYAN + 'nitro init <n> [--template <type>]' + COLOR_RESET);
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Template Types:');
    TNPUtils.PrintLn('  program  - Executable program (default)');
    TNPUtils.PrintLn('  library  - Shared library (.dll/.so)');
    TNPUtils.PrintLn('  unit     - Static library (.lib/.a)');
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Example:');
    TNPUtils.PrintLn('  nitro init MyGame');
    TNPUtils.PrintLn('  nitro init MyLib --template library');
    TNPUtils.PrintLn('');
    ExitCode := 2;
    Exit;
  end;

  LProjectName := ParamStr(2);
  LBaseDir := GetCurrentDir() + PathDelim;
  LTemplate := tpProgram; // Default
  
  // Parse optional --template parameter
  LIndex := 3;
  while LIndex <= ParamCount do
  begin
    if ((ParamStr(LIndex) = '--template') or (ParamStr(LIndex) = '-t')) and (LIndex < ParamCount) then
    begin
      Inc(LIndex);
      LTemplateStr := LowerCase(ParamStr(LIndex).Trim());
      
      if LTemplateStr = 'program' then
        LTemplate := tpProgram
      else if LTemplateStr = 'library' then
        LTemplate := tpLibrary
      else if LTemplateStr = 'unit' then
        LTemplate := tpUnit
      else
      begin
        TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Invalid template type: ' + ParamStr(LIndex));
        TNPUtils.PrintLn('Valid types: program, library, unit');
        TNPUtils.PrintLn('');
        ExitCode := 2;
        Exit;
      end;
    end;
    Inc(LIndex);
  end;

  TNPUtils.PrintLn('');
  GCompiler.Init(LProjectName, LBaseDir, LTemplate);
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn(COLOR_GREEN + '✓ Project created successfully!' + COLOR_RESET);
  TNPUtils.PrintLn('');
end;

procedure CommandBuild();
begin
  TNPUtils.PrintLn('');
  try
    GCompiler.Build();
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn(COLOR_GREEN + COLOR_BOLD + '✓ Build completed successfully!' + COLOR_RESET);
    TNPUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn(COLOR_RED + COLOR_BOLD + '✗ Build failed!' + COLOR_RESET);
      
      // Build() already called PrintErrors() before raising exception if there were compiler errors
      // Only print the exception message if it's NOT a compilation error (e.g., Zig build failure)
      if not GCompiler.HasErrors() then
        TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      
      TNPUtils.PrintLn('');
      ExitCode := 3;
    end;
  end;
end;

procedure CommandRun();
begin
  TNPUtils.PrintLn('');
  try
    GCompiler.Run();
    TNPUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TNPUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure CommandClean();
begin
  TNPUtils.PrintLn('');
  try
    GCompiler.Clean();
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn(COLOR_GREEN + '✓ Clean completed successfully!' + COLOR_RESET);
    TNPUtils.PrintLn('');
  except
    on E: Exception do
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TNPUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure CommandConvertHeader();
var
  LInputFile: string;
  LOutputFile: string;
  LLibraryName: string;
  LConvention: string;
  LIndex: Integer;
begin
  if ParamCount < 2 then
  begin
    TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Input header file required');
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Usage: ' + COLOR_CYAN + 'nitro convert-header <input.h> [options]' + COLOR_RESET);
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Options:');
    TNPUtils.PrintLn('  --output <file>       Output Delphi unit filename');
    TNPUtils.PrintLn('  --library <n>         Target library name for external declarations');
    TNPUtils.PrintLn('  --convention <type>   Calling convention (cdecl, stdcall) [default: cdecl]');
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Example:');
    TNPUtils.PrintLn('  nitro convert-header sqlite3.h --output USQLite3.pas --library sqlite3');
    TNPUtils.PrintLn('');
    ExitCode := 2;
    Exit;
  end;

  LInputFile := ParamStr(2);
  LOutputFile := '';
  LLibraryName := '';
  LConvention := 'cdecl';

  // Parse optional parameters
  LIndex := 3;
  while LIndex <= ParamCount do
  begin
    if (ParamStr(LIndex) = '--output') and (LIndex < ParamCount) then
    begin
      Inc(LIndex);
      LOutputFile := ParamStr(LIndex);
    end
    else if (ParamStr(LIndex) = '--library') and (LIndex < ParamCount) then
    begin
      Inc(LIndex);
      LLibraryName := ParamStr(LIndex);
    end
    else if (ParamStr(LIndex) = '--convention') and (LIndex < ParamCount) then
    begin
      Inc(LIndex);
      LConvention := ParamStr(LIndex);
    end;
    Inc(LIndex);
  end;

  TNPUtils.PrintLn('');
  try
    GCompiler.ConvertCHeader(LInputFile, LOutputFile, LLibraryName, LConvention);
  except
    on E: Exception do
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + E.Message);
      TNPUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

procedure ProcessCommand();
var
  LCommand: string;
begin
  if ParamCount = 0 then
  begin
    ShowHelp();
    Exit;
  end;

  LCommand := LowerCase(ParamStr(1));

  // Handle flags
  if (LCommand = '-h') or (LCommand = '--help') or (LCommand = 'help') then
  begin
    ShowHelp();
    Exit;
  end;

  if (LCommand = '--version') or (LCommand = 'version') then
  begin
    ShowVersion();
    Exit;
  end;

  // Handle commands
  if LCommand = 'init' then
    CommandInit()
  else if LCommand = 'build' then
    CommandBuild()
  else if LCommand = 'run' then
    CommandRun()
  else if LCommand = 'clean' then
    CommandClean()
  else if LCommand = 'convert-header' then
    CommandConvertHeader()
  else
  begin
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn(COLOR_RED + 'Error: ' + COLOR_RESET + 'Unknown command: ' + COLOR_YELLOW + LCommand + COLOR_RESET);
    TNPUtils.PrintLn('');
    TNPUtils.PrintLn('Run ' + COLOR_CYAN + 'nitro help' + COLOR_RESET + ' to see available commands');
    TNPUtils.PrintLn('');
    ExitCode := 2;
  end;
end;

procedure RunNitro();
begin
  ExitCode := 0;
  GCompiler := nil;

  try
    GCompiler := TNPCompiler.Create();
    try
      ProcessCommand();
    finally
      FreeAndNil(GCompiler);
    end;
  except
    on E: Exception do
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn(COLOR_RED + COLOR_BOLD + 'Fatal Error: ' + COLOR_RESET + E.Message);
      TNPUtils.PrintLn('');
      ExitCode := 1;
    end;
  end;
end;

end.
