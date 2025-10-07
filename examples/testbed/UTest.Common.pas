{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Common;

interface

uses
  System.SysUtils,
  System.TypInfo,
  NitroPascal.Types,
  NitroPascal.Lexer,
  NitroPascal.Parser,
  NitroPascal.Compiler;

procedure RunLexerTest(const ATestName, ASource: string);
procedure RunParserTest(const ATestName, ASource: string);
procedure RunParserTestWithVerify(const ATestName, ASource: string; AVerifyProc: TProc<TNPASTNode>);
procedure RunCompilerTest(const ATestName, ASource: string);

function InferCompilationMode(const ASource: string): TNPCompilationMode;

// AST Verification Helpers
function FindNodeByKind(ARoot: TNPASTNode; AKind: TNPNodeKind): TNPASTNode;
function GetProgramNode(ARoot: TNPASTNode): TNPProgramNode;
function GetModuleNode(ARoot: TNPASTNode): TNPModuleNode;
procedure AssertNodeKind(ANode: TNPASTNode; AExpected: TNPNodeKind; const AMsg: string);
procedure AssertNotNil(ANode: TNPASTNode; const AMsg: string);
procedure AssertIdentifierName(ANode: TNPASTNode; const AExpected: string; const AMsg: string);
procedure AssertIntValue(ANode: TNPASTNode; AExpected: Int64; const AMsg: string);
procedure AssertBinaryOp(ANode: TNPASTNode; AExpectedOp: TNPTokenKind; const AMsg: string);

implementation

uses
  System.IOUtils,
  NitroPascal.Utils;

function InferCompilationMode(const ASource: string): TNPCompilationMode;
begin
  // Simple heuristic: check first non-whitespace keyword
  if ASource.TrimLeft().StartsWith('program') then
    Result := cmProgram
  else if ASource.TrimLeft().StartsWith('module') then
    Result := cmModule
  else if ASource.TrimLeft().StartsWith('library') then
    Result := cmLibrary
  else
    Result := cmProgram; // Default
end;

{ AST Verification Helpers }

function FindNodeByKind(ARoot: TNPASTNode; AKind: TNPNodeKind): TNPASTNode;
var
  LNode: TNPASTNode;
begin
  Result := nil;
  
  if not Assigned(ARoot) then
    Exit;
  
  if ARoot.Kind = AKind then
    Exit(ARoot);
  
  // Search in common list properties
  if ARoot is TNPProgramNode then
  begin
    for LNode in TNPProgramNode(ARoot).Declarations do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
    for LNode in TNPProgramNode(ARoot).MainBlock do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
  end
  else if ARoot is TNPModuleNode then
  begin
    for LNode in TNPModuleNode(ARoot).Declarations do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
  end
  else if ARoot is TNPAssignmentNode then
  begin
    Result := FindNodeByKind(TNPAssignmentNode(ARoot).Target, AKind);
    if Assigned(Result) then
      Exit;
    Result := FindNodeByKind(TNPAssignmentNode(ARoot).Value, AKind);
  end
  else if ARoot is TNPBinaryOpNode then
  begin
    Result := FindNodeByKind(TNPBinaryOpNode(ARoot).Left, AKind);
    if Assigned(Result) then
      Exit;
    Result := FindNodeByKind(TNPBinaryOpNode(ARoot).Right, AKind);
  end
  else if ARoot is TNPUnaryOpNode then
  begin
    Result := FindNodeByKind(TNPUnaryOpNode(ARoot).Operand, AKind);
  end
  else if ARoot is TNPIfNode then
  begin
    Result := FindNodeByKind(TNPIfNode(ARoot).Condition, AKind);
    if Assigned(Result) then
      Exit;
    Result := FindNodeByKind(TNPIfNode(ARoot).ThenBranch, AKind);
    if Assigned(Result) then
      Exit;
    if Assigned(TNPIfNode(ARoot).ElseBranch) then
      Result := FindNodeByKind(TNPIfNode(ARoot).ElseBranch, AKind);
  end
  else if ARoot is TNPWhileNode then
  begin
    Result := FindNodeByKind(TNPWhileNode(ARoot).Condition, AKind);
    if Assigned(Result) then
      Exit;
    Result := FindNodeByKind(TNPWhileNode(ARoot).Body, AKind);
  end
  else if ARoot is TNPForNode then
  begin
    Result := FindNodeByKind(TNPForNode(ARoot).StartValue, AKind);
    if Assigned(Result) then
      Exit;
    Result := FindNodeByKind(TNPForNode(ARoot).EndValue, AKind);
    if Assigned(Result) then
      Exit;
    Result := FindNodeByKind(TNPForNode(ARoot).Body, AKind);
  end
  else if ARoot is TNPRoutineDeclNode then
  begin
    for LNode in TNPRoutineDeclNode(ARoot).Parameters do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
    for LNode in TNPRoutineDeclNode(ARoot).LocalVars do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
    for LNode in TNPRoutineDeclNode(ARoot).Body do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
  end
  else if ARoot is TNPReturnNode then
  begin
    if Assigned(TNPReturnNode(ARoot).Value) then
      Result := FindNodeByKind(TNPReturnNode(ARoot).Value, AKind);
  end
  else if ARoot is TNPCallNode then
  begin
    Result := FindNodeByKind(TNPCallNode(ARoot).Callee, AKind);
    if Assigned(Result) then
      Exit;
    for LNode in TNPCallNode(ARoot).Arguments do
    begin
      Result := FindNodeByKind(LNode, AKind);
      if Assigned(Result) then
        Exit;
    end;
  end;
end;

function GetProgramNode(ARoot: TNPASTNode): TNPProgramNode;
begin
  if ARoot is TNPProgramNode then
    Result := TNPProgramNode(ARoot)
  else
    Result := nil;
end;

function GetModuleNode(ARoot: TNPASTNode): TNPModuleNode;
begin
  if ARoot is TNPModuleNode then
    Result := TNPModuleNode(ARoot)
  else
    Result := nil;
end;

procedure AssertNotNil(ANode: TNPASTNode; const AMsg: string);
begin
  if not Assigned(ANode) then
    raise Exception.Create('ASSERTION FAILED: ' + AMsg + ' - Node is nil');
end;

procedure AssertNodeKind(ANode: TNPASTNode; AExpected: TNPNodeKind; const AMsg: string);
begin
  AssertNotNil(ANode, AMsg);
  if ANode.Kind <> AExpected then
    raise Exception.CreateFmt('ASSERTION FAILED: %s - Expected %s but got %s', 
      [AMsg, GetEnumName(TypeInfo(TNPNodeKind), Ord(AExpected)), 
       GetEnumName(TypeInfo(TNPNodeKind), Ord(ANode.Kind))]);
end;

procedure AssertIdentifierName(ANode: TNPASTNode; const AExpected: string; const AMsg: string);
begin
  AssertNotNil(ANode, AMsg);
  AssertNodeKind(ANode, nkIdentifier, AMsg + ' - Expected identifier node');
  
  if TNPIdentifierNode(ANode).Name <> AExpected then
    raise Exception.CreateFmt('ASSERTION FAILED: %s - Expected identifier "%s" but got "%s"',
      [AMsg, AExpected, TNPIdentifierNode(ANode).Name]);
end;

procedure AssertIntValue(ANode: TNPASTNode; AExpected: Int64; const AMsg: string);
begin
  AssertNotNil(ANode, AMsg);
  AssertNodeKind(ANode, nkIntLiteral, AMsg + ' - Expected integer literal');
  
  if TNPIntLiteralNode(ANode).Value <> AExpected then
    raise Exception.CreateFmt('ASSERTION FAILED: %s - Expected %d but got %d',
      [AMsg, AExpected, TNPIntLiteralNode(ANode).Value]);
end;

procedure AssertBinaryOp(ANode: TNPASTNode; AExpectedOp: TNPTokenKind; const AMsg: string);
begin
  AssertNotNil(ANode, AMsg);
  AssertNodeKind(ANode, nkBinary, AMsg + ' - Expected binary operation');
  
  if TNPBinaryOpNode(ANode).Op <> AExpectedOp then
    raise Exception.CreateFmt('ASSERTION FAILED: %s - Expected operator %s but got %s',
      [AMsg, GetEnumName(TypeInfo(TNPTokenKind), Ord(AExpectedOp)),
       GetEnumName(TypeInfo(TNPTokenKind), Ord(TNPBinaryOpNode(ANode).Op))]);
end;

procedure RunLexerTest(const ATestName, ASource: string);
var
  LLexer: TNPLexer;
  LToken: TNPToken;
  LCount: Integer;
begin
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn('=== ' + ATestName + ' ===');
  TNPUtils.PrintLn('');
  
  LLexer := TNPLexer.Create(ASource, 'test.np');
  try
    LCount := 0;
    repeat
      LToken := LLexer.NextToken();
      Inc(LCount);
      TNPUtils.PrintLn(Format('[%3d] %s', [LCount, LToken.ToString()]));
    until LToken.Kind = tkEOF;
    
    if LLexer.HasErrors() then
    begin
      TNPUtils.PrintLn('');
      TNPUtils.PrintLn('ERRORS:');
      for var LError in LLexer.GetErrors() do
        TNPUtils.PrintLn('  ' + LError.ToString());
    end
    else
      TNPUtils.PrintLn('✓ No errors');
  finally
    LLexer.Free();
  end;
end;

procedure RunParserTest(const ATestName, ASource: string);
var
  LLexer: TNPLexer;
  LParser: TNPParser;
  LAST: TNPASTNode;
begin
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn('=== ' + ATestName + ' ===');
  TNPUtils.PrintLn('');
  
  LLexer := TNPLexer.Create(ASource, 'test.np');
  try
    LParser := TNPParser.Create(LLexer);
    try
      LAST := LParser.Parse(InferCompilationMode(ASource));
      
      if LParser.HasErrors() then
      begin
        TNPUtils.PrintLn('ERRORS:');
        for var LError in LParser.GetErrors() do
          TNPUtils.PrintLn('  ' + LError.ToString());
      end
      else
      begin
        TNPUtils.PrintLn('✓ Parse successful');
        if Assigned(LAST) then
        begin
          TNPUtils.PrintLn(Format('Root node: %s', [GetEnumName(TypeInfo(TNPNodeKind), Ord(LAST.Kind))]));
        end;
      end;
      
      if Assigned(LAST) then
        LAST.Free();
    finally
      LParser.Free();
    end;
  finally
    LLexer.Free();
  end;
end;

procedure RunParserTestWithVerify(const ATestName, ASource: string; AVerifyProc: TProc<TNPASTNode>);
var
  LLexer: TNPLexer;
  LParser: TNPParser;
  LAST: TNPASTNode;
  //LSuccess: Boolean;
begin
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn('=== ' + ATestName + ' ===');
  TNPUtils.PrintLn('');
  
  //LSuccess := False;
  LLexer := TNPLexer.Create(ASource, 'test.np');
  try
    LParser := TNPParser.Create(LLexer);
    try
      LAST := LParser.Parse(InferCompilationMode(ASource));
      
      if LParser.HasErrors() then
      begin
        TNPUtils.PrintLn('❌ PARSE ERRORS:');
        for var LError in LParser.GetErrors() do
          TNPUtils.PrintLn('  ' + LError.ToString());
      end
      else if not Assigned(LAST) then
      begin
        TNPUtils.PrintLn('❌ FAILED: Parser returned nil AST');
      end
      else
      begin
        try
          // Run verification
          AVerifyProc(LAST);
          TNPUtils.PrintLn('✓ All assertions passed');
          //LSuccess := True;
        except
          on E: Exception do
          begin
            TNPUtils.PrintLn('❌ ' + E.Message);
          end;
        end;
      end;
      
      if Assigned(LAST) then
        LAST.Free();
    finally
      LParser.Free();
    end;
  finally
    LLexer.Free();
  end;
end;

procedure RunCompilerTest(const ATestName, ASource: string);
var
  LCompiler: TNPCompiler;
  LFiles: TArray<TNPGeneratedFile>;
  LFile: TNPGeneratedFile;
  LTempFile: string;
  LSuccess: Boolean;
begin
  TNPUtils.PrintLn('');
  TNPUtils.PrintLn('=== ' + ATestName + ' ===');
  TNPUtils.PrintLn('');
  
  LCompiler := TNPCompiler.Create();
  try
    // Write source to temp file
    LTempFile := TPath.Combine(TPath.GetTempPath(), 'nitropascal_test_' + TPath.GetGUIDFileName() + '.np');
    try
      TFile.WriteAllText(LTempFile, ASource);
      
      TNPUtils.PrintLn('Source:');
      TNPUtils.PrintLn(ASource);
      TNPUtils.PrintLn('');
      
      // Compile the file
      LSuccess := LCompiler.CompileFromFile(LTempFile);
      
      if LCompiler.HasErrors() then
      begin
        TNPUtils.PrintLn('❌ COMPILATION ERRORS:');
        for var LError in LCompiler.GetErrors() do
          TNPUtils.PrintLn('  ' + LError.ToString());
      end
      else if not LSuccess then
      begin
        TNPUtils.PrintLn('❌ Compilation failed (unknown error)');
      end
      else
      begin
        LFiles := LCompiler.GetGeneratedFiles();
        if Length(LFiles) > 0 then
        begin
          TNPUtils.PrintLn('✓ Compilation successful');
          TNPUtils.PrintLn(Format('Generated %d files:', [Length(LFiles)]));
          TNPUtils.PrintLn('');
          
          for LFile in LFiles do
          begin
            TNPUtils.PrintLn('--- ' + LFile.Filename + ' ---');
            TNPUtils.PrintLn(LFile.Content);
            TNPUtils.PrintLn('');
          end;
        end
        else
          TNPUtils.PrintLn('❌ No files generated');
      end;
      
    finally
      // Clean up temp file
      if TFile.Exists(LTempFile) then
        TFile.Delete(LTempFile);
    end;
  finally
    LCompiler.Free();
  end;
end;

end.
