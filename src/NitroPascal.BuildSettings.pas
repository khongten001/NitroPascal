unit NitroPascal.BuildSettings;

interface

uses
  System.SysUtils,
  System.Classes;

type
  { TNPOptimizeMode }
  TNPOptimizeMode = (
    omDebug,           // Debug mode with safety checks
    omReleaseSafe,     // Optimized with safety checks
    omReleaseFast,     // Fully optimized, minimal safety
    omReleaseSmall     // Optimized for size
  );

  { TNPTemplate }
  TNPTemplate = (
    tpProgram,     // Program template
    tpLibrary,     // Library template
    tpUnit         // Unit template
  );

  { TNPAppType }
  TNPAppType = (
    atConsole,    // Console application (default)
    atGUI         // GUI application (no console window)
  );

  { TNPBuildSettings }
  TNPBuildSettings = class
  private
    FTarget: string;
    FOptimize: TNPOptimizeMode;
    FEnableExceptions: Boolean;
    FStripSymbols: Boolean;
    FAppType: TNPAppType;
    FModulePaths: TStringList;
    FIncludePaths: TStringList;
    FLibraryPaths: TStringList;
    FLinkLibraries: TStringList;

    function IsValidIdentifier(const AValue: string): Boolean;

  public
    constructor Create();
    destructor Destroy(); override;

    function NormalizePath(const APath: string): string;

    procedure AddModulePath(const APath: string);
    procedure AddIncludePath(const APath: string);
    procedure AddLibraryPath(const APath: string);
    procedure AddLinkLibrary(const ALibrary: string);

    procedure ClearModulePaths();
    procedure ClearIncludePaths();
    procedure ClearLibraryPaths();
    procedure ClearLinkLibraries();

    function GetModulePaths(): TArray<string>;
    function GetIncludePaths(): TArray<string>;
    function GetLibraryPaths(): TArray<string>;
    function GetLinkLibraries(): TArray<string>;

    procedure Reset();
    function ValidateAndNormalizeTarget(const ATarget: string): string;

    property Target: string read FTarget write FTarget;
    property Optimize: TNPOptimizeMode read FOptimize write FOptimize;
    property EnableExceptions: Boolean read FEnableExceptions write FEnableExceptions;
    property StripSymbols: Boolean read FStripSymbols write FStripSymbols;
    property AppType: TNPAppType read FAppType write FAppType;
  end;

implementation

{ TNPBuildSettings }

constructor TNPBuildSettings.Create();
begin
  inherited Create();

  FTarget := '';
  FOptimize := omDebug;
  FEnableExceptions := True;
  FStripSymbols := False;
  FAppType := atConsole;

  FModulePaths := TStringList.Create();
  FIncludePaths := TStringList.Create();
  FLibraryPaths := TStringList.Create();
  FLinkLibraries := TStringList.Create();
end;

destructor TNPBuildSettings.Destroy();
begin
  FModulePaths.Free();
  FIncludePaths.Free();
  FLibraryPaths.Free();
  FLinkLibraries.Free();
  inherited;
end;

function TNPBuildSettings.NormalizePath(const APath: string): string;
begin
  // Normalize path separators for Zig (forward slashes)
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

function TNPBuildSettings.IsValidIdentifier(const AValue: string): Boolean;
var
  LI: Integer;
  LC: Char;
begin
  Result := False;

  if AValue.IsEmpty then
    Exit;

  for LI := 1 to AValue.Length do
  begin
    LC := AValue[LI];
    if not CharInSet(LC, ['a'..'z', '0'..'9', '_']) then
      Exit;
  end;

  Result := True;
end;

function TNPBuildSettings.ValidateAndNormalizeTarget(const ATarget: string): string;
var
  LTrimmed: string;
  LParts: TArray<string>;
  LI: Integer;
  LPart: string;
begin
  LTrimmed := ATarget.Trim().ToLower();

  // Empty or 'native' is valid
  if (LTrimmed = '') or (LTrimmed = 'native') then
    Exit('native');

  // Split by dash
  LParts := LTrimmed.Split(['-']);

  // Must have 2 or 3 parts: arch-os or arch-os-abi
  if (Length(LParts) < 2) or (Length(LParts) > 3) then
    raise Exception.CreateFmt(
      'Invalid target format: "%s"' + sLineBreak +
      'Expected format: arch-os or arch-os-abi' + sLineBreak +
      'Examples: x86_64-linux, aarch64-macos, wasm32-wasi',
      [ATarget]
    );

  // Validate and clean each part
  for LI := 0 to High(LParts) do
  begin
    LPart := LParts[LI].Trim();

    // Remove any extra spaces or invalid characters
    if Pos(' ', LPart) > 0 then
    begin
      // If contains space, take last word (handles "triple x86_64" → "x86_64")
      LPart := LPart.Split([' '])[High(LPart.Split([' ']))];
    end;

    // Ensure it's a valid identifier (alphanumeric + underscore)
    if not IsValidIdentifier(LPart) then
      raise Exception.CreateFmt(
        'Invalid component "%s" in target "%s"' + sLineBreak +
        'Components must be alphanumeric (a-z, 0-9, _)',
        [LPart, ATarget]
      );

    LParts[LI] := LPart;
  end;

  // Reconstruct normalized target
  Result := string.Join('-', LParts);
end;

procedure TNPBuildSettings.AddModulePath(const APath: string);
begin
  if not FModulePaths.Contains(APath) then
    FModulePaths.Add(APath);
end;

procedure TNPBuildSettings.AddIncludePath(const APath: string);
begin
  if not FIncludePaths.Contains(APath) then
    FIncludePaths.Add(APath);
end;

procedure TNPBuildSettings.AddLibraryPath(const APath: string);
begin
  if not FLibraryPaths.Contains(APath) then
    FLibraryPaths.Add(APath);
end;

procedure TNPBuildSettings.AddLinkLibrary(const ALibrary: string);
begin
  if not FLinkLibraries.Contains(ALibrary) then
    FLinkLibraries.Add(ALibrary);
end;

procedure TNPBuildSettings.ClearModulePaths();
begin
  FModulePaths.Clear();
end;

procedure TNPBuildSettings.ClearIncludePaths();
begin
  FIncludePaths.Clear();
end;

procedure TNPBuildSettings.ClearLibraryPaths();
begin
  FLibraryPaths.Clear();
end;

procedure TNPBuildSettings.ClearLinkLibraries();
begin
  FLinkLibraries.Clear();
end;

function TNPBuildSettings.GetModulePaths(): TArray<string>;
begin
  Result := FModulePaths.ToStringArray();
end;

function TNPBuildSettings.GetIncludePaths(): TArray<string>;
begin
  Result := FIncludePaths.ToStringArray();
end;

function TNPBuildSettings.GetLibraryPaths(): TArray<string>;
begin
  Result := FLibraryPaths.ToStringArray();
end;

function TNPBuildSettings.GetLinkLibraries(): TArray<string>;
begin
  Result := FLinkLibraries.ToStringArray();
end;

procedure TNPBuildSettings.Reset();
begin
  FTarget := '';
  FOptimize := omDebug;
  FEnableExceptions := False;
  FStripSymbols := False;
  FAppType := atConsole;

  FModulePaths.Clear();
  FIncludePaths.Clear();
  FLibraryPaths.Clear();
  FLinkLibraries.Clear();
end;

end.
