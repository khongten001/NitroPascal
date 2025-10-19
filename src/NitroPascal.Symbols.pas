{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Symbols;

{$I NitroPascal.Defines.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type

  { TSymbolKind }
  TNPSymbolKind = (skType, skVariable, skFunction, skProcedure, skConstant, skParameter);

  { TSymbol }
  TNPSymbol = record
    SymbolName: string;
    Kind: TNPSymbolKind;
    Line: Integer;
    Column: Integer;
    SourceFile: string;
  end;

  { TNPSymbolTable }
  TNPSymbolTable = class
  private
    FScopes: TStack<TDictionary<string, TNPSymbol>>;
    FGlobalScope: TDictionary<string, TNPSymbol>;
    
    procedure InitializeBuiltIns();
    procedure RegisterBuiltIn(const AName: string; const AKind: TNPSymbolKind);
    
  public
    constructor Create();
    destructor Destroy(); override;
    
    procedure EnterScope();
    procedure ExitScope();
    
    procedure AddSymbol(const ASymbol: TNPSymbol);
    function FindSymbol(const AName: string): Boolean;
    function GetSymbol(const AName: string): TNPSymbol;
    
    procedure Clear();
  end;

implementation

{ TNPSymbolTable }

constructor TNPSymbolTable.Create();
begin
  inherited Create();
  FScopes := TStack<TDictionary<string, TNPSymbol>>.Create();
  FGlobalScope := TDictionary<string, TNPSymbol>.Create();
  InitializeBuiltIns();
end;

destructor TNPSymbolTable.Destroy();
var
  LScope: TDictionary<string, TNPSymbol>;
begin
  while FScopes.Count > 0 do
  begin
    LScope := FScopes.Pop();
    LScope.Free();
  end;
  FScopes.Free();
  FGlobalScope.Free();
  inherited;
end;

procedure TNPSymbolTable.InitializeBuiltIns();
begin
  // Built-in constants
  RegisterBuiltIn('True', skConstant);
  RegisterBuiltIn('False', skConstant);
  RegisterBuiltIn('nil', skConstant);
  
  // Built-in types (from CodeGen.InitializeTypeMap)
  // Integer types
  RegisterBuiltIn('Byte', skType);
  RegisterBuiltIn('ShortInt', skType);
  RegisterBuiltIn('Word', skType);
  RegisterBuiltIn('SmallInt', skType);
  RegisterBuiltIn('Cardinal', skType);
  RegisterBuiltIn('Integer', skType);
  RegisterBuiltIn('LongWord', skType);
  RegisterBuiltIn('LongInt', skType);
  RegisterBuiltIn('Int64', skType);
  RegisterBuiltIn('UInt64', skType);
  
  // Floating point types
  RegisterBuiltIn('Single', skType);
  RegisterBuiltIn('Double', skType);
  RegisterBuiltIn('Extended', skType);
  RegisterBuiltIn('Real', skType);
  
  // Character and string types
  RegisterBuiltIn('Char', skType);
  RegisterBuiltIn('AnsiChar', skType);
  RegisterBuiltIn('WideChar', skType);
  RegisterBuiltIn('String', skType);
  RegisterBuiltIn('AnsiString', skType);
  RegisterBuiltIn('WideString', skType);
  RegisterBuiltIn('UnicodeString', skType);
  
  // Boolean type
  RegisterBuiltIn('Boolean', skType);
  
  // Pointer types
  RegisterBuiltIn('Pointer', skType);
  RegisterBuiltIn('PChar', skType);
  RegisterBuiltIn('PWideChar', skType);
  RegisterBuiltIn('PAnsiChar', skType);
  
  // File types
  RegisterBuiltIn('Text', skType);
  RegisterBuiltIn('TextFile', skType);
  RegisterBuiltIn('File', skType);
  RegisterBuiltIn('BinaryFile', skType);
  
  // Special types
  RegisterBuiltIn('Variant', skType);
  RegisterBuiltIn('OleVariant', skType);
  
  // Runtime functions and procedures (from CodeGen.RTL_FUNCTION_MAP)
  // I/O Functions
  RegisterBuiltIn('WriteLn', skProcedure);
  RegisterBuiltIn('Write', skProcedure);
  RegisterBuiltIn('ReadLn', skProcedure);
  
  // Memory Management
  RegisterBuiltIn('New', skProcedure);
  RegisterBuiltIn('Dispose', skProcedure);
  RegisterBuiltIn('GetMem', skProcedure);
  RegisterBuiltIn('FreeMem', skProcedure);
  RegisterBuiltIn('ReallocMem', skProcedure);
  
  // Memory Operations
  RegisterBuiltIn('FillChar', skProcedure);
  RegisterBuiltIn('Move', skProcedure);
  
  // Array/String Functions
  RegisterBuiltIn('Length', skFunction);
  RegisterBuiltIn('Copy', skFunction);
  RegisterBuiltIn('Pos', skFunction);
  RegisterBuiltIn('SetLength', skProcedure);
  RegisterBuiltIn('High', skFunction);
  RegisterBuiltIn('Low', skFunction);
  
  // String Manipulation
  RegisterBuiltIn('Insert', skProcedure);
  RegisterBuiltIn('Delete', skProcedure);
  RegisterBuiltIn('Trim', skFunction);
  RegisterBuiltIn('TrimLeft', skFunction);
  RegisterBuiltIn('TrimRight', skFunction);
  
  // String Conversion
  RegisterBuiltIn('IntToStr', skFunction);
  RegisterBuiltIn('StrToInt', skFunction);
  RegisterBuiltIn('StrToIntDef', skFunction);
  RegisterBuiltIn('FloatToStr', skFunction);
  RegisterBuiltIn('StrToFloat', skFunction);
  RegisterBuiltIn('UpperCase', skFunction);
  RegisterBuiltIn('LowerCase', skFunction);
  RegisterBuiltIn('BoolToStr', skFunction);
  RegisterBuiltIn('Format', skFunction);
  
  // Ordinal Functions
  RegisterBuiltIn('Ord', skFunction);
  RegisterBuiltIn('Chr', skFunction);
  RegisterBuiltIn('Succ', skFunction);
  RegisterBuiltIn('Pred', skFunction);
  RegisterBuiltIn('Inc', skProcedure);
  RegisterBuiltIn('Dec', skProcedure);
  
  // Type Information
  RegisterBuiltIn('Assigned', skFunction);
  RegisterBuiltIn('SizeOf', skFunction);
  
  // Set Operations
  RegisterBuiltIn('Include', skProcedure);
  RegisterBuiltIn('Exclude', skProcedure);
  
  // Program Control
  RegisterBuiltIn('Halt', skProcedure);
  RegisterBuiltIn('Exit', skProcedure);
  RegisterBuiltIn('Break', skProcedure);
  RegisterBuiltIn('Continue', skProcedure);
  
  // Math Functions
  RegisterBuiltIn('Abs', skFunction);
  RegisterBuiltIn('Sqr', skFunction);
  RegisterBuiltIn('Sqrt', skFunction);
  RegisterBuiltIn('Sin', skFunction);
  RegisterBuiltIn('Cos', skFunction);
  RegisterBuiltIn('Tan', skFunction);
  RegisterBuiltIn('ArcTan', skFunction);
  RegisterBuiltIn('ArcSin', skFunction);
  RegisterBuiltIn('ArcCos', skFunction);
  RegisterBuiltIn('Round', skFunction);
  RegisterBuiltIn('Trunc', skFunction);
  RegisterBuiltIn('Ceil', skFunction);
  RegisterBuiltIn('Floor', skFunction);
  RegisterBuiltIn('Max', skFunction);
  RegisterBuiltIn('Min', skFunction);
  RegisterBuiltIn('Randomize', skProcedure);
  RegisterBuiltIn('Random', skFunction);
  
  // File I/O
  RegisterBuiltIn('AssignFile', skProcedure);
  RegisterBuiltIn('Reset', skProcedure);
  RegisterBuiltIn('Rewrite', skProcedure);
  RegisterBuiltIn('Append', skProcedure);
  RegisterBuiltIn('CloseFile', skProcedure);
  RegisterBuiltIn('Eof', skFunction);
  RegisterBuiltIn('FileExists', skFunction);
  RegisterBuiltIn('DeleteFile', skFunction);
  RegisterBuiltIn('RenameFile', skFunction);
  RegisterBuiltIn('DirectoryExists', skFunction);
  RegisterBuiltIn('CreateDir', skFunction);
  RegisterBuiltIn('GetCurrentDir', skFunction);
  
  // Exception Handling
  RegisterBuiltIn('RaiseException', skProcedure);
  RegisterBuiltIn('GetExceptionMessage', skFunction);
  
  // Command Line Parameters
  RegisterBuiltIn('ParamCount', skFunction);
  RegisterBuiltIn('ParamStr', skFunction);
  
  // Binary File I/O
  RegisterBuiltIn('BlockRead', skProcedure);
  RegisterBuiltIn('BlockWrite', skProcedure);
  RegisterBuiltIn('FileSize', skFunction);
  RegisterBuiltIn('FilePos', skFunction);
  RegisterBuiltIn('Seek', skProcedure);
end;

procedure TNPSymbolTable.RegisterBuiltIn(const AName: string; const AKind: TNPSymbolKind);
var
  LSymbol: TNPSymbol;
begin
  LSymbol.SymbolName := AName;
  LSymbol.Kind := AKind;
  LSymbol.Line := 0;
  LSymbol.Column := 0;
  LSymbol.SourceFile := '';
  FGlobalScope.Add(AName, LSymbol);
end;

procedure TNPSymbolTable.EnterScope();
var
  LNewScope: TDictionary<string, TNPSymbol>;
begin
  LNewScope := TDictionary<string, TNPSymbol>.Create();
  FScopes.Push(LNewScope);
end;

procedure TNPSymbolTable.ExitScope();
var
  LScope: TDictionary<string, TNPSymbol>;
begin
  if FScopes.Count > 0 then
  begin
    LScope := FScopes.Pop();
    LScope.Free();
  end;
end;

procedure TNPSymbolTable.AddSymbol(const ASymbol: TNPSymbol);
var
  LCurrentScope: TDictionary<string, TNPSymbol>;
begin
  if FScopes.Count > 0 then
  begin
    LCurrentScope := FScopes.Peek();
    LCurrentScope.AddOrSetValue(ASymbol.SymbolName, ASymbol);
  end
  else
  begin
    FGlobalScope.AddOrSetValue(ASymbol.SymbolName, ASymbol);
  end;
end;

function TNPSymbolTable.FindSymbol(const AName: string): Boolean;
var
  LScopeArray: TArray<TDictionary<string, TNPSymbol>>;
  LIndex: Integer;
begin

  // Check local scopes (from innermost to outermost)
  LScopeArray := FScopes.ToArray();
  for LIndex := Length(LScopeArray) - 1 downto 0 do
  begin
    if LScopeArray[LIndex].ContainsKey(AName) then
    begin
      Result := True;
      Exit;
    end;
  end;
  
  // Check global scope
  Result := FGlobalScope.ContainsKey(AName);
end;

function TNPSymbolTable.GetSymbol(const AName: string): TNPSymbol;
var
  LScopeArray: TArray<TDictionary<string, TNPSymbol>>;
  LIndex: Integer;
begin
  // Check local scopes (from innermost to outermost)
  LScopeArray := FScopes.ToArray();
  for LIndex := Length(LScopeArray) - 1 downto 0 do
  begin
    if LScopeArray[LIndex].TryGetValue(AName, Result) then
      Exit;
  end;
  
  // Check global scope
  if FGlobalScope.TryGetValue(AName, Result) then
    Exit;
  
  // Not found - return empty symbol
  Result.SymbolName := '';
  Result.Kind := skVariable;
  Result.Line := 0;
  Result.Column := 0;
  Result.SourceFile := '';
end;

procedure TNPSymbolTable.Clear();
var
  LScope: TDictionary<string, TNPSymbol>;
begin
  while FScopes.Count > 0 do
  begin
    LScope := FScopes.Pop();
    LScope.Free();
  end;
  FGlobalScope.Clear();
  InitializeBuiltIns();
end;

end.
