{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  NitroPascal.Types,
  NitroPascal.Symbols;

type
  { TNPCodeGenerator }
  TNPCodeGenerator = class
  private
    FErrors: TList<TNPError>;
    FHeaderCode: TStringBuilder;
    FImplCode: TStringBuilder;
    FIndentLevel: Integer;
    FCurrentModule: string;
    FIsLibrary: Boolean;
    FSymbolTable: TNPSymbolTable;
    
    procedure AddError(const APos: TNPSourcePos; const AMsg: string);
    procedure Indent();
    procedure Dedent();
    function GetIndent(): string;
    
    procedure EmitHeader(const ALine: string);
    procedure EmitImpl(const ALine: string);
    
    procedure EmitProgram(ANode: TNPProgramNode);
    procedure EmitModule(ANode: TNPModuleNode);
    procedure EmitLibrary(ANode: TNPLibraryNode);
    
    procedure EmitDeclarations(ADecls: TNPASTNodeList; AIsHeader: Boolean);
    procedure EmitImport(ANode: TNPImportNode);
    procedure EmitExtern(ANode: TNPExternNode; AIsHeader: Boolean);
    procedure EmitTypeDecl(ANode: TNPTypeDeclNode; AIsHeader: Boolean);
    procedure EmitConstDecl(ANode: TNPConstDeclNode; AIsHeader: Boolean);
    procedure EmitVarDecl(ANode: TNPVarDeclNode; AIsHeader: Boolean);
    procedure EmitRoutineDecl(ANode: TNPRoutineDeclNode; AIsHeader: Boolean);
    
    function EmitType(ANode: TNPASTNode): string;
    function EmitRecordType(ANode: TNPRecordNode; const ATypeName: string = ''): string;
    function EmitEnumType(ANode: TNPEnumNode): string;
    function EmitArrayType(ANode: TNPArrayNode): string;
    function EmitPointerType(ANode: TNPPointerNode): string;
    
    procedure EmitStatements(AStmts: TNPASTNodeList);
    procedure EmitStatement(ANode: TNPASTNode);
    procedure EmitCompound(ANode: TNPCompoundNode);
    procedure EmitAssignment(ANode: TNPAssignmentNode);
    procedure EmitIf(ANode: TNPIfNode);
    procedure EmitWhile(ANode: TNPWhileNode);
    procedure EmitRepeat(ANode: TNPRepeatNode);
    procedure EmitFor(ANode: TNPForNode);
    procedure EmitCase(ANode: TNPCaseNode);
    
    function EmitExpression(ANode: TNPASTNode): string;
    function EmitBinaryOp(ANode: TNPBinaryOpNode): string;
    function EmitUnaryOp(ANode: TNPUnaryOpNode): string;
    function EmitCall(ANode: TNPCallNode): string;
    function EmitMethodCall(ANode: TNPMethodCallNode): string;
    function EmitTypeCast(ANode: TNPTypeCastNode): string;
    function EmitArrayLiteral(ANode: TNPArrayLiteralNode): string;
    function EmitRecordLiteral(ANode: TNPRecordLiteralNode): string;

    function EscapeString(const AStr: string): string;
    {$HINTS OFF}
    function MapOperator(AKind: TNPTokenKind): string;
    {$HINTS ON}
    function IsIntegerExpression(ANode: TNPASTNode): Boolean;
    function MapBinaryOperator(AKind: TNPTokenKind; AIsInteger: Boolean): string;
    function MapUnaryOperator(AKind: TNPTokenKind; AIsInteger: Boolean): string;
    
  public
    constructor Create(const ASymbolTable: TNPSymbolTable);
    destructor Destroy; override;
    
    function Generate(ARoot: TNPASTNode; const AModuleName: string): Boolean;
    
    function GetHeaderCode(): string;
    function GetImplementationCode(): string;
    
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
    
    procedure Clear();
  end;

implementation

{ TNPCodeGenerator }

constructor TNPCodeGenerator.Create(const ASymbolTable: TNPSymbolTable);
begin
  inherited Create();
  FErrors := TList<TNPError>.Create();
  FHeaderCode := TStringBuilder.Create();
  FImplCode := TStringBuilder.Create();
  FIndentLevel := 0;
  FSymbolTable := ASymbolTable;
end;

destructor TNPCodeGenerator.Destroy;
begin
  FErrors.Free();
  FHeaderCode.Free();
  FImplCode.Free();
  inherited;
end;

procedure TNPCodeGenerator.AddError(const APos: TNPSourcePos; const AMsg: string);
begin
  FErrors.Add(TNPError.Create(APos, AMsg));
end;

procedure TNPCodeGenerator.Indent();
begin
  Inc(FIndentLevel);
end;

procedure TNPCodeGenerator.Dedent();
begin
  if FIndentLevel > 0 then
    Dec(FIndentLevel);
end;

function TNPCodeGenerator.GetIndent(): string;
begin
  Result := ''.PadLeft(FIndentLevel * 2);
end;

procedure TNPCodeGenerator.EmitHeader(const ALine: string);
begin
  FHeaderCode.AppendLine(ALine);
end;

procedure TNPCodeGenerator.EmitImpl(const ALine: string);
begin
  FImplCode.AppendLine(ALine);
end;

function TNPCodeGenerator.Generate(ARoot: TNPASTNode; const AModuleName: string): Boolean;
begin
  FErrors.Clear();
  FHeaderCode.Clear();
  FImplCode.Clear();
  FIndentLevel := 0;
  FCurrentModule := AModuleName;
  
  if ARoot is TNPProgramNode then
    EmitProgram(TNPProgramNode(ARoot))
  else if ARoot is TNPModuleNode then
    EmitModule(TNPModuleNode(ARoot))
  else if ARoot is TNPLibraryNode then
    EmitLibrary(TNPLibraryNode(ARoot))
  else
  begin
    AddError(TNPSourcePos.Create('', 0, 0), 'Unknown root node type');
    Exit(False);
  end;
  
  Result := not HasErrors();
end;

procedure TNPCodeGenerator.EmitProgram(ANode: TNPProgramNode);
begin
  FIsLibrary := False;
  
  // Generate header
  EmitHeader('#pragma once');
  EmitHeader('#include <cstdint>');
  EmitHeader('#include <string>');
  EmitHeader('');
  
  // Emit declarations in header
  EmitDeclarations(ANode.Declarations, True);
  
  // Generate implementation
  EmitImpl('#include <cstdint>');
  EmitImpl('#include <string>');
  EmitImpl('');
  
  // Emit declarations in implementation
  EmitDeclarations(ANode.Declarations, False);
  
  // Emit main function
  EmitImpl('');
  EmitImpl('int main() {');
  Indent();
  EmitImpl(GetIndent() + 'int ExitCode = 0;');
  EmitImpl('');
  
  // Emit main block statements
  EmitStatements(ANode.MainBlock);
  
  EmitImpl('');
  EmitImpl(GetIndent() + 'return ExitCode;');
  Dedent();
  EmitImpl('}');
end;

procedure TNPCodeGenerator.EmitModule(ANode: TNPModuleNode);
begin
  FIsLibrary := False;
  
  // Generate header
  EmitHeader('#pragma once');
  EmitHeader('#include <cstdint>');
  EmitHeader('#include <string>');
  EmitHeader('');
  
  // Emit public declarations in header
  EmitDeclarations(ANode.Declarations, True);
  
  // Generate implementation
  EmitImpl('#include "' + FCurrentModule + '.h"');
  EmitImpl('#include <cstdint>');
  EmitImpl('#include <string>');
  EmitImpl('');
  
  // Emit all declarations in implementation
  EmitDeclarations(ANode.Declarations, False);
end;

procedure TNPCodeGenerator.EmitLibrary(ANode: TNPLibraryNode);
begin
  FIsLibrary := True;
  
  // Generate header
  EmitHeader('#pragma once');
  EmitHeader('#include <cstdint>');
  EmitHeader('#include <string>');
  EmitHeader('');
  EmitHeader('#ifdef _WIN32');
  EmitHeader('  #define DLLEXPORT __declspec(dllexport)');
  EmitHeader('#else');
  EmitHeader('  #define DLLEXPORT __attribute__((visibility("default")))');
  EmitHeader('#endif');
  EmitHeader('');
  EmitHeader('extern "C" {');
  EmitHeader('');
  
  // Emit public declarations in header
  EmitDeclarations(ANode.Declarations, True);
  
  EmitHeader('');
  EmitHeader('}');
  
  // Generate implementation
  EmitImpl('#include "' + FCurrentModule + '.h"');
  EmitImpl('#include <cstdint>');
  EmitImpl('#include <string>');
  EmitImpl('');
  
  // Emit all declarations in implementation
  EmitDeclarations(ANode.Declarations, False);
  
  // Emit init/finalize blocks
  if (ANode.InitBlock.Count > 0) or (ANode.FinalizeBlock.Count > 0) then
  begin
    EmitImpl('');
    EmitImpl('#ifdef _WIN32');
    EmitImpl('#include <windows.h>');
    EmitImpl('BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {');
    Indent();
    
    if ANode.InitBlock.Count > 0 then
    begin
      EmitImpl(GetIndent() + 'if (fdwReason == DLL_PROCESS_ATTACH) {');
      Indent();
      EmitStatements(ANode.InitBlock);
      Dedent();
      EmitImpl(GetIndent() + '}');
    end;
    
    if ANode.FinalizeBlock.Count > 0 then
    begin
      EmitImpl(GetIndent() + 'if (fdwReason == DLL_PROCESS_DETACH) {');
      Indent();
      EmitStatements(ANode.FinalizeBlock);
      Dedent();
      EmitImpl(GetIndent() + '}');
    end;
    
    EmitImpl(GetIndent() + 'return TRUE;');
    Dedent();
    EmitImpl('}');
    EmitImpl('#else');
    
    if ANode.InitBlock.Count > 0 then
    begin
      EmitImpl('__attribute__((constructor))');
      EmitImpl('static void _lib_init() {');
      Indent();
      EmitStatements(ANode.InitBlock);
      Dedent();
      EmitImpl('}');
    end;
    
    if ANode.FinalizeBlock.Count > 0 then
    begin
      EmitImpl('__attribute__((destructor))');
      EmitImpl('static void _lib_fini() {');
      Indent();
      EmitStatements(ANode.FinalizeBlock);
      Dedent();
      EmitImpl('}');
    end;
    
    EmitImpl('#endif');
  end;
end;

procedure TNPCodeGenerator.EmitDeclarations(ADecls: TNPASTNodeList; AIsHeader: Boolean);
var
  LNode: TNPASTNode;
begin
  for LNode in ADecls do
  begin
    if LNode is TNPImportNode then
      EmitImport(TNPImportNode(LNode))
    else if LNode is TNPExternNode then
      EmitExtern(TNPExternNode(LNode), AIsHeader)
    else if LNode is TNPTypeDeclNode then
      EmitTypeDecl(TNPTypeDeclNode(LNode), AIsHeader)
    else if LNode is TNPConstDeclNode then
      EmitConstDecl(TNPConstDeclNode(LNode), AIsHeader)
    else if LNode is TNPVarDeclNode then
      EmitVarDecl(TNPVarDeclNode(LNode), AIsHeader)
    else if LNode is TNPRoutineDeclNode then
      EmitRoutineDecl(TNPRoutineDeclNode(LNode), AIsHeader);
  end;
end;

procedure TNPCodeGenerator.EmitImport(ANode: TNPImportNode);
begin
  // Imports become includes in header
  EmitHeader('#include "' + ANode.ModuleName + '.h"');
end;

procedure TNPCodeGenerator.EmitExtern(ANode: TNPExternNode; AIsHeader: Boolean);
var
  LParam: TNPASTNode;
  LParamNode: TNPParameterNode;
  LParams: TStringBuilder;
  LI: Integer;
begin
  if not AIsHeader then
    Exit;
  
  LParams := TStringBuilder.Create();
  try
    // Build parameter list
    for LI := 0 to ANode.Parameters.Count - 1 do
    begin
      LParam := ANode.Parameters[LI];
      if LParam is TNPParameterNode then
      begin
        LParamNode := TNPParameterNode(LParam);
        
        // Handle variadic parameters
        if LParamNode.IsVariadic then
        begin
          if LI > 0 then
            LParams.Append(', ');
          LParams.Append('...');
          Continue;
        end;
        
        if LI > 0 then
          LParams.Append(', ');
        
        // Map parameter type
        if LParamNode.Modifier = 'var' then
          LParams.Append(EmitType(LParamNode.TypeNode) + '& ')
        else if LParamNode.Modifier = 'const' then
          LParams.Append('const ' + EmitType(LParamNode.TypeNode) + ' ')
        else
          LParams.Append(EmitType(LParamNode.TypeNode) + ' ');
        
        // Use first name only
        if System.Length(LParamNode.Names) > 0 then
          LParams.Append(LParamNode.Names[0]);
      end;
    end;
    
    // Emit extern declaration
    if ANode.Source.StartsWith('<') then
    begin
      EmitHeader('#include ' + ANode.Source);
    end
    else if not ANode.IsDLL then
    begin
      EmitHeader('#include ' + ANode.Source);
    end;
    
    EmitHeader('extern "C" {');
    
    if Assigned(ANode.ReturnType) then
      EmitHeader('  ' + EmitType(ANode.ReturnType) + ' ' + ANode.RoutineName + '(' + LParams.ToString() + ');')
    else
      EmitHeader('  void ' + ANode.RoutineName + '(' + LParams.ToString() + ');');
    
    EmitHeader('}');
    EmitHeader('');
  finally
    LParams.Free();
  end;
end;

procedure TNPCodeGenerator.EmitTypeDecl(ANode: TNPTypeDeclNode; AIsHeader: Boolean);
begin
  if not AIsHeader then
    Exit;
  
  if ANode.TypeDef is TNPRecordNode then
    EmitHeader(EmitRecordType(TNPRecordNode(ANode.TypeDef), ANode.TypeName))
  else if ANode.TypeDef is TNPEnumNode then
    EmitHeader(EmitEnumType(TNPEnumNode(ANode.TypeDef)))
  else if ANode.TypeDef is TNPArrayNode then
    EmitHeader('using ' + ANode.TypeName + ' = ' + EmitArrayType(TNPArrayNode(ANode.TypeDef)) + ';')
  else if ANode.TypeDef is TNPPointerNode then
    EmitHeader('using ' + ANode.TypeName + ' = ' + EmitPointerType(TNPPointerNode(ANode.TypeDef)) + ';')
  else if ANode.TypeDef is TNPIdentifierNode then
    EmitHeader('using ' + ANode.TypeName + ' = ' + TNPIdentifierNode(ANode.TypeDef).Name + ';');
  
  EmitHeader('');
end;

procedure TNPCodeGenerator.EmitConstDecl(ANode: TNPConstDeclNode; AIsHeader: Boolean);
var
  LType: string;
begin
  if Assigned(ANode.TypeNode) then
    LType := EmitType(ANode.TypeNode)
  else
    LType := 'auto';
  
  if AIsHeader then
    EmitHeader('const ' + LType + ' ' + ANode.ConstName + ' = ' + EmitExpression(ANode.Value) + ';')
  else
    EmitImpl('const ' + LType + ' ' + ANode.ConstName + ' = ' + EmitExpression(ANode.Value) + ';');
end;

procedure TNPCodeGenerator.EmitVarDecl(ANode: TNPVarDeclNode; AIsHeader: Boolean);
var
  LVarName: string;
  LType: string;
  LPointerNode: TNPPointerNode;
  LFuncType: TNPFunctionTypeNode;
  LParams: TStringBuilder;
  LParam: TNPASTNode;
  LParamNode: TNPParameterNode;
  LI: Integer;
  LJ: Integer;
  LReturnType: string;
begin
  // Check if this is a function pointer type
  if (ANode.TypeNode is TNPPointerNode) and 
     (TNPPointerNode(ANode.TypeNode).BaseType is TNPFunctionTypeNode) then
  begin
    // Special handling for function pointer types
    LPointerNode := TNPPointerNode(ANode.TypeNode);
    LFuncType := TNPFunctionTypeNode(LPointerNode.BaseType);
    LParams := TStringBuilder.Create();
    try
      // Build parameter list
      for LI := 0 to LFuncType.Parameters.Count - 1 do
      begin
        LParam := LFuncType.Parameters[LI];
        if LParam is TNPParameterNode then
        begin
          LParamNode := TNPParameterNode(LParam);
          
          // Handle variadic parameters
          if LParamNode.IsVariadic then
          begin
            if LI > 0 then
              LParams.Append(', ');
            LParams.Append('...');
            Continue;
          end;
          
          for LJ := 0 to System.High(LParamNode.Names) do
          begin
            if (LI > 0) or (LJ > 0) then
              LParams.Append(', ');
            
            if LParamNode.Modifier = 'var' then
              LParams.Append(EmitType(LParamNode.TypeNode) + '&')
            else if LParamNode.Modifier = 'const' then
              LParams.Append('const ' + EmitType(LParamNode.TypeNode) + '&')
            else
              LParams.Append(EmitType(LParamNode.TypeNode));
          end;
        end;
      end;
      
      // Determine return type
      if LFuncType.IsFunction and Assigned(LFuncType.ReturnType) then
        LReturnType := EmitType(LFuncType.ReturnType)
      else
        LReturnType := 'void';
      
      // Emit each variable with function pointer syntax: return_type (*varname)(params)
      for LVarName in ANode.VarNames do
      begin
        if AIsHeader then
        begin
          EmitHeader('extern ' + LReturnType + ' (*' + LVarName + ')(' + LParams.ToString() + ');');
        end
        else
        begin
          if Assigned(ANode.InitValue) then
            EmitImpl(LReturnType + ' (*' + LVarName + ')(' + LParams.ToString() + ') = ' + EmitExpression(ANode.InitValue) + ';')
          else
            EmitImpl(LReturnType + ' (*' + LVarName + ')(' + LParams.ToString() + ');');
        end;
      end;
    finally
      LParams.Free();
    end;
  end
  else
  begin
    // Regular type handling
    LType := EmitType(ANode.TypeNode);
    
    for LVarName in ANode.VarNames do
    begin
      if AIsHeader then
      begin
        EmitHeader('extern ' + LType + ' ' + LVarName + ';');
      end
      else
      begin
        if Assigned(ANode.InitValue) then
          EmitImpl(LType + ' ' + LVarName + ' = ' + EmitExpression(ANode.InitValue) + ';')
        else
          EmitImpl(LType + ' ' + LVarName + ';');
      end;
    end;
  end;
end;

procedure TNPCodeGenerator.EmitRoutineDecl(ANode: TNPRoutineDeclNode; AIsHeader: Boolean);
var
  LReturnType: string;
  LParams: TStringBuilder;
  LParam: TNPASTNode;
  LParamNode: TNPParameterNode;
  LI: Integer;
  LJ: Integer;
begin
  LParams := TStringBuilder.Create();
  try
    // Build parameter list
    for LI := 0 to ANode.Parameters.Count - 1 do
    begin
      LParam := ANode.Parameters[LI];
      if LParam is TNPParameterNode then
      begin
        LParamNode := TNPParameterNode(LParam);
        
        // Handle variadic parameters
        if LParamNode.IsVariadic then
        begin
          if LI > 0 then
            LParams.Append(', ');
          LParams.Append('...');
          Continue;
        end;
        
        for LJ := 0 to System.High(LParamNode.Names) do
        begin
          if (LI > 0) or (LJ > 0) then
            LParams.Append(', ');
          
          if LParamNode.Modifier = 'var' then
            LParams.Append(EmitType(LParamNode.TypeNode) + '& ' + LParamNode.Names[LJ])
          else if LParamNode.Modifier = 'const' then
            LParams.Append('const ' + EmitType(LParamNode.TypeNode) + '& ' + LParamNode.Names[LJ])
          else
            LParams.Append(EmitType(LParamNode.TypeNode) + ' ' + LParamNode.Names[LJ]);
        end;
      end;
    end;
    
    if Assigned(ANode.ReturnType) then
      LReturnType := EmitType(ANode.ReturnType)
    else
      LReturnType := 'void';
    
    // Emit declaration
    if AIsHeader then
    begin
      if ANode.IsPublic then
      begin
        if FIsLibrary then
          EmitHeader('DLLEXPORT ' + LReturnType + ' ' + ANode.RoutineName + '(' + LParams.ToString() + ');')
        else
          EmitHeader(LReturnType + ' ' + ANode.RoutineName + '(' + LParams.ToString() + ');');
      end;
    end
    else
    begin
      EmitImpl('');
      if not ANode.IsPublic then
        EmitImpl('static ' + LReturnType + ' ' + ANode.RoutineName + '(' + LParams.ToString() + ') {')
      else if FIsLibrary then
        EmitImpl('DLLEXPORT ' + LReturnType + ' ' + ANode.RoutineName + '(' + LParams.ToString() + ') {')
      else
        EmitImpl(LReturnType + ' ' + ANode.RoutineName + '(' + LParams.ToString() + ') {');
      Indent();
      
      // Emit local variables
      for LParam in ANode.LocalVars do
      begin
        if LParam is TNPVarDeclNode then
        begin
          for var LVarName in TNPVarDeclNode(LParam).VarNames do
          begin
            EmitImpl(GetIndent() + EmitType(TNPVarDeclNode(LParam).TypeNode) + ' ' + LVarName + ';');
          end;
        end;
      end;
      
      if ANode.LocalVars.Count > 0 then
        EmitImpl('');
      
      // Emit body
      EmitStatements(ANode.Body);
      
      Dedent();
      EmitImpl('}');
    end;
  finally
    LParams.Free();
  end;
end;

function TNPCodeGenerator.EmitType(ANode: TNPASTNode): string;
var
  LName: string;
  LSubrange: TNPSubrangeNode;
begin
  if ANode is TNPIdentifierNode then
  begin
    LName := TNPIdentifierNode(ANode).Name;
    
    // Try to resolve as subrange type
    if Assigned(FSymbolTable) and FSymbolTable.ResolveToSubrange(LName, LSubrange) then
    begin
      // Subranges are represented as int32_t in C++
      Result := 'int32_t';
      Exit;
    end;
    
    // Map built-in types
    if LName = 'int' then
      Result := 'int32_t'
    else if LName = 'uint' then
      Result := 'uint32_t'
    else if LName = 'int64' then
      Result := 'int64_t'
    else if LName = 'uint64' then
      Result := 'uint64_t'
    else if LName = 'int16' then
      Result := 'int16_t'
    else if LName = 'uint16' then
      Result := 'uint16_t'
    else if LName = 'byte' then
      Result := 'uint8_t'
    else if LName = 'double' then
      Result := 'double'
    else if LName = 'float' then
      Result := 'float'
    else if LName = 'bool' then
      Result := 'bool'
    else if LName = 'char' then
      Result := 'char'
    else if LName = 'string' then
      Result := 'std::string'
    else if LName = 'pointer' then
      Result := 'void*'
    else
      Result := LName;
  end
  else if ANode is TNPArrayNode then
    Result := EmitArrayType(TNPArrayNode(ANode))
  else if ANode is TNPPointerNode then
    Result := EmitPointerType(TNPPointerNode(ANode))
  else
    Result := 'void';
end;

function TNPCodeGenerator.EmitRecordType(ANode: TNPRecordNode; const ATypeName: string = ''): string;
var
  LResult: TStringBuilder;
  LField: TNPASTNode;
  LVarDecl: TNPVarDeclNode;
  LVarName: string;
begin
  LResult := TStringBuilder.Create();
  try
    // Emit named struct if type name is provided
    if ATypeName <> '' then
      LResult.AppendLine('struct ' + ATypeName + ' {')
    else
      LResult.AppendLine('struct {');
    
    for LField in ANode.Fields do
    begin
      if LField is TNPVarDeclNode then
      begin
        LVarDecl := TNPVarDeclNode(LField);
        for LVarName in LVarDecl.VarNames do
        begin
          LResult.AppendLine('  ' + EmitType(LVarDecl.TypeNode) + ' ' + LVarName + ';');
        end;
      end;
    end;
    
    LResult.Append('};');
    Result := LResult.ToString();
  finally
    LResult.Free();
  end;
end;

function TNPCodeGenerator.EmitEnumType(ANode: TNPEnumNode): string;
var
  LResult: TStringBuilder;
  LI: Integer;
begin
  LResult := TStringBuilder.Create();
  try
    LResult.Append('enum {');
    
    for LI := 0 to System.High(ANode.Values) do
    begin
      if LI > 0 then
        LResult.Append(', ');
      LResult.Append(ANode.Values[LI]);
    end;
    
    LResult.Append('}');
    Result := LResult.ToString();
  finally
    LResult.Free();
  end;
end;

function TNPCodeGenerator.EmitArrayType(ANode: TNPArrayNode): string;
var
  LSizeExpr: string;
  LI: Integer;
  LDim: TPair<TNPASTNode, TNPASTNode>;
  LResult: string;
  LLowValue: Integer;
  LHighValue: Integer;
  LLowBound: TNPASTNode;
  LHighBound: TNPASTNode;
  LSubrange: TNPSubrangeNode;
begin
  if Length(ANode.Dimensions) = 0 then
  begin
    Result := 'void /* invalid array */';
    Exit;
  end;
  
  LResult := EmitType(ANode.ElementType);
  
  // For multi-dimensional arrays, generate nested std::array
  // Process dimensions in reverse order for proper nesting
  for LI := Length(ANode.Dimensions) - 1 downto 0 do
  begin
    LDim := ANode.Dimensions[LI];
    LLowBound := LDim.Key;
    LHighBound := LDim.Value;
    
    // Check if both bounds are the same identifier (subrange type name)
    if (LLowBound = LHighBound) and (LLowBound is TNPIdentifierNode) then
    begin
      // This is a subrange type name, resolve it
      if Assigned(FSymbolTable) and FSymbolTable.ResolveToSubrange(TNPIdentifierNode(LLowBound).Name, LSubrange) then
      begin
        LLowValue := LSubrange.LowBound;
        LHighValue := LSubrange.HighBound;
        LSizeExpr := IntToStr((LHighValue - LLowValue) + 1);
        LResult := Format('std::array<%s, %s>', [LResult, LSizeExpr]);
        Continue;
      end
      else
      begin
        AddError(ANode.Position, Format('Cannot resolve type "%s" to subrange', [TNPIdentifierNode(LLowBound).Name]));
        Result := 'void /* unresolved subrange type */';
        Exit;
      end;
    end;
    
    // Resolve type names to subranges if needed (legacy support for single bound)
    if LLowBound is TNPIdentifierNode then
    begin
      if Assigned(FSymbolTable) and FSymbolTable.ResolveToSubrange(TNPIdentifierNode(LLowBound).Name, LSubrange) then
      begin
        // Use the resolved subrange bounds
        LLowValue := LSubrange.LowBound;
        LHighValue := LSubrange.HighBound;
        LSizeExpr := IntToStr((LHighValue - LLowValue) + 1);
        LResult := Format('std::array<%s, %s>', [LResult, LSizeExpr]);
        Continue;
      end;
    end;
    
    // Try to evaluate both bounds as constants
    // If both are integer literals, calculate size directly
    if (LLowBound is TNPIntLiteralNode) and (LHighBound is TNPIntLiteralNode) then
    begin
      LLowValue := TNPIntLiteralNode(LLowBound).Value;
      LHighValue := TNPIntLiteralNode(LHighBound).Value;
      LSizeExpr := IntToStr((LHighValue - LLowValue) + 1);
    end
    else
    begin
      // Build expression: (high - low + 1)
      // Emit both expressions and build the size calculation
      LSizeExpr := '((' + EmitExpression(LHighBound) + ') - (' + 
                   EmitExpression(LLowBound) + ') + 1)';
    end;
    
    LResult := Format('std::array<%s, %s>', [LResult, LSizeExpr]);
  end;
  
  Result := LResult;
end;

function TNPCodeGenerator.EmitPointerType(ANode: TNPPointerNode): string;
var
  LFuncType: TNPFunctionTypeNode;
  LParams: TStringBuilder;
  LParam: TNPASTNode;
  LParamNode: TNPParameterNode;
  LI: Integer;
  LJ: Integer;
  LReturnType: string;
begin
  // Check if this is a pointer to a function type
  if ANode.BaseType is TNPFunctionTypeNode then
  begin
    LFuncType := TNPFunctionTypeNode(ANode.BaseType);
    LParams := TStringBuilder.Create();
    try
      // Build parameter list
      for LI := 0 to LFuncType.Parameters.Count - 1 do
      begin
        LParam := LFuncType.Parameters[LI];
        if LParam is TNPParameterNode then
        begin
          LParamNode := TNPParameterNode(LParam);
          
          // Handle variadic parameters
          if LParamNode.IsVariadic then
          begin
            if LI > 0 then
              LParams.Append(', ');
            LParams.Append('...');
            Continue;
          end;
          
          for LJ := 0 to System.High(LParamNode.Names) do
          begin
            if (LI > 0) or (LJ > 0) then
              LParams.Append(', ');
            
            if LParamNode.Modifier = 'var' then
              LParams.Append(EmitType(LParamNode.TypeNode) + '&')
            else if LParamNode.Modifier = 'const' then
              LParams.Append('const ' + EmitType(LParamNode.TypeNode) + '&')
            else
              LParams.Append(EmitType(LParamNode.TypeNode));
          end;
        end;
      end;
      
      // Determine return type
      if LFuncType.IsFunction and Assigned(LFuncType.ReturnType) then
        LReturnType := EmitType(LFuncType.ReturnType)
      else
        LReturnType := 'void';
      
      // Generate C++ function pointer syntax: return_type (*)(params)
      Result := LReturnType + ' (*)(' + LParams.ToString() + ')';
    finally
      LParams.Free();
    end;
  end
  else
  begin
    // Regular pointer: type*
    Result := EmitType(ANode.BaseType) + '*';
  end;
end;

procedure TNPCodeGenerator.EmitStatements(AStmts: TNPASTNodeList);
var
  LStmt: TNPASTNode;
begin
  for LStmt in AStmts do
    EmitStatement(LStmt);
end;

procedure TNPCodeGenerator.EmitStatement(ANode: TNPASTNode);
begin
  if ANode is TNPCompoundNode then
    EmitCompound(TNPCompoundNode(ANode))
  else if ANode is TNPAssignmentNode then
    EmitAssignment(TNPAssignmentNode(ANode))
  else if ANode is TNPIfNode then
    EmitIf(TNPIfNode(ANode))
  else if ANode is TNPWhileNode then
    EmitWhile(TNPWhileNode(ANode))
  else if ANode is TNPRepeatNode then
    EmitRepeat(TNPRepeatNode(ANode))
  else if ANode is TNPForNode then
    EmitFor(TNPForNode(ANode))
  else if ANode is TNPCaseNode then
    EmitCase(TNPCaseNode(ANode))
  else if ANode is TNPBreakNode then
    EmitImpl(GetIndent() + 'break;')
  else if ANode is TNPContinueNode then
    EmitImpl(GetIndent() + 'continue;')
  else if ANode is TNPReturnNode then
  begin
    if Assigned(TNPReturnNode(ANode).Value) then
      EmitImpl(GetIndent() + 'return ' + EmitExpression(TNPReturnNode(ANode).Value) + ';')
    else
      EmitImpl(GetIndent() + 'return;');
  end
  else if ANode is TNPHaltNode then
    EmitImpl(GetIndent() + 'std::exit(' + EmitExpression(TNPHaltNode(ANode).ExitCode) + ');')
  else if ANode is TNPCallNode then
    EmitImpl(GetIndent() + EmitCall(TNPCallNode(ANode)) + ';')
  else if ANode is TNPMethodCallNode then
    EmitImpl(GetIndent() + EmitMethodCall(TNPMethodCallNode(ANode)) + ';');
end;

procedure TNPCodeGenerator.EmitCompound(ANode: TNPCompoundNode);
begin
  EmitImpl(GetIndent() + '{');
  Indent();
  EmitStatements(ANode.Statements);
  Dedent();
  EmitImpl(GetIndent() + '}');
end;

procedure TNPCodeGenerator.EmitAssignment(ANode: TNPAssignmentNode);
begin
  EmitImpl(GetIndent() + EmitExpression(ANode.Target) + ' = ' + EmitExpression(ANode.Value) + ';');
end;

procedure TNPCodeGenerator.EmitIf(ANode: TNPIfNode);
begin
  EmitImpl(GetIndent() + 'if (' + EmitExpression(ANode.Condition) + ') {');
  Indent();
  EmitStatement(ANode.ThenBranch);
  Dedent();
  
  if Assigned(ANode.ElseBranch) then
  begin
    EmitImpl(GetIndent() + '} else {');
    Indent();
    EmitStatement(ANode.ElseBranch);
    Dedent();
  end;
  
  EmitImpl(GetIndent() + '}');
end;

procedure TNPCodeGenerator.EmitWhile(ANode: TNPWhileNode);
begin
  EmitImpl(GetIndent() + 'while (' + EmitExpression(ANode.Condition) + ') {');
  Indent();
  EmitStatement(ANode.Body);
  Dedent();
  EmitImpl(GetIndent() + '}');
end;

procedure TNPCodeGenerator.EmitRepeat(ANode: TNPRepeatNode);
begin
  EmitImpl(GetIndent() + 'do {');
  Indent();
  EmitStatements(ANode.Body);
  Dedent();
  EmitImpl(GetIndent() + '} while (!(' + EmitExpression(ANode.Condition) + '));');
end;

procedure TNPCodeGenerator.EmitFor(ANode: TNPForNode);
var
  LStart, LEnd, LOp: string;
begin
  LStart := EmitExpression(ANode.StartValue);
  LEnd := EmitExpression(ANode.EndValue);
  
  if ANode.IsDownto then
    LOp := '--'
  else
    LOp := '++';
  
  EmitImpl(GetIndent() + 'for (int ' + ANode.VarName + ' = ' + LStart + '; ' + 
           ANode.VarName + ' <= ' + LEnd + '; ' + ANode.VarName + LOp + ') {');
  Indent();
  EmitStatement(ANode.Body);
  Dedent();
  EmitImpl(GetIndent() + '}');
end;

procedure TNPCodeGenerator.EmitCase(ANode: TNPCaseNode);
var
  LElement: TNPASTNode;
  LCaseElem: TNPCaseElementNode;
  LLabel: TNPASTNode;
begin
  EmitImpl(GetIndent() + 'switch (' + EmitExpression(ANode.Expression) + ') {');
  Indent();
  
  for LElement in ANode.Elements do
  begin
    if LElement is TNPCaseElementNode then
    begin
      LCaseElem := TNPCaseElementNode(LElement);
      
      for LLabel in LCaseElem.Labels do
      begin
        EmitImpl(GetIndent() + 'case ' + EmitExpression(LLabel) + ':');
      end;
      
      Indent();
      EmitStatement(LCaseElem.Statement);
      EmitImpl(GetIndent() + 'break;');
      Dedent();
    end;
  end;
  
  if ANode.ElseStatements.Count > 0 then
  begin
    EmitImpl(GetIndent() + 'default:');
    Indent();
    EmitStatements(ANode.ElseStatements);
    EmitImpl(GetIndent() + 'break;');
    Dedent();
  end;
  
  Dedent();
  EmitImpl(GetIndent() + '}');
end;

function TNPCodeGenerator.EmitExpression(ANode: TNPASTNode): string;
begin
  if ANode is TNPBinaryOpNode then
    Result := EmitBinaryOp(TNPBinaryOpNode(ANode))
  else if ANode is TNPUnaryOpNode then
    Result := EmitUnaryOp(TNPUnaryOpNode(ANode))
  else if ANode is TNPCallNode then
    Result := EmitCall(TNPCallNode(ANode))
  else if ANode is TNPMethodCallNode then
    Result := EmitMethodCall(TNPMethodCallNode(ANode))
  else if ANode is TNPTypeCastNode then
    Result := EmitTypeCast(TNPTypeCastNode(ANode))
  else if ANode is TNPIdentifierNode then
    Result := TNPIdentifierNode(ANode).Name
  else if ANode is TNPIntLiteralNode then
    Result := IntToStr(TNPIntLiteralNode(ANode).Value)
  else if ANode is TNPFloatLiteralNode then
  begin
    Result := FloatToStr(TNPFloatLiteralNode(ANode).Value);
    // Ensure float literals always have decimal point to avoid integer division in C++
    if (Pos('.', Result) = 0) and (Pos('e', LowerCase(Result)) = 0) then
      Result := Result + '.0';
  end
  else if ANode is TNPStringLiteralNode then
    Result := '"' + EscapeString(TNPStringLiteralNode(ANode).Value) + '"'
  else if ANode is TNPCharLiteralNode then
    Result := '''' + TNPCharLiteralNode(ANode).Value + ''''
  else if ANode is TNPBoolLiteralNode then
  begin
    if TNPBoolLiteralNode(ANode).Value then
      Result := 'true'
    else
      Result := 'false';
  end
  else if ANode is TNPNilLiteralNode then
    Result := 'nullptr'
  else if ANode is TNPFieldAccessNode then
  begin
    // Handle pointer dereference + field access: ptr^.x becomes ptr->x
    if TNPFieldAccessNode(ANode).RecordExpr is TNPDerefNode then
      Result := EmitExpression(TNPDerefNode(TNPFieldAccessNode(ANode).RecordExpr).PointerExpr) + '->' + TNPFieldAccessNode(ANode).FieldName
    else
      Result := EmitExpression(TNPFieldAccessNode(ANode).RecordExpr) + '.' + TNPFieldAccessNode(ANode).FieldName;
  end
  else if ANode is TNPIndexNode then
    Result := EmitExpression(TNPIndexNode(ANode).ArrayExpr) + '[' + EmitExpression(TNPIndexNode(ANode).IndexExpr) + ']'
  else if ANode is TNPDerefNode then
    Result := '*' + EmitExpression(TNPDerefNode(ANode).PointerExpr)
  else if ANode is TNPArrayLiteralNode then
    Result := EmitArrayLiteral(TNPArrayLiteralNode(ANode))
  else if ANode is TNPRecordLiteralNode then
    Result := EmitRecordLiteral(TNPRecordLiteralNode(ANode))
  else
    Result := '/* unknown */';
end;

function TNPCodeGenerator.EmitBinaryOp(ANode: TNPBinaryOpNode): string;
var
  LIsInteger: Boolean;
begin
  LIsInteger := IsIntegerExpression(ANode.Left) or IsIntegerExpression(ANode.Right);
  Result := '(' + EmitExpression(ANode.Left) + ' ' + MapBinaryOperator(ANode.Op, LIsInteger) + ' ' + EmitExpression(ANode.Right) + ')';
end;

function TNPCodeGenerator.EmitUnaryOp(ANode: TNPUnaryOpNode): string;
var
  LIsInteger: Boolean;
begin
  if ANode.Op = tkAt then
    Result := '&' + EmitExpression(ANode.Operand)
  else
  begin
    LIsInteger := IsIntegerExpression(ANode.Operand);
    Result := MapUnaryOperator(ANode.Op, LIsInteger) + EmitExpression(ANode.Operand);
  end;
end;

function TNPCodeGenerator.EmitCall(ANode: TNPCallNode): string;
var
  LArgs: TStringBuilder;
  LI: Integer;
begin
  LArgs := TStringBuilder.Create();
  try
    for LI := 0 to ANode.Arguments.Count - 1 do
    begin
      if LI > 0 then
        LArgs.Append(', ');
      LArgs.Append(EmitExpression(ANode.Arguments[LI]));
    end;
    
    // Handle dereferenced function pointer calls: fp^(args) → (*fp)(args)
    if ANode.Callee is TNPDerefNode then
      Result := '(*' + EmitExpression(TNPDerefNode(ANode.Callee).PointerExpr) + ')(' + LArgs.ToString() + ')'
    else
      Result := EmitExpression(ANode.Callee) + '(' + LArgs.ToString() + ')';
  finally
    LArgs.Free();
  end;
end;

function TNPCodeGenerator.EmitMethodCall(ANode: TNPMethodCallNode): string;
var
  LArgs: TStringBuilder;
  LI: Integer;
begin
  LArgs := TStringBuilder.Create();
  try
    for LI := 0 to ANode.Arguments.Count - 1 do
    begin
      if LI > 0 then
        LArgs.Append(', ');
      LArgs.Append(EmitExpression(ANode.Arguments[LI]));
    end;
    
    Result := EmitExpression(ANode.ObjectExpr) + '.' + ANode.MethodName + '(' + LArgs.ToString() + ')';
  finally
    LArgs.Free();
  end;
end;

function TNPCodeGenerator.EmitTypeCast(ANode: TNPTypeCastNode): string;
var
  LTargetType: string;
  LExpr: string;
begin
  // Generate C++ type cast
  LTargetType := EmitType(ANode.TargetType);
  LExpr := EmitExpression(ANode.Expression);
  
  // For pointer casts, use reinterpret_cast
  // For other types, use static_cast
  if ANode.TargetType is TNPPointerNode then
    Result := 'reinterpret_cast<' + LTargetType + '>(' + LExpr + ')'
  else
    Result := 'static_cast<' + LTargetType + '>(' + LExpr + ')';
end;

function TNPCodeGenerator.EmitArrayLiteral(ANode: TNPArrayLiteralNode): string;
var
  LResult: TStringBuilder;
  LI: Integer;
begin
  LResult := TStringBuilder.Create();
  try
    LResult.Append('{');
    
    for LI := 0 to ANode.Elements.Count - 1 do
    begin
      if LI > 0 then
        LResult.Append(', ');
      LResult.Append(EmitExpression(ANode.Elements[LI]));
    end;
    
    LResult.Append('}');
    Result := LResult.ToString();
  finally
    LResult.Free();
  end;
end;

function TNPCodeGenerator.EmitRecordLiteral(ANode: TNPRecordLiteralNode): string;
var
  LResult: TStringBuilder;
  LI: Integer;
begin
  LResult := TStringBuilder.Create();
  try
    LResult.Append('{');
    
    for LI := 0 to System.High(ANode.FieldNames) do
    begin
      if LI > 0 then
        LResult.Append(', ');
      // C++ designated initializer syntax: .fieldname = value
      LResult.Append('.');
      LResult.Append(ANode.FieldNames[LI]);
      LResult.Append(' = ');
      LResult.Append(EmitExpression(ANode.FieldValues[LI]));
    end;
    
    LResult.Append('}');
    Result := LResult.ToString();
  finally
    LResult.Free();
  end;
end;

function TNPCodeGenerator.EscapeString(const AStr: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AStr do
  begin
    case LChar of
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
      #9:  Result := Result + '\t';
      #0:  Result := Result + '\0';
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
    else
      Result := Result + LChar;
    end;
  end;
end;

function TNPCodeGenerator.IsIntegerExpression(ANode: TNPASTNode): Boolean;
begin
  // Check if expression is integer-typed (not boolean)
  if ANode is TNPIntLiteralNode then
    Result := True
  else if ANode is TNPBoolLiteralNode then
    Result := False
  else if ANode is TNPBinaryOpNode then
  begin
    // Recursively check operands
    Result := IsIntegerExpression(TNPBinaryOpNode(ANode).Left) or 
              IsIntegerExpression(TNPBinaryOpNode(ANode).Right);
  end
  else if ANode is TNPUnaryOpNode then
    Result := IsIntegerExpression(TNPUnaryOpNode(ANode).Operand)
  else
    // Default: assume integer for identifiers and other expressions
    // This is conservative - we prefer bitwise for ambiguous cases
    Result := True;
end;

function TNPCodeGenerator.MapBinaryOperator(AKind: TNPTokenKind; AIsInteger: Boolean): string;
begin
  case AKind of
    tkPlus: Result := '+';
    tkMinus: Result := '-';
    tkStar: Result := '*';
    tkSlash: Result := '/';
    tkDiv: Result := '/';
    tkMod: Result := '%';
    tkEquals: Result := '==';
    tkNotEqual: Result := '!=';
    tkLess: Result := '<';
    tkLessEqual: Result := '<=';
    tkGreater: Result := '>';
    tkGreaterEqual: Result := '>=';
    tkAnd: 
      if AIsInteger then
        Result := '&'   // Bitwise AND for integers
      else
        Result := '&&'; // Logical AND for booleans
    tkOr: 
      if AIsInteger then
        Result := '|'   // Bitwise OR for integers
      else
        Result := '||'; // Logical OR for booleans
    tkXor: Result := '^';  // Always bitwise XOR
    tkShl: Result := '<<'; // Shift left
    tkShr: Result := '>>'; // Shift right
  else
    Result := '?';
  end;
end;

function TNPCodeGenerator.MapUnaryOperator(AKind: TNPTokenKind; AIsInteger: Boolean): string;
begin
  case AKind of
    tkMinus: Result := '-';
    tkNot:
      if AIsInteger then
        Result := '~'   // Bitwise NOT for integers
      else
        Result := '!';  // Logical NOT for booleans
  else
    Result := '?';
  end;
end;

function TNPCodeGenerator.MapOperator(AKind: TNPTokenKind): string;
begin
  case AKind of
    tkPlus: Result := '+';
    tkMinus: Result := '-';
    tkStar: Result := '*';
    tkSlash: Result := '/';
    tkDiv: Result := '/';
    tkMod: Result := '%';
    tkEquals: Result := '==';
    tkNotEqual: Result := '!=';
    tkLess: Result := '<';
    tkLessEqual: Result := '<=';
    tkGreater: Result := '>';
    tkGreaterEqual: Result := '>=';
    tkAnd: Result := '&&';
    tkOr: Result := '||';
    tkNot: Result := '!';
    tkXor: Result := '^';
  else
    Result := '?';
  end;
end;

function TNPCodeGenerator.GetHeaderCode(): string;
begin
  Result := FHeaderCode.ToString();
end;

function TNPCodeGenerator.GetImplementationCode(): string;
begin
  Result := FImplCode.ToString();
end;

function TNPCodeGenerator.HasErrors(): Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPCodeGenerator.GetErrors(): TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

procedure TNPCodeGenerator.Clear();
begin
  FErrors.Clear();
  FHeaderCode.Clear();
  FImplCode.Clear();
  FIndentLevel := 0;
end;

end.
