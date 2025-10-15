{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Preprocessor;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  NitroPascal.Compiler,
  NitroPascal.Errors,
  NitroPascal.BuildSettings;

type
  { TNPPreprocessor }
  TNPPreprocessor = class
  strict private
    FCompiler: TNPCompiler;
    FSourceFile: string;
    FLineNumber: Integer;
    
    procedure ProcessDirective(const ADirective: string; const AValue: string);
    function ParseDirectiveLine(const ALine: string; out ADirective: string; out AValue: string): Boolean;
    function ParseOptimizationMode(const AValue: string): TNPOptimizeMode;
    function ParseBoolean(const AValue: string): Boolean;
    function DequoteValue(const AValue: string): string;
    function IsConditionalDirective(const ADirective: string): Boolean;
    
  public
    constructor Create(const ACompiler: TNPCompiler);
    
    function ProcessFile(const AFilename: string): Boolean;
  end;

implementation

{ TNPPreprocessor }

constructor TNPPreprocessor.Create(const ACompiler: TNPCompiler);
begin
  inherited Create();
  FCompiler := ACompiler;
  FSourceFile := '';
  FLineNumber := 0;
end;

function TNPPreprocessor.DequoteValue(const AValue: string): string;
var
  LTrimmed: string;
  LLen: Integer;
begin
  LTrimmed := AValue.Trim();
  LLen := LTrimmed.Length;
  
  // Check if surrounded by double quotes
  if (LLen >= 2) and (LTrimmed[1] = '"') and (LTrimmed[LLen] = '"') then
    Result := Copy(LTrimmed, 2, LLen - 2)
  // Check if surrounded by single quotes
  else if (LLen >= 2) and (LTrimmed[1] = '''') and (LTrimmed[LLen] = '''') then
    Result := Copy(LTrimmed, 2, LLen - 2)
  else
    Result := LTrimmed;
end;

function TNPPreprocessor.IsConditionalDirective(const ADirective: string): Boolean;
const
  // Directives handled by DelphiAST during parsing - silently ignored by preprocessor
  CONDITIONAL_DIRECTIVES: array[0..10] of string = (
    'ifdef',     // {$IFDEF xxx}
    'ifndef',    // {$IFNDEF xxx}
    'if',        // {$IF condition}
    'ifopt',     // {$IFOPT switch}
    'else',      // {$ELSE}
    'elseif',    // {$ELSEIF condition}
    'endif',     // {$ENDIF}
    'ifend',     // {$IFEND}
    'define',    // {$DEFINE xxx}
    'undef',     // {$UNDEF xxx}
    'r'          // {$R *.res} - resource files
  );
var
  LDirective: string;
  LCheckDir: string;
begin
  Result := False;
  LDirective := ADirective.Trim().ToLower();
  
  for LCheckDir in CONDITIONAL_DIRECTIVES do
  begin
    if LDirective = LCheckDir then
      Exit(True);
  end;
end;

function TNPPreprocessor.ParseOptimizationMode(const AValue: string): TNPOptimizeMode;
var
  LValue: string;
begin
  LValue := AValue.Trim().ToLower();
  
  if LValue = 'debug' then
    Result := omDebug
  else if LValue = 'releasesafe' then
    Result := omReleaseSafe
  else if LValue = 'releasefast' then
    Result := omReleaseFast
  else if LValue = 'releasesmall' then
    Result := omReleaseSmall
  else
    raise Exception.CreateFmt('Invalid optimization mode: %s (expected Debug, ReleaseSafe, ReleaseFast, or ReleaseSmall)', [AValue]);
end;

function TNPPreprocessor.ParseBoolean(const AValue: string): Boolean;
var
  LValue: string;
begin
  LValue := AValue.Trim().ToLower();
  
  if (LValue = 'on') or (LValue = 'true') or (LValue = 'yes') or (LValue = '1') then
    Result := True
  else if (LValue = 'off') or (LValue = 'false') or (LValue = 'no') or (LValue = '0') then
    Result := False
  else
    raise Exception.CreateFmt('Invalid boolean value: %s (expected on/off, true/false, yes/no, or 1/0)', [AValue]);
end;

procedure TNPPreprocessor.ProcessDirective(const ADirective: string; const AValue: string);
var
  LDir: string;
  LVal: string;
begin
  LDir := ADirective.Trim().ToLower();
  LVal := DequoteValue(AValue);
  
  try
    if LDir = 'optimization' then
      FCompiler.SetOptimize(ParseOptimizationMode(LVal))
    else if LDir = 'target' then
      FCompiler.SetTarget(LVal.Trim())
    else if LDir = 'exceptions' then
      FCompiler.SetEnableExceptions(ParseBoolean(LVal))
    else if LDir = 'strip' then
      FCompiler.SetStripSymbols(ParseBoolean(LVal))
    else if LDir = 'include_path' then
      FCompiler.AddIncludePath(LVal.Trim())
    else if LDir = 'library_path' then
      FCompiler.AddLibraryPath(LVal.Trim())
    else if LDir = 'link' then
      FCompiler.AddLinkLibrary(LVal.Trim())
    else if LDir = 'module_path' then
      FCompiler.AddModulePath(LVal.Trim())
    else if LDir = 'apptype' then
    begin
      if LVal.ToLower() = 'console' then
        FCompiler.SetAppType(atConsole)
      else if LVal.ToLower() = 'gui' then
        FCompiler.SetAppType(atGUI)
      else
        raise Exception.CreateFmt('Invalid APPTYPE value: %s (expected CONSOLE or GUI)', [LVal]);
    end
    else
    begin
      // Check if it's a conditional directive (handled by DelphiAST)
      if not IsConditionalDirective(ADirective) then
      begin
        // Unknown directive - warn only if not conditional
        FCompiler.PrintLn('Warning: Unknown compiler directive {$%s} at line %d', [ADirective, FLineNumber]);
      end;
      // If it IS conditional, silently ignore (DelphiAST handles it)
    end;
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt('Error in directive {$%s} at line %d: %s', 
        [ADirective, FLineNumber, E.Message]);
    end;
  end;
end;

function TNPPreprocessor.ParseDirectiveLine(const ALine: string; 
  out ADirective: string; out AValue: string): Boolean;
var
  LTrimmed: string;
  LEnd: Integer;
  LContent: string;
  LSpacePos: Integer;
begin
  Result := False;
  ADirective := '';
  AValue := '';
  
  LTrimmed := ALine.Trim();
  
  // Check for compiler directive pattern: {$...}
  if not LTrimmed.StartsWith('{$') then
    Exit;
  
  LEnd := Pos('}', LTrimmed);
  if LEnd = 0 then
    Exit; // Malformed directive
  
  // Extract content between {$ and }
  LContent := Copy(LTrimmed, 3, LEnd - 3).Trim();
  
  // Split into directive and value at first whitespace
  LSpacePos := Pos(' ', LContent);
  if LSpacePos = 0 then
  begin
    // No space - directive only (like {$strip})
    ADirective := LContent;
    AValue := '';
  end
  else
  begin
    ADirective := Copy(LContent, 1, LSpacePos - 1).Trim();
    AValue := Copy(LContent, LSpacePos + 1, Length(LContent)).Trim();
  end;
  
  Result := not ADirective.IsEmpty;
end;

function TNPPreprocessor.ProcessFile(const AFilename: string): Boolean;
var
  LLines: TStringList;
  LLine: string;
  LDirective: string;
  LValue: string;
begin
  Result := False;
  FSourceFile := AFilename;
  
  if not TFile.Exists(AFilename) then
    Exit;
  
  try
    LLines := TStringList.Create();
    try
      LLines.LoadFromFile(AFilename);
      
      FLineNumber := 0;
      for LLine in LLines do
      begin
        Inc(FLineNumber);
        
        if ParseDirectiveLine(LLine, LDirective, LValue) then
        begin
          ProcessDirective(LDirective, LValue);
        end;
      end;
      
      Result := True;
    finally
      LLines.Free();
    end;
  except
    on E: Exception do
    begin
      // Log error and return false
      FCompiler.PrintLn('Preprocessor error: %s', [E.Message]);
      Result := False;
    end;
  end;
end;

end.
