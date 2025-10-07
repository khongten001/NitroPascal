{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Parser;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  NitroPascal.Types,
  NitroPascal.Lexer,
  System.Classes;

type
  { TNPParser }
  TNPParser = class
  private
    FLexer: TNPLexer;
    FCurrentToken: TNPToken;
    FErrors: TList<TNPError>;
    FDirectives: TDictionary<string, string>;
    
    procedure Advance();
    function Match(const AKind: TNPTokenKind): Boolean;
    function Expect(const AKind: TNPTokenKind; const AMsg: string): Boolean;
    procedure AddError(const AMsg: string);
    procedure Synchronize();
    procedure CollectDirectives();
    
    // Grammar rules
    function ParseProgram(): TNPProgramNode;
    function ParseModule(): TNPModuleNode;
    function ParseLibrary(): TNPLibraryNode;
    
    function ParseDeclarations(): TNPASTNodeList;
    function ParseImportWithoutKeyword(): TNPImportNode;
    {$HINTS OFF}
    function ParseImport(): TNPImportNode;
    {$HINTS ON}
    function ParseExtern(): TNPExternNode;
    function ParseTypeDeclWithoutKeyword(): TNPTypeDeclNode;
    function ParseTypeDecl(): TNPTypeDeclNode;
    function ParseConstDeclWithoutKeyword(): TNPConstDeclNode;
    {$HINTS OFF}
    function ParseConstDecl(): TNPConstDeclNode;
    {$HINTS ON}
    function ParseVarDeclWithoutKeyword(): TNPVarDeclNode;
    function ParseVarDecl(): TNPVarDeclNode;
    function ParseRoutineDecl(const AIsPublic: Boolean): TNPRoutineDeclNode;
    
    function ParseType(): TNPASTNode;
    function ParseRecordType(): TNPRecordNode;
    function ParseEnumType(): TNPEnumNode;
    function ParseArrayType(): TNPArrayNode;
    function ParsePointerType(): TNPPointerNode;
    function ParseFunctionType(): TNPASTNode;
    
    function ParseParameters(): TNPASTNodeList;
    function ParseParameter(): TNPParameterNode;
    
    function ParseStatementSequence(): TNPASTNodeList;
    function ParseStatement(): TNPASTNode;
    function ParseCompoundStatement(): TNPCompoundNode;
    function ParseIfStatement(): TNPIfNode;
    function ParseWhileStatement(): TNPWhileNode;
    function ParseRepeatStatement(): TNPRepeatNode;
    function ParseForStatement(): TNPForNode;
    function ParseCaseStatement(): TNPCaseNode;
    function ParseAssignment(ATarget: TNPASTNode): TNPAssignmentNode;
    
    function ParseExpression(): TNPASTNode;
    function ParseSimpleExpression(): TNPASTNode;
    function ParseTerm(): TNPASTNode;
    function ParseFactor(): TNPASTNode;
    function ParseDesignator(): TNPASTNode;
    function ParseCallOrMethodCall(ACallee: TNPASTNode): TNPASTNode;
    function ParseArgumentList(): TNPASTNodeList;
    
  public
    constructor Create(ALexer: TNPLexer);
    destructor Destroy; override;
    
    function Parse(const AMode: TNPCompilationMode): TNPASTNode;
    
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
    function GetDirectives(): TDictionary<string, string>;
  end;

implementation

{ TNPParser }

constructor TNPParser.Create(ALexer: TNPLexer);
begin
  inherited Create();
  FLexer := ALexer;
  FErrors := TList<TNPError>.Create();
  FDirectives := TDictionary<string, string>.Create();
  FCurrentToken := FLexer.NextToken();
end;

destructor TNPParser.Destroy;
begin
  FErrors.Free();
  FDirectives.Free();
  inherited;
end;

procedure TNPParser.Advance();
begin
  FCurrentToken := FLexer.NextToken();
end;

function TNPParser.Match(const AKind: TNPTokenKind): Boolean;
begin
  Result := FCurrentToken.Kind = AKind;
end;

function TNPParser.Expect(const AKind: TNPTokenKind; const AMsg: string): Boolean;
begin
  if Match(AKind) then
  begin
    Advance();
    Exit(True);
  end;
  
  AddError(AMsg);
  Result := False;
end;

procedure TNPParser.AddError(const AMsg: string);
begin
  FErrors.Add(TNPError.Create(FCurrentToken.Position, AMsg));
end;

procedure TNPParser.Synchronize();
begin
  Advance();
  
  while not Match(tkEOF) do
  begin
    if Match(tkSemicolon) then
    begin
      Advance();
      Exit;
    end;
    
    case FCurrentToken.Kind of
      tkProgram, tkModule, tkLibrary, tkType, tkConst, tkVar, 
      tkRoutine, tkBegin, tkEnd, tkIf, tkWhile, tkFor, tkCase, tkRepeat:
        Exit;
    end;
    
    Advance();
  end;
end;

function IsValidZigTarget(const ATarget: string): Boolean;
const
  VALID_ARCH: array[0..23] of string = (
    'x86_64', 'x86', 'aarch64', 'arm', 'armeb', 'aarch64_be', 'aarch64_32',
    'arc', 'avr', 'bpfel', 'bpfeb', 'csky', 'dxil', 'hexagon', 'loongarch32',
    'loongarch64', 'm68k', 'mips', 'mipsel', 'mips64', 'mips64el', 'msp430',
    'nvptx', 'nvptx64'
  );
  VALID_OS: array[0..23] of string = (
    'windows', 'linux', 'macos', 'freebsd', 'netbsd', 'openbsd', 'dragonfly',
    'wasi', 'emscripten', 'cuda', 'opencl', 'glsl', 'vulkan', 'metal',
    'amdhsa', 'ps4', 'ps5', 'elfiamcu', 'tvos', 'watchos', 'driverkit',
    'mesa3d', 'contiki', 'aix'
  );
  VALID_ABI: array[0..7] of string = (
    'gnu', 'musl', 'msvc', 'android', 'eabi', 'eabihf', 'ilp32', 'simulator'
  );
var
  LParts: TArray<string>;
  LArch: string;
  LOS: string;
  LABI: string;
  LFound: Boolean;
  LValidValue: string;
begin
  // Special case: 'native' is always valid
  if ATarget.ToLower() = 'native' then
    Exit(True);

  // Parse target triple: arch-os[-abi]
  LParts := ATarget.ToLower().Split(['-']);
  if Length(LParts) < 2 then
    Exit(False); // Must have at least arch-os

  LArch := LParts[0];
  LOS := LParts[1];
  if Length(LParts) >= 3 then
    LABI := LParts[2]
  else
    LABI := '';

  // Validate architecture
  LFound := False;
  for LValidValue in VALID_ARCH do
  begin
    if LArch = LValidValue then
    begin
      LFound := True;
      Break;
    end;
  end;
  if not LFound then
    Exit(False);

  // Validate OS
  LFound := False;
  for LValidValue in VALID_OS do
  begin
    if LOS = LValidValue then
    begin
      LFound := True;
      Break;
    end;
  end;
  if not LFound then
    Exit(False);

  // Validate ABI if present
  if not LABI.IsEmpty() then
  begin
    LFound := False;
    for LValidValue in VALID_ABI do
    begin
      if LABI = LValidValue then
      begin
        LFound := True;
        Break;
      end;
    end;
    if not LFound then
      Exit(False);
  end;

  Result := True;
end;

procedure TNPParser.CollectDirectives();
const
  VALID_OPTIMIZE_VALUES: array[0..3] of string = ('debug', 'release_safe', 'release_fast', 'release_small');
var
  LDirectiveName: string;
  LValue: string;
  LIsValid: Boolean;
  LValidValue: string;
begin
  // Collect all compiler directives at the beginning of the file
  while Match(tkDirective) do
  begin
    // The lexer provides:
    //   - Lexeme = directive name (without $)
    //   - Value = the string value from the quoted string
    LDirectiveName := FCurrentToken.Lexeme.Trim().ToLower();

    // Get value from the token's Value field (already parsed by lexer)
    if not FCurrentToken.Value.IsEmpty then
      LValue := FCurrentToken.Value.AsString
    else
      LValue := '';

    // Validate that directive has a value
    if LValue.IsEmpty() then
    begin
      AddError('Compiler directive $' + LDirectiveName + ' requires a value');
      Advance();
      Continue;
    end;

    // Validate directive values
    if LDirectiveName = 'optimize' then
    begin
      LValue := LValue.ToLower();
      LIsValid := False;
      for LValidValue in VALID_OPTIMIZE_VALUES do
      begin
        if LValue = LValidValue then
        begin
          LIsValid := True;
          Break;
        end;
      end;

      if not LIsValid then
      begin
        AddError(Format('Invalid value for $optimize: "%s". Valid values: debug, release_safe, release_fast, release_small', [LValue]));
        Advance();
        Continue;
      end;
    end
    else if (LDirectiveName = 'exceptions') or (LDirectiveName = 'strip_symbols') then
    begin
      LValue := LValue.ToLower();
      if (LValue <> 'on') and (LValue <> 'off') then
      begin
        AddError(Format('Invalid value for $%s: "%s". Valid values: on, off', [LDirectiveName, LValue]));
        Advance();
        Continue;
      end;
    end
    else if LDirectiveName = 'target' then
    begin
      if not IsValidZigTarget(LValue) then
      begin
        AddError(Format('Invalid Zig target: "%s". Format: <arch>-<os>[-<abi>] or "native". ' +
          'Examples: x86_64-windows, aarch64-linux-gnu, native', [LValue]));
        Advance();
        Continue;
      end;
    end;

    // Store directive (allow multiple for path directives)
    if FDirectives.ContainsKey(LDirectiveName) then
    begin
      // For path directives, append with semicolon separator
      if (LDirectiveName.EndsWith('_path')) or (LDirectiveName = 'link_library') then
        FDirectives[LDirectiveName] := FDirectives[LDirectiveName] + ';' + LValue
      else
        AddError(Format('Duplicate directive: $%s', [LDirectiveName]));
    end
    else
      FDirectives.Add(LDirectiveName, LValue);

    Advance();
  end;
end;

function TNPParser.Parse(const AMode: TNPCompilationMode): TNPASTNode;
begin
  Result := nil;
  
  // Collect compiler directives first
  CollectDirectives();
  
  case AMode of
    cmProgram: Result := ParseProgram();
    cmModule: Result := ParseModule();
    cmLibrary: Result := ParseLibrary();
  end;
end;

function TNPParser.ParseProgram(): TNPProgramNode;
var
  LNode: TNPProgramNode;
begin
  if not Expect(tkProgram, 'Expected "program"') then
    Exit(nil);
  
  if not Match(tkIdentifier) then
  begin
    AddError('Expected program name');
    Exit(nil);
  end;
  
  LNode := TNPProgramNode.Create(FCurrentToken.Position);
  LNode.Name := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Parse declarations
  LNode.Declarations := ParseDeclarations();
  
  // Parse main block
  if not Expect(tkBegin, 'Expected "begin"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.MainBlock := ParseStatementSequence();
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Expect(tkDot, 'Expected "."') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseModule(): TNPModuleNode;
var
  LNode: TNPModuleNode;
begin
  if not Expect(tkModule, 'Expected "module"') then
    Exit(nil);
  
  if not Match(tkIdentifier) then
  begin
    AddError('Expected module name');
    Exit(nil);
  end;
  
  LNode := TNPModuleNode.Create(FCurrentToken.Position);
  LNode.Name := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Parse declarations
  LNode.Declarations := ParseDeclarations();
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Expect(tkDot, 'Expected "."') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseLibrary(): TNPLibraryNode;
var
  LNode: TNPLibraryNode;
begin
  if not Expect(tkLibrary, 'Expected "library"') then
    Exit(nil);
  
  if not Match(tkIdentifier) then
  begin
    AddError('Expected library name');
    Exit(nil);
  end;
  
  LNode := TNPLibraryNode.Create(FCurrentToken.Position);
  LNode.Name := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Parse declarations
  LNode.Declarations := ParseDeclarations();
  
  // Optional init block
  if Match(tkBegin) then
  begin
    Advance();
    LNode.InitBlock := ParseStatementSequence();
    if not Expect(tkEnd, 'Expected "end"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    if not Expect(tkSemicolon, 'Expected ";"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
  end;
  
  // Optional finalize block
  if Match(tkFinalize) then
  begin
    Advance();
    LNode.FinalizeBlock := ParseStatementSequence();
    if not Expect(tkEnd, 'Expected "end"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    if not Expect(tkSemicolon, 'Expected ";"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
  end;
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Expect(tkDot, 'Expected "."') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseDeclarations(): TNPASTNodeList;
var
  LList: TNPASTNodeList;
  LNode: TNPASTNode;
begin
  LList := TNPASTNodeList.Create(True);
  
  while not Match(tkEOF) and not Match(tkBegin) and not Match(tkEnd) and not Match(tkFinalize) do
  begin
    
    if Match(tkImport) then
    begin
      Advance(); // Skip 'import' keyword
      // Parse all import declarations under this import keyword
      while Match(tkIdentifier) do
      begin
        LNode := ParseImportWithoutKeyword();
        if Assigned(LNode) then
          LList.Add(LNode);
      end;
      Continue; // Continue outer loop, don't add single node
    end
    else if Match(tkExtern) then
      LNode := ParseExtern()
    else if Match(tkType) then
    begin
      Advance(); // Skip 'type' keyword
      // Parse all type declarations under this type keyword
      while Match(tkIdentifier) do
      begin
        LNode := ParseTypeDeclWithoutKeyword();
        if Assigned(LNode) then
          LList.Add(LNode);
      end;
      Continue; // Continue outer loop, don't add single node
    end
    else if Match(tkConst) then
    begin
      Advance(); // Skip 'const' keyword
      // Parse all constant declarations under this const keyword
      while Match(tkIdentifier) do
      begin
        LNode := ParseConstDeclWithoutKeyword();
        if Assigned(LNode) then
          LList.Add(LNode);
      end;
      Continue; // Continue outer loop, don't add single node
    end
    else if Match(tkVar) then
    begin
      Advance(); // Skip 'var' keyword
      // Parse all variable declarations under this var keyword
      while Match(tkIdentifier) do
      begin
        LNode := ParseVarDeclWithoutKeyword();
        if Assigned(LNode) then
          LList.Add(LNode);
      end;
      Continue; // Continue outer loop, don't add single node
    end
    else if Match(tkPublic) then
    begin
      Advance();
      if Match(tkRoutine) then
        LNode := ParseRoutineDecl(True)
      else if Match(tkType) then
        LNode := ParseTypeDecl()
      else
      begin
        AddError('Expected "routine" or "type" after "public"');
        Synchronize();
        Continue;
      end;
    end
    else if Match(tkRoutine) then
      LNode := ParseRoutineDecl(False)
    else
      Break;
    
    if Assigned(LNode) then
      LList.Add(LNode);
  end;
  
  Result := LList;
end;

function TNPParser.ParseImportWithoutKeyword(): TNPImportNode;
var
  LNode: TNPImportNode;
begin
  if not Match(tkIdentifier) then
  begin
    AddError('Expected module name');
    Exit(nil);
  end;
  
  LNode := TNPImportNode.Create(FCurrentToken.Position);
  LNode.ModuleName := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseImport(): TNPImportNode;
begin
  Advance(); // Skip 'import'
  Result := ParseImportWithoutKeyword();
end;

function TNPParser.ParseExtern(): TNPExternNode;
var
  LNode: TNPExternNode;
begin
  Advance(); // Skip 'extern'
  
  LNode := TNPExternNode.Create(FCurrentToken.Position);
  
  // Parse source (<header> or "header" or dll "name")
  if Match(tkLess) then
  begin
    Advance();
    
    // Build header name by reading all tokens until '>'
    var LHeaderName: string := '';
    while not Match(tkGreater) and not Match(tkEOF) do
    begin
      LHeaderName := LHeaderName + FCurrentToken.Lexeme;
      Advance();
    end;
    
    if not Match(tkGreater) then
    begin
      AddError('Expected ">"');
      LNode.Free();
      Exit(nil);
    end;
    
    LNode.Source := '<' + LHeaderName + '>';
    Advance();
  end
  else if Match(tkString) then
  begin
    LNode.Source := FCurrentToken.Value.AsString;
    Advance();
  end
  else if Match(tkIdentifier) and (FCurrentToken.Lexeme = 'dll') then
  begin
    Advance();
    if not Match(tkString) then
    begin
      AddError('Expected DLL name');
      LNode.Free();
      Exit(nil);
    end;
    LNode.Source := FCurrentToken.Value.AsString;
    LNode.IsDLL := True;
    Advance();
    
    // Optional calling convention
    if Match(tkIdentifier) then
    begin
      if (FCurrentToken.Lexeme = 'stdcall') or 
         (FCurrentToken.Lexeme = 'cdecl') or 
         (FCurrentToken.Lexeme = 'fastcall') then
      begin
        LNode.CallConv := FCurrentToken.Lexeme;
        Advance();
      end;
    end;
  end
  else
  begin
    AddError('Expected header source');
    LNode.Free();
    Exit(nil);
  end;
  
  if not Expect(tkRoutine, 'Expected "routine"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Match(tkIdentifier) then
  begin
    AddError('Expected routine name');
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.RoutineName := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkLParen, 'Expected "("') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Match(tkRParen) then
    LNode.Parameters := ParseParameters();
  
  if not Expect(tkRParen, 'Expected ")"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Optional return type
  if Match(tkColon) then
  begin
    Advance();
    LNode.ReturnType := ParseType();
  end;
  
  // Optional "as" clause
  if Match(tkIdentifier) and (FCurrentToken.Lexeme = 'as') then
  begin
    Advance();
    if not Match(tkString) then
    begin
      AddError('Expected external name');
      LNode.Free();
      Exit(nil);
    end;
    LNode.ExternalName := FCurrentToken.Value.AsString;
    Advance();
  end;
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseTypeDeclWithoutKeyword(): TNPTypeDeclNode;
var
  LNode: TNPTypeDeclNode;
begin
  if not Match(tkIdentifier) then
  begin
    AddError('Expected type name');
    Exit(nil);
  end;
  
  LNode := TNPTypeDeclNode.Create(FCurrentToken.Position);
  LNode.TypeName := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkEquals, 'Expected "="') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.TypeDef := ParseType();
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseTypeDecl(): TNPTypeDeclNode;
begin
  Advance(); // Skip 'type'
  Result := ParseTypeDeclWithoutKeyword();
end;

function TNPParser.ParseConstDeclWithoutKeyword(): TNPConstDeclNode;
var
  LNode: TNPConstDeclNode;
begin
  if not Match(tkIdentifier) then
  begin
    AddError('Expected constant name');
    Exit(nil);
  end;
  
  LNode := TNPConstDeclNode.Create(FCurrentToken.Position);
  LNode.ConstName := FCurrentToken.Lexeme;
  Advance();
  
  // Optional type
  if Match(tkColon) then
  begin
    Advance();
    LNode.TypeNode := ParseType();
  end;
  
  if not Expect(tkEquals, 'Expected "="') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.Value := ParseExpression();
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseConstDecl(): TNPConstDeclNode;
begin
  Advance(); // Skip 'const'
  Result := ParseConstDeclWithoutKeyword();
end;

function TNPParser.ParseVarDeclWithoutKeyword(): TNPVarDeclNode;
var
  LNode: TNPVarDeclNode;
  LNames: TList<string>;
begin
  LNode := TNPVarDeclNode.Create(FCurrentToken.Position);
  LNames := TList<string>.Create();
  try
    // Parse identifier list
    repeat
      if not Match(tkIdentifier) then
      begin
        AddError('Expected variable name');
        LNode.Free();
        Exit(nil);
      end;
      LNames.Add(FCurrentToken.Lexeme);
      Advance();
      if not Match(tkComma) then
        Break;
      Advance();
    until False;

    LNode.VarNames := LNames.ToArray();
    
    if not Expect(tkColon, 'Expected ":"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    
    LNode.TypeNode := ParseType();
    
    // Optional initialization
    if Match(tkAssign) then
    begin
      Advance();
      LNode.InitValue := ParseExpression();
    end;
    
    if not Expect(tkSemicolon, 'Expected ";"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    
    Result := LNode;
  finally
    LNames.Free();
  end;
end;

function TNPParser.ParseVarDecl(): TNPVarDeclNode;
begin
  Advance(); // Skip 'var'
  Result := ParseVarDeclWithoutKeyword();
end;

function TNPParser.ParseRoutineDecl(const AIsPublic: Boolean): TNPRoutineDeclNode;
var
  LNode: TNPRoutineDeclNode;
begin
  Advance(); // Skip 'routine'
  
  if not Match(tkIdentifier) then
  begin
    AddError('Expected routine name');
    Exit(nil);
  end;
  
  LNode := TNPRoutineDeclNode.Create(FCurrentToken.Position);
  LNode.RoutineName := FCurrentToken.Lexeme;
  LNode.IsPublic := AIsPublic;
  Advance();
  
  if not Expect(tkLParen, 'Expected "("') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Match(tkRParen) then
    LNode.Parameters := ParseParameters();
  
  if not Expect(tkRParen, 'Expected ")"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Optional return type
  if Match(tkColon) then
  begin
    Advance();
    LNode.ReturnType := ParseType();
  end;
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Optional local variables
  while Match(tkVar) do
    LNode.LocalVars.Add(ParseVarDecl());
  
  if not Expect(tkBegin, 'Expected "begin"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.Body := ParseStatementSequence();
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Expect(tkSemicolon, 'Expected ";"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseType(): TNPASTNode;
var
  LIdent: TNPIdentifierNode;
  LSubrange: TNPSubrangeNode;
  LLowValue: Int64;
  LSavedPos: TNPSourcePos;
  LNode: TNPFunctionTypeNode;
begin
  Result := nil;
  
  if Match(tkArray) then
    Result := ParseArrayType()
  else if Match(tkIdentifier) then
  begin
    // Handle 'record' keyword
    if FCurrentToken.Lexeme = 'record' then
      Result := ParseRecordType()
    // Handle 'function' and 'procedure' type declarations
    else if (FCurrentToken.Lexeme = 'function') or (FCurrentToken.Lexeme = 'procedure') then
      Result := ParseFunctionType()
    else
    begin
      LIdent := TNPIdentifierNode.Create(FCurrentToken.Position);
      LIdent.Name := FCurrentToken.Lexeme;
      Advance();
      Result := LIdent;
    end;
  end
  else if Match(tkCaret) then
    Result := ParsePointerType()
  else if Match(tkLParen) then
    Result := ParseEnumType()
  else if Match(tkInteger) or Match(tkMinus) then
  begin
    // Subrange type: low..high
    LSavedPos := FCurrentToken.Position;
    
    if Match(tkMinus) then
    begin
      Advance();
      if not Match(tkInteger) then
      begin
        AddError('Expected integer for subrange low bound');
        Exit(nil);
      end;
      LLowValue := -FCurrentToken.Value.AsInt64;
      Advance();
    end
    else
    begin
      LLowValue := FCurrentToken.Value.AsInt64;
      Advance();
    end;
    
    if Match(tkDotDot) then
    begin
      Advance();
      LSubrange := TNPSubrangeNode.Create(LSavedPos);
      LSubrange.LowBound := LLowValue;
      
      if Match(tkMinus) then
      begin
        Advance();
        if not Match(tkInteger) then
        begin
          AddError('Expected integer for subrange high bound');
          LSubrange.Free();
          Exit(nil);
        end;
        LSubrange.HighBound := -FCurrentToken.Value.AsInt64;
        Advance();
      end
      else if Match(tkInteger) then
      begin
        LSubrange.HighBound := FCurrentToken.Value.AsInt64;
        Advance();
      end
      else
      begin
        AddError('Expected integer for subrange high bound');
        LSubrange.Free();
        Exit(nil);
      end;
      
      Result := LSubrange;
    end
    else
    begin
      AddError('Expected ".." in subrange type');
      Exit(nil);
    end;
  end
  else if Match(tkRoutine) then
  begin
    Advance(); // Skip 'routine'
    
    LNode := TNPFunctionTypeNode.Create(FCurrentToken.Position);
    
    if not Expect(tkLParen, 'Expected "("') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    
    if not Match(tkRParen) then
      TNPFunctionTypeNode(LNode).Parameters := ParseParameters();
    
    if not Expect(tkRParen, 'Expected ")"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    
    // Optional return type for routine function types
    if Match(tkColon) then
    begin
      Advance();
      TNPFunctionTypeNode(LNode).IsFunction := True;
      TNPFunctionTypeNode(LNode).ReturnType := ParseType();
    end
    else
    begin
      TNPFunctionTypeNode(LNode).IsFunction := False;
    end;
    
    Result := LNode;
  end
  else
    AddError('Expected type');
end;

function TNPParser.ParseRecordType(): TNPRecordNode;
var
  LNode: TNPRecordNode;
  LFieldDecl: TNPVarDeclNode;
  LNames: TList<string>;
begin
  Advance(); // Skip 'record'
  
  LNode := TNPRecordNode.Create(FCurrentToken.Position);
  
  while not Match(tkEnd) and not Match(tkEOF) do
  begin
    // Parse field declaration: name1, name2: type;
    LFieldDecl := TNPVarDeclNode.Create(FCurrentToken.Position);
    LNames := TList<string>.Create();
    try
      // Parse identifier list
      repeat
        if not Match(tkIdentifier) then
        begin
          AddError('Expected field name');
          LFieldDecl.Free();
          LNames.Free();
          LNode.Free();
          Exit(nil);
        end;
        LNames.Add(FCurrentToken.Lexeme);
        Advance();
        if not Match(tkComma) then
          Break;
        Advance();
      until False;

      LFieldDecl.VarNames := LNames.ToArray();
      
      if not Expect(tkColon, 'Expected ":"') then
      begin
        LFieldDecl.Free();
        LNames.Free();
        LNode.Free();
        Exit(nil);
      end;
      
      LFieldDecl.TypeNode := ParseType();
      
      if not Expect(tkSemicolon, 'Expected ";"') then
      begin
        LFieldDecl.Free();
        LNames.Free();
        LNode.Free();
        Exit(nil);
      end;
      
      LNode.Fields.Add(LFieldDecl);
    finally
      LNames.Free();
    end;
  end;
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseEnumType(): TNPEnumNode;
var
  LNode: TNPEnumNode;
  LValues: TList<string>;
begin
  Advance(); // Skip '('
  
  LNode := TNPEnumNode.Create(FCurrentToken.Position);
  LValues := TList<string>.Create();
  try
    repeat
      if not Match(tkIdentifier) then
      begin
        AddError('Expected enum value');
        LNode.Free();
        Exit(nil);
      end;
      LValues.Add(FCurrentToken.Lexeme);
      Advance();
      if not Match(tkComma) then
        Break;
      Advance();
    until False;
    
    LNode.Values := LValues.ToArray();
    
    if not Expect(tkRParen, 'Expected ")"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    
    Result := LNode;
  finally
    LValues.Free();
  end;
end;

function TNPParser.ParseArrayType(): TNPArrayNode;
var
  LNode: TNPArrayNode;
  LDimensions: TList<TPair<TNPASTNode, TNPASTNode>>;
  LLowExpr: TNPASTNode;
  LHighExpr: TNPASTNode;
begin
  Advance(); // Skip 'array'
  
  if not Expect(tkLBracket, 'Expected "["') then
    Exit(nil);
  
  LNode := TNPArrayNode.Create(FCurrentToken.Position);
  LDimensions := TList<TPair<TNPASTNode, TNPASTNode>>.Create();
  try
    // Parse dimension bounds
    repeat
      // Parse low bound expression
      LLowExpr := ParseSimpleExpression();
      if not Assigned(LLowExpr) then
      begin
        AddError('Expected expression for array lower bound');
        LNode.Free();
        LDimensions.Free();
        Exit(nil);
      end;
      
      // Check if this is a subrange type name (no .. following)
      if not Match(tkDotDot) then
      begin
        // Single identifier = subrange type (e.g., array[Index])
        // Use same expression for both bounds; codegen will resolve via symbol table
        LDimensions.Add(TPair<TNPASTNode, TNPASTNode>.Create(LLowExpr, LLowExpr));
        
        // Check for additional dimensions
        if Match(tkComma) then
        begin
          Advance();
          Continue;
        end
        else
          Break;
      end;
      
      // Normal case: low..high
      Advance(); // Skip '..'
      
      // Parse high bound expression
      LHighExpr := ParseSimpleExpression();
      if not Assigned(LHighExpr) then
      begin
        AddError('Expected expression for array upper bound');
        LLowExpr.Free();
        LNode.Free();
        LDimensions.Free();
        Exit(nil);
      end;
      
      // Store dimension as expression pair
      LDimensions.Add(TPair<TNPASTNode, TNPASTNode>.Create(LLowExpr, LHighExpr));
      
      // Check for additional dimensions
      if Match(tkComma) then
      begin
        Advance();
        Continue;
      end
      else
        Break;
    until False;
    
    LNode.Dimensions := LDimensions.ToArray();
    
    if not Expect(tkRBracket, 'Expected "]"') then
    begin
      LNode.Free();
      LDimensions.Free();
      Exit(nil);
    end;
    
    // Parse 'of' keyword
    if not Expect(tkOf, 'Expected "of"') then
    begin
      LNode.Free();
      LDimensions.Free();
      Exit(nil);
    end;
    
    // Parse element type
    LNode.ElementType := ParseType();
    
    Result := LNode;
  finally
    LDimensions.Free();
  end;
end;

function TNPParser.ParsePointerType(): TNPPointerNode;
var
  LNode: TNPPointerNode;
begin
  Advance(); // Skip '^'
  
  LNode := TNPPointerNode.Create(FCurrentToken.Position);
  LNode.BaseType := ParseType();
  
  Result := LNode;
end;

function TNPParser.ParseFunctionType(): TNPASTNode;
var
  LNode: TNPFunctionTypeNode;
  LIsFunction: Boolean;
begin
  LIsFunction := (FCurrentToken.Lexeme = 'function');
  Advance(); // Skip 'function' or 'procedure'
  
  LNode := TNPFunctionTypeNode.Create(FCurrentToken.Position);
  LNode.IsFunction := LIsFunction;
  
  if not Expect(tkLParen, 'Expected "("') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  if not Match(tkRParen) then
    LNode.Parameters := ParseParameters();
  
  if not Expect(tkRParen, 'Expected ")"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Return type for functions
  if LIsFunction then
  begin
    if not Expect(tkColon, 'Expected ":"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    LNode.ReturnType := ParseType();
  end;
  
  Result := LNode;
end;

function TNPParser.ParseParameters(): TNPASTNodeList;
var
  LList: TNPASTNodeList;
  LVariadicParam: TNPParameterNode;
begin
  LList := TNPASTNodeList.Create(True);
  
  repeat
    // Check for variadic parameter (...) 
    // Lexer produces tkDotDot (..) followed by tkDot (.)
    if Match(tkDotDot) then
    begin
      Advance();
      if Match(tkDot) then
      begin
        Advance();
        // Create variadic parameter marker
        LVariadicParam := TNPParameterNode.Create(FCurrentToken.Position);
        LVariadicParam.IsVariadic := True;
        LVariadicParam.Names := [];
        LVariadicParam.TypeNode := nil;
        LList.Add(LVariadicParam);
        Break; // Variadic must be last parameter
      end
      else
      begin
        // tkDotDot without following tkDot is an error in parameter list
        AddError('Unexpected ".."');
        LList.Free();
        Exit(nil);
      end;
    end;
    
    LList.Add(ParseParameter());
    if not Match(tkSemicolon) then
      Break;
    Advance();
  until False;
  
  Result := LList;
end;

function TNPParser.ParseParameter(): TNPParameterNode;
var
  LNode: TNPParameterNode;
  LNames: TList<string>;
  LModifier: string;
begin
  LNode := TNPParameterNode.Create(FCurrentToken.Position);
  LNames := TList<string>.Create();
  try
    // Optional modifier
    LModifier := '';
    if Match(tkConst) then
    begin
      LModifier := 'const';
      Advance();
    end
    else if Match(tkVar) then
    begin
      LModifier := 'var';
      Advance();
    end
    else if Match(tkIdentifier) and (FCurrentToken.Lexeme = 'out') then
    begin
      LModifier := 'out';
      Advance();
    end;
    
    LNode.Modifier := LModifier;
    
    // Parse identifier list
    repeat
      if not Match(tkIdentifier) then
      begin
        AddError('Expected parameter name');
        LNode.Free();
        Exit(nil);
      end;
      LNames.Add(FCurrentToken.Lexeme);
      Advance();
      if not Match(tkComma) then
        Break;
      Advance();
    until False;
    
    LNode.Names := LNames.ToArray();
    
    if not Expect(tkColon, 'Expected ":"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    
    LNode.TypeNode := ParseType();
    
    Result := LNode;
  finally
    LNames.Free();
  end;
end;

function TNPParser.ParseStatementSequence(): TNPASTNodeList;
var
  LList: TNPASTNodeList;
  LStmt: TNPASTNode;
begin
  LList := TNPASTNodeList.Create(True);
  
  while not Match(tkEnd) and not Match(tkUntil) and not Match(tkElse) and not Match(tkEOF) do
  begin
    if Match(tkSemicolon) then
    begin
      Advance();
      Continue;
    end;
    
    LStmt := ParseStatement();
    if Assigned(LStmt) then
      LList.Add(LStmt);
    
    if Match(tkSemicolon) then
      Advance();
  end;
  
  Result := LList;
end;

function TNPParser.ParseStatement(): TNPASTNode;
var
  LTarget: TNPASTNode;
  LNode: TNPASTNode;
begin
  if Match(tkBegin) then
    Result := ParseCompoundStatement()
  else if Match(tkIf) then
    Result := ParseIfStatement()
  else if Match(tkWhile) then
    Result := ParseWhileStatement()
  else if Match(tkRepeat) then
    Result := ParseRepeatStatement()
  else if Match(tkFor) then
    Result := ParseForStatement()
  else if Match(tkCase) then
    Result := ParseCaseStatement()
  else if Match(tkBreak) then
  begin
    LNode := TNPBreakNode.Create(FCurrentToken.Position);
    Advance();
    Result := LNode;
  end
  else if Match(tkContinue) then
  begin
    LNode := TNPContinueNode.Create(FCurrentToken.Position);
    Advance();
    Result := LNode;
  end
  else if Match(tkReturn) then
  begin
    LNode := TNPReturnNode.Create(FCurrentToken.Position);
    Advance();
    if not Match(tkSemicolon) and not Match(tkEnd) then
      TNPReturnNode(LNode).Value := ParseExpression();
    Result := LNode;
  end
  else if Match(tkHalt) then
  begin
    LNode := TNPHaltNode.Create(FCurrentToken.Position);
    Advance();
    if not Expect(tkLParen, 'Expected "("') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    TNPHaltNode(LNode).ExitCode := ParseExpression();
    if not Expect(tkRParen, 'Expected ")"') then
    begin
      LNode.Free();
      Exit(nil);
    end;
    Result := LNode;
  end
  else if Match(tkIdentifier) then
  begin
    LTarget := ParseDesignator();
    if Match(tkAssign) then
      Result := ParseAssignment(LTarget)
    else
      Result := LTarget; // Procedure call
  end
  else if Match(tkLParen) then
  begin
    LTarget := ParseFactor(); // ParseFactor handles parenthesized expressions with postfix ops
    if Match(tkAssign) then
      Result := ParseAssignment(LTarget)
    else
      Result := LTarget; // Procedure call
  end
  else
  begin
    AddError('Unexpected token: ' + FCurrentToken.Lexeme);
    Synchronize();
    Result := nil;
  end;
end;

function TNPParser.ParseCompoundStatement(): TNPCompoundNode;
var
  LNode: TNPCompoundNode;
begin
  Advance(); // Skip 'begin'
  
  LNode := TNPCompoundNode.Create(FCurrentToken.Position);
  LNode.Statements := ParseStatementSequence();
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseIfStatement(): TNPIfNode;
var
  LNode: TNPIfNode;
begin
  Advance(); // Skip 'if'
  
  LNode := TNPIfNode.Create(FCurrentToken.Position);
  LNode.Condition := ParseExpression();
  
  if not Expect(tkThen, 'Expected "then"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.ThenBranch := ParseStatement();
  
  if Match(tkElse) then
  begin
    Advance();
    LNode.ElseBranch := ParseStatement();
  end;
  
  Result := LNode;
end;

function TNPParser.ParseWhileStatement(): TNPWhileNode;
var
  LNode: TNPWhileNode;
begin
  Advance(); // Skip 'while'
  
  LNode := TNPWhileNode.Create(FCurrentToken.Position);
  LNode.Condition := ParseExpression();
  
  if not Expect(tkDo, 'Expected "do"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.Body := ParseStatement();
  
  Result := LNode;
end;

function TNPParser.ParseRepeatStatement(): TNPRepeatNode;
var
  LNode: TNPRepeatNode;
begin
  Advance(); // Skip 'repeat'
  
  LNode := TNPRepeatNode.Create(FCurrentToken.Position);
  LNode.Body := ParseStatementSequence();
  
  if not Expect(tkUntil, 'Expected "until"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.Condition := ParseExpression();
  
  Result := LNode;
end;

function TNPParser.ParseForStatement(): TNPForNode;
var
  LNode: TNPForNode;
begin
  Advance(); // Skip 'for'
  
  if not Match(tkIdentifier) then
  begin
    AddError('Expected loop variable');
    Exit(nil);
  end;
  
  LNode := TNPForNode.Create(FCurrentToken.Position);
  LNode.VarName := FCurrentToken.Lexeme;
  Advance();
  
  if not Expect(tkAssign, 'Expected ":="') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.StartValue := ParseExpression();
  
  if Match(tkTo) then
  begin
    LNode.IsDownto := False;
    Advance();
  end
  else if Match(tkDownto) then
  begin
    LNode.IsDownto := True;
    Advance();
  end
  else
  begin
    AddError('Expected "to" or "downto"');
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.EndValue := ParseExpression();
  
  if not Expect(tkDo, 'Expected "do"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  LNode.Body := ParseStatement();
  
  Result := LNode;
end;

function TNPParser.ParseCaseStatement(): TNPCaseNode;
var
  LNode: TNPCaseNode;
  LElement: TNPCaseElementNode;
begin
  Advance(); // Skip 'case'
  
  LNode := TNPCaseNode.Create(FCurrentToken.Position);
  LNode.Expression := ParseExpression();
  
  if not Expect(tkOf, 'Expected "of"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  // Parse case elements
  while not Match(tkElse) and not Match(tkEnd) and not Match(tkEOF) do
  begin
    LElement := TNPCaseElementNode.Create(FCurrentToken.Position);
    
    // Parse labels
    repeat
      LElement.Labels.Add(ParseExpression());
      if Match(tkDotDot) then
      begin
        Advance();
        LElement.Labels.Add(ParseExpression());
      end;
      if not Match(tkComma) then
        Break;
      Advance();
    until False;
    
    if not Expect(tkColon, 'Expected ":"') then
    begin
      LElement.Free();
      LNode.Free();
      Exit(nil);
    end;
    
    LElement.Statement := ParseStatement();
    LNode.Elements.Add(LElement);
    
    if Match(tkSemicolon) then
      Advance();
  end;
  
  // Optional else
  if Match(tkElse) then
  begin
    Advance();
    LNode.ElseStatements := ParseStatementSequence();
  end;
  
  if not Expect(tkEnd, 'Expected "end"') then
  begin
    LNode.Free();
    Exit(nil);
  end;
  
  Result := LNode;
end;

function TNPParser.ParseAssignment(ATarget: TNPASTNode): TNPAssignmentNode;
var
  LNode: TNPAssignmentNode;
begin
  Advance(); // Skip ':='
  
  LNode := TNPAssignmentNode.Create(FCurrentToken.Position);
  LNode.Target := ATarget;
  LNode.Value := ParseExpression();
  
  Result := LNode;
end;

function TNPParser.ParseExpression(): TNPASTNode;
var
  LLeft: TNPASTNode;
  LOp: TNPTokenKind;
  LRight: TNPASTNode;
  LNode: TNPBinaryOpNode;
begin
  LLeft := ParseSimpleExpression();
  
  // Relational operators
  if Match(tkEquals) or Match(tkNotEqual) or Match(tkLess) or 
     Match(tkLessEqual) or Match(tkGreater) or Match(tkGreaterEqual) then
  begin
    LOp := FCurrentToken.Kind;
    Advance();
    LRight := ParseSimpleExpression();
    
    LNode := TNPBinaryOpNode.Create(FCurrentToken.Position);
    LNode.Left := LLeft;
    LNode.Op := LOp;
    LNode.Right := LRight;
    Result := LNode;
  end
  else
    Result := LLeft;
end;

function TNPParser.ParseSimpleExpression(): TNPASTNode;
var
  LLeft: TNPASTNode;
  LOp: TNPTokenKind;
  LRight: TNPASTNode;
  LNode: TNPBinaryOpNode;
  LUnary: TNPUnaryOpNode;
begin
  // Optional unary +/-
  if Match(tkPlus) or Match(tkMinus) then
  begin
    LOp := FCurrentToken.Kind;
    Advance();
    LLeft := ParseTerm();
    
    LUnary := TNPUnaryOpNode.Create(FCurrentToken.Position);
    LUnary.Op := LOp;
    LUnary.Operand := LLeft;
    LLeft := LUnary;
  end
  else
    LLeft := ParseTerm();
  
  // Additive operators
  while Match(tkPlus) or Match(tkMinus) or Match(tkOr) or Match(tkXor) do
  begin
    LOp := FCurrentToken.Kind;
    Advance();
    LRight := ParseTerm();
    
    LNode := TNPBinaryOpNode.Create(FCurrentToken.Position);
    LNode.Left := LLeft;
    LNode.Op := LOp;
    LNode.Right := LRight;
    LLeft := LNode;
  end;
  
  Result := LLeft;
end;

function TNPParser.ParseTerm(): TNPASTNode;
var
  LLeft: TNPASTNode;
  LOp: TNPTokenKind;
  LRight: TNPASTNode;
  LNode: TNPBinaryOpNode;
begin
  LLeft := ParseFactor();
  
  // Multiplicative operators
  while Match(tkStar) or Match(tkSlash) or Match(tkDiv) or 
        Match(tkMod) or Match(tkAnd) or Match(tkShl) or Match(tkShr) do
  begin
    LOp := FCurrentToken.Kind;
    Advance();
    LRight := ParseFactor();
    
    LNode := TNPBinaryOpNode.Create(FCurrentToken.Position);
    LNode.Left := LLeft;
    LNode.Op := LOp;
    LNode.Right := LRight;
    LLeft := LNode;
  end;
  
  Result := LLeft;
end;

function TNPParser.ParseFactor(): TNPASTNode;
var
  LNode: TNPASTNode;
  LUnary: TNPUnaryOpNode;
  LArrayLit: TNPArrayLiteralNode;
  LFirstExpr: TNPASTNode;
  LSavedPos: TNPSourcePos;
  LFirstIdent: string;
  LRecordLit: TNPRecordLiteralNode;
  LFieldNames: TList<string>;
  LIdent: TNPIdentifierNode;
  LField: TNPFieldAccessNode;
  LFieldOrMethodName: string;
  LIndex: TNPIndexNode;
  LIndex2: TNPIndexNode;
  LDeref: TNPDerefNode;
  LOp: TNPTokenKind;
  LRight: TNPASTNode;
  LBinOp: TNPBinaryOpNode;
begin
  Result := nil;
  
  // Literals
  if Match(tkInteger) then
  begin
    LNode := TNPIntLiteralNode.Create(FCurrentToken.Position, FCurrentToken.Value.AsInt64);
    Advance();
    Result := LNode;
  end
  else if Match(tkFloat) then
  begin
    LNode := TNPFloatLiteralNode.Create(FCurrentToken.Position, FCurrentToken.Value.AsExtended);
    Advance();
    Result := LNode;
  end
  else if Match(tkString) then
  begin
    LNode := TNPStringLiteralNode.Create(FCurrentToken.Position, FCurrentToken.Value.AsString);
    Advance();
    Result := LNode;
  end
  else if Match(tkChar) then
  begin
    LNode := TNPCharLiteralNode.Create(FCurrentToken.Position, FCurrentToken.Value.AsString[1]);
    Advance();
    Result := LNode;
  end
  else if Match(tkTrue) or Match(tkFalse) then
  begin
    LNode := TNPBoolLiteralNode.Create(FCurrentToken.Position, Match(tkTrue));
    Advance();
    Result := LNode;
  end
  else if Match(tkNil) then
  begin
    LNode := TNPNilLiteralNode.Create(FCurrentToken.Position);
    Advance();
    Result := LNode;
  end
  else if Match(tkNot) or Match(tkAt) then
  begin
    LUnary := TNPUnaryOpNode.Create(FCurrentToken.Position);
    LUnary.Op := FCurrentToken.Kind;
    Advance();
    LUnary.Operand := ParseFactor();
    Result := LUnary;
  end
  else if Match(tkCaret) then
  begin
    // Check if this is a type cast: ^Type(expr)
    LSavedPos := FCurrentToken.Position;
    Advance(); // Skip '^'
    
    // Try to parse as type
    if Match(tkIdentifier) or Match(tkArray) or Match(tkCaret) or Match(tkRoutine) then
    begin
      var LBaseType: TNPASTNode := ParseType();
      
      // Wrap in pointer node since we consumed the '^'
      var LPointerType: TNPPointerNode := TNPPointerNode.Create(LSavedPos);
      LPointerType.BaseType := LBaseType;
      
      // Check if followed by '(' for type cast
      if Match(tkLParen) then
      begin
        Advance(); // Skip '('
        
        var LCastNode: TNPTypeCastNode := TNPTypeCastNode.Create(LSavedPos);
        LCastNode.TargetType := LPointerType;
        LCastNode.Expression := ParseExpression();
        
        if not Expect(tkRParen, 'Expected ")"') then
        begin
          LCastNode.Free();
          Exit(nil);
        end;
        
        Result := LCastNode;
      end
      else
      begin
        // Not a type cast, must be pointer type construction or error
        AddError('Expected "(" after type in type cast');
        LPointerType.Free();
        Exit(nil);
      end;
    end
    else
    begin
      AddError('Expected type after "^" in type cast');
      Exit(nil);
    end;
  end
  else if Match(tkLParen) then
  begin
    Advance();
    
    // Check for empty parens - treat as empty array literal
    if Match(tkRParen) then
    begin
      Advance();
      LArrayLit := TNPArrayLiteralNode.Create(FCurrentToken.Position);
      Result := LArrayLit;
      Exit;
    end;
    
    // First, try to parse as array literal or record literal based on first element
    // Save position for potential backtracking
    if Match(tkIdentifier) then
    begin
      LSavedPos := FCurrentToken.Position;
      LFirstIdent := FCurrentToken.Lexeme;
      Advance();
      
      // Check if this is a record literal (identifier: value)
      if Match(tkColon) then
      begin
        Advance();
        
        // This is a record literal
        LRecordLit := TNPRecordLiteralNode.Create(LSavedPos);
        LFieldNames := TList<string>.Create();
        try
          LFieldNames.Add(LFirstIdent);
          LRecordLit.FieldValues.Add(ParseExpression());
          
          while Match(tkSemicolon) do
          begin
            Advance();
            if Match(tkRParen) then
              Break;
            
            if not Match(tkIdentifier) then
            begin
              AddError('Expected field name');
              LRecordLit.Free();
              LFieldNames.Free();
              Exit(nil);
            end;
            
            LFieldNames.Add(FCurrentToken.Lexeme);
            Advance();
            
            if not Expect(tkColon, 'Expected ":"') then
            begin
              LRecordLit.Free();
              LFieldNames.Free();
              Exit(nil);
            end;
            
            LRecordLit.FieldValues.Add(ParseExpression());
          end;
          
          LRecordLit.FieldNames := LFieldNames.ToArray();
          
          if not Expect(tkRParen, 'Expected ")"') then
          begin
            LRecordLit.Free();
            LFieldNames.Free();
            Exit(nil);
          end;
          
          Result := LRecordLit;
        finally
          LFieldNames.Free();
        end;
        Exit;
      end;
      
      // Not a record literal, reconstruct the identifier and parse as expression
      LIdent := TNPIdentifierNode.Create(LSavedPos);
      LIdent.Name := LFirstIdent;
      LNode := LIdent;
      
      // Parse any suffixes (., [, ^, ())
      while True do
      begin
        if Match(tkDot) then
        begin
          Advance();
          if not Match(tkIdentifier) then
          begin
            AddError('Expected field or method name');
            LNode.Free();
            Exit(nil);
          end;
          
          LFieldOrMethodName := FCurrentToken.Lexeme;
          Advance();
          
          if Match(tkLParen) then
          begin
            LField := TNPFieldAccessNode.Create(FCurrentToken.Position);
            LField.RecordExpr := LNode;
            LField.FieldName := LFieldOrMethodName;
            LNode := ParseCallOrMethodCall(LField);
          end
          else
          begin
            LField := TNPFieldAccessNode.Create(FCurrentToken.Position);
            LField.RecordExpr := LNode;
            LField.FieldName := LFieldOrMethodName;
            LNode := LField;
          end;
        end
        else if Match(tkLBracket) then
        begin
          Advance();
          LIndex := TNPIndexNode.Create(FCurrentToken.Position);
          LIndex.ArrayExpr := LNode;
          LIndex.IndexExpr := ParseExpression();
          LNode := LIndex;
          
          while Match(tkComma) do
          begin
            Advance();
            LIndex2 := TNPIndexNode.Create(FCurrentToken.Position);
            LIndex2.ArrayExpr := LNode;
            LIndex2.IndexExpr := ParseExpression();
            LNode := LIndex2;
          end;
          
          if not Expect(tkRBracket, 'Expected "]"') then
          begin
            LNode.Free();
            Exit(nil);
          end;
        end
        else if Match(tkCaret) then
        begin
          Advance();
          LDeref := TNPDerefNode.Create(FCurrentToken.Position);
          LDeref.PointerExpr := LNode;
          LNode := LDeref;
        end
        else if Match(tkLParen) then
        begin
          LNode := ParseCallOrMethodCall(LNode);
        end
        else
          Break;
      end;
      
      // Check if this is part of array literal: (expr, expr, ...)
      if Match(tkComma) then
      begin
        // Array literal with multiple elements
        LArrayLit := TNPArrayLiteralNode.Create(FCurrentToken.Position);
        LArrayLit.Elements.Add(LNode);
        //LNode := nil; // Transfer ownership
        
        while Match(tkComma) do
        begin
          Advance();
          if Match(tkRParen) then
            Break;
          LArrayLit.Elements.Add(ParseExpression());
        end;
        
        if not Expect(tkRParen, 'Expected ")"') then
        begin
          LArrayLit.Free();
          Exit(nil);
        end;
        
        Result := LArrayLit;
        Exit;
      end;
      
      // Continue parsing rest of expression (operators, etc.)
      // Handle multiplicative operators
      while Match(tkStar) or Match(tkSlash) or Match(tkDiv) or 
            Match(tkMod) or Match(tkAnd) or Match(tkShl) or Match(tkShr) do
      begin
        LOp := FCurrentToken.Kind;
        Advance();
        LRight := ParseFactor();
        
        LBinOp := TNPBinaryOpNode.Create(FCurrentToken.Position);
        LBinOp.Left := LNode;
        LBinOp.Op := LOp;
        LBinOp.Right := LRight;
        LNode := LBinOp;
      end;
      
      // Handle additive operators
      while Match(tkPlus) or Match(tkMinus) or Match(tkOr) or Match(tkXor) do
      begin
        LOp := FCurrentToken.Kind;
        Advance();
        LRight := ParseTerm();
        
        LBinOp := TNPBinaryOpNode.Create(FCurrentToken.Position);
        LBinOp.Left := LNode;
        LBinOp.Op := LOp;
        LBinOp.Right := LRight;
        LNode := LBinOp;
      end;
      
      // Handle relational operators
      if Match(tkEquals) or Match(tkNotEqual) or Match(tkLess) or 
         Match(tkLessEqual) or Match(tkGreater) or Match(tkGreaterEqual) then
      begin
        LOp := FCurrentToken.Kind;
        Advance();
        LRight := ParseSimpleExpression();
        
        LBinOp := TNPBinaryOpNode.Create(FCurrentToken.Position);
        LBinOp.Left := LNode;
        LBinOp.Op := LOp;
        LBinOp.Right := LRight;
        LNode := LBinOp;
      end;
      
      if not Expect(tkRParen, 'Expected ")"') then
      begin
        if Assigned(LNode) then
          LNode.Free();
        Exit(nil);
      end;
      
      // Allow postfix operators on parenthesized expressions
      while Match(tkCaret) or Match(tkLBracket) or Match(tkDot) do
      begin
        if Match(tkCaret) then
        begin
          Advance();
          LDeref := TNPDerefNode.Create(FCurrentToken.Position);
          LDeref.PointerExpr := LNode;
          LNode := LDeref;
        end
        else if Match(tkLBracket) then
        begin
          Advance();
          LIndex := TNPIndexNode.Create(FCurrentToken.Position);
          LIndex.ArrayExpr := LNode;
          LIndex.IndexExpr := ParseExpression();
          LNode := LIndex;
          
          while Match(tkComma) do
          begin
            Advance();
            LIndex2 := TNPIndexNode.Create(FCurrentToken.Position);
            LIndex2.ArrayExpr := LNode;
            LIndex2.IndexExpr := ParseExpression();
            LNode := LIndex2;
          end;
          
          if not Expect(tkRBracket, 'Expected "]"') then
          begin
            LNode.Free();
            Exit(nil);
          end;
        end
        else if Match(tkDot) then
        begin
          Advance();
          if not Match(tkIdentifier) then
          begin
            AddError('Expected field name');
            LNode.Free();
            Exit(nil);
          end;
          
          LField := TNPFieldAccessNode.Create(FCurrentToken.Position);
          LField.RecordExpr := LNode;
          LField.FieldName := FCurrentToken.Lexeme;
          Advance();
          LNode := LField;
        end;
      end;
      
      Result := LNode;
      Exit;
    end;
    
    // Not identifier - parse as expression and check for array literal
    LFirstExpr := ParseExpression();
    
    if Match(tkComma) then
    begin
      // Array literal: (expr, expr, ...)
      LArrayLit := TNPArrayLiteralNode.Create(FCurrentToken.Position);
      LArrayLit.Elements.Add(LFirstExpr);
      //LFirstExpr := nil; // Transfer ownership
      
      while Match(tkComma) do
      begin
        Advance();
        if Match(tkRParen) then
          Break;
        LArrayLit.Elements.Add(ParseExpression());
      end;
      
      if not Expect(tkRParen, 'Expected ")"') then
      begin
        LArrayLit.Free();
        Exit(nil);
      end;
      
      Result := LArrayLit;
    end
    else
    begin
      // Single parenthesized expression
      if not Expect(tkRParen, 'Expected ")"') then
      begin
        if Assigned(LFirstExpr) then
          LFirstExpr.Free();
        Exit(nil);
      end;
      
      // Allow postfix operators on parenthesized expressions
      LNode := LFirstExpr;
      while Match(tkCaret) or Match(tkLBracket) or Match(tkDot) do
      begin
        if Match(tkCaret) then
        begin
          Advance();
          LDeref := TNPDerefNode.Create(FCurrentToken.Position);
          LDeref.PointerExpr := LNode;
          LNode := LDeref;
        end
        else if Match(tkLBracket) then
        begin
          Advance();
          LIndex := TNPIndexNode.Create(FCurrentToken.Position);
          LIndex.ArrayExpr := LNode;
          LIndex.IndexExpr := ParseExpression();
          LNode := LIndex;
          
          while Match(tkComma) do
          begin
            Advance();
            LIndex2 := TNPIndexNode.Create(FCurrentToken.Position);
            LIndex2.ArrayExpr := LNode;
            LIndex2.IndexExpr := ParseExpression();
            LNode := LIndex2;
          end;
          
          if not Expect(tkRBracket, 'Expected "]"') then
          begin
            LNode.Free();
            Exit(nil);
          end;
        end
        else if Match(tkDot) then
        begin
          Advance();
          if not Match(tkIdentifier) then
          begin
            AddError('Expected field name');
            LNode.Free();
            Exit(nil);
          end;
          
          LField := TNPFieldAccessNode.Create(FCurrentToken.Position);
          LField.RecordExpr := LNode;
          LField.FieldName := FCurrentToken.Lexeme;
          Advance();
          LNode := LField;
        end;
      end;
      
      Result := LNode;
    end;
  end
  else if Match(tkLBracket) then
  begin
    // Array literal with square brackets
    Advance();
    LArrayLit := TNPArrayLiteralNode.Create(FCurrentToken.Position);
    
    if not Match(tkRBracket) then
    begin
      repeat
        LArrayLit.Elements.Add(ParseExpression());
        if not Match(tkComma) then
          Break;
        Advance();
      until False;
    end;
    
    if not Expect(tkRBracket, 'Expected "]"') then
    begin
      LArrayLit.Free();
      Exit(nil);
    end;
    
    Result := LArrayLit;
  end
  else if Match(tkIdentifier) then
    Result := ParseDesignator()
  else
    AddError('Unexpected token in expression');
end;

function TNPParser.ParseDesignator(): TNPASTNode;
var
  LNode: TNPASTNode;
  LIdent: TNPIdentifierNode;
  LField: TNPFieldAccessNode;
  LIndex: TNPIndexNode;
  LDeref: TNPDerefNode;
  LFieldOrMethodName: string;
begin
  if not Match(tkIdentifier) then
  begin
    AddError('Expected identifier');
    Exit(nil);
  end;
  
  LIdent := TNPIdentifierNode.Create(FCurrentToken.Position);
  LIdent.Name := FCurrentToken.Lexeme;
  Advance();
  
  LNode := LIdent;
  
  // Handle selectors
  while True do
  begin
    if Match(tkDot) then
    begin
      Advance();
      if not Match(tkIdentifier) then
      begin
        AddError('Expected field or method name');
        LNode.Free();
        Exit(nil);
      end;
      
      // Save field/method name and advance
      LFieldOrMethodName := FCurrentToken.Lexeme;
      Advance();
      
      // Check for method call
      if Match(tkLParen) then
      begin
        // Build temporary field access node for method call parsing
        LField := TNPFieldAccessNode.Create(FCurrentToken.Position);
        LField.RecordExpr := LNode;
        LField.FieldName := LFieldOrMethodName;
        LNode := ParseCallOrMethodCall(LField);
      end
      else
      begin
        LField := TNPFieldAccessNode.Create(FCurrentToken.Position);
        LField.RecordExpr := LNode;
        LField.FieldName := LFieldOrMethodName;
        LNode := LField;
      end;
    end
    else if Match(tkLBracket) then
    begin
      Advance();
      
      // Parse first index
      LIndex := TNPIndexNode.Create(FCurrentToken.Position);
      LIndex.ArrayExpr := LNode;
      LIndex.IndexExpr := ParseExpression();
      LNode := LIndex;
      
      // Handle comma-separated indices (multi-dimensional arrays)
      while Match(tkComma) do
      begin
        Advance();
        LIndex := TNPIndexNode.Create(FCurrentToken.Position);
        LIndex.ArrayExpr := LNode;
        LIndex.IndexExpr := ParseExpression();
        LNode := LIndex;
      end;
      
      if not Expect(tkRBracket, 'Expected "]"') then
      begin
        LNode.Free();
        Exit(nil);
      end;
    end
    else if Match(tkCaret) then
    begin
      Advance();
      LDeref := TNPDerefNode.Create(FCurrentToken.Position);
      LDeref.PointerExpr := LNode;
      LNode := LDeref;
    end
    else if Match(tkLParen) then
    begin
      LNode := ParseCallOrMethodCall(LNode);
    end
    else
      Break;
  end;
  
  Result := LNode;
end;

function TNPParser.ParseCallOrMethodCall(ACallee: TNPASTNode): TNPASTNode;
var
  LCall: TNPCallNode;
  LMethodCall: TNPMethodCallNode;
  LField: TNPFieldAccessNode;
begin
  // Check if this is a method call (obj.method())
  if ACallee is TNPFieldAccessNode then
  begin
    LField := TNPFieldAccessNode(ACallee);
    LMethodCall := TNPMethodCallNode.Create(FCurrentToken.Position);
    LMethodCall.ObjectExpr := LField.RecordExpr;
    LMethodCall.MethodName := LField.FieldName;
    LField.RecordExpr := nil; // Transfer ownership
    LField.Free();
    
    if not Expect(tkLParen, 'Expected "("') then
    begin
      LMethodCall.Free();
      Exit(nil);
    end;
    
    if not Match(tkRParen) then
      LMethodCall.Arguments := ParseArgumentList();
    
    if not Expect(tkRParen, 'Expected ")"') then
    begin
      LMethodCall.Free();
      Exit(nil);
    end;
    
    Result := LMethodCall;
  end
  else
  begin
    // Regular function call
    LCall := TNPCallNode.Create(FCurrentToken.Position);
    LCall.Callee := ACallee;
    
    if not Expect(tkLParen, 'Expected "("') then
    begin
      LCall.Free();
      Exit(nil);
    end;
    
    if not Match(tkRParen) then
      LCall.Arguments := ParseArgumentList();
    
    if not Expect(tkRParen, 'Expected ")"') then
    begin
      LCall.Free();
      Exit(nil);
    end;
    
    Result := LCall;
  end;
end;

function TNPParser.ParseArgumentList(): TNPASTNodeList;
var
  LList: TNPASTNodeList;
begin
  LList := TNPASTNodeList.Create(True);
  
  repeat
    LList.Add(ParseExpression());
    if not Match(tkComma) then
      Break;
    Advance();
  until False;
  
  Result := LList;
end;

function TNPParser.HasErrors(): Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPParser.GetErrors(): TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

function TNPParser.GetDirectives(): TDictionary<string, string>;
begin
  Result := FDirectives;
end;

end.
