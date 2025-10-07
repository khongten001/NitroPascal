{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Types;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Generics.Collections,
  System.Rtti;

type
  { Forward declarations }
  TNPASTNode = class;
  TNPASTNodeList = class;

  { TNPSourcePos }
  TNPSourcePos = record
    Filename: string;
    Line: Integer;
    Column: Integer;
    class function Create(const AFilename: string; ALine, AColumn: Integer): TNPSourcePos; static;
    function ToString(): string;
  end;

  { TNPError }
  TNPError = record
    Position: TNPSourcePos;
    Message: string;
    ErrorCode: Integer;
    class function Create(const APos: TNPSourcePos; const AMsg: string; ACode: Integer = 0): TNPError; static;
    function ToString(): string;
  end;

  { TNPTokenKind }
  TNPTokenKind = (
    // Literals
    tkInteger, tkFloat, tkString, tkChar,
    
    // Keywords  
    tkProgram, tkModule, tkLibrary, tkRoutine, tkVar, tkConst, tkType, tkArray,
    tkBegin, tkEnd, tkIf, tkThen, tkElse, tkWhile, tkDo, tkFor, tkTo, tkDownto,
    tkCase, tkOf, tkReturn, tkBreak, tkContinue, tkRepeat, tkUntil,
    tkExtern, tkImport, tkPublic, tkFinalize, tkHalt,
    tkAnd, tkOr, tkNot, tkXor, tkDiv, tkMod, tkShl, tkShr,
    tkTrue, tkFalse, tkNil,
    
    // Operators
    tkAssign, tkEquals, tkNotEqual, tkLess, tkGreater, tkLessEqual, tkGreaterEqual,
    tkPlus, tkMinus, tkStar, tkSlash,
    
    // Delimiters
    tkLParen, tkRParen, tkLBracket, tkRBracket, 
    tkDot, tkComma, tkColon, tkSemicolon,
    tkCaret, tkAt, tkDotDot,
    
    // Special
    tkIdentifier, tkDirective, tkPreprocessor, tkEOF, tkError
  );

  { TNPToken - Token with position and value }
  TNPToken = record
    Kind: TNPTokenKind;
    Position: TNPSourcePos;
    Lexeme: string;
    Value: TValue;
    class function Create(AKind: TNPTokenKind; const APos: TNPSourcePos; const ALexeme: string): TNPToken; overload; static;
    class function Create(AKind: TNPTokenKind; const APos: TNPSourcePos; const ALexeme: string; const AValue: TValue): TNPToken; overload; static;
    function ToString(): string;
  end;

  { TNPCompilationMode }
  TNPCompilationMode = (cmProgram, cmModule, cmLibrary);

  { TNPNodeKind }
  TNPNodeKind = (
    nkProgram, nkModule, nkLibrary,
    nkImport, nkExtern, nkTypeDecl, nkConstDecl, nkVarDecl, nkRoutineDecl,
    nkParameter, nkRecord, nkEnum, nkArray, nkPointer, nkSubrange, nkFunctionType,
    nkCompound, nkAssignment, nkIf, nkWhile, nkRepeat, nkFor, nkCase,
    nkBreak, nkContinue, nkReturn, nkHalt,
    nkBinary, nkUnary, nkCall, nkMethodCall, nkIndex, nkFieldAccess, nkDeref, nkTypeCast,
    nkIdentifier, nkIntLiteral, nkFloatLiteral, nkStringLiteral, nkCharLiteral,
    nkBoolLiteral, nkNilLiteral, nkArrayLiteral, nkRecordLiteral
  );

  { TNPASTNode }
  TNPASTNode = class
  private
    FPosition: TNPSourcePos;
    FKind: TNPNodeKind;
  public
    constructor Create(AKind: TNPNodeKind; const APos: TNPSourcePos);
    property Kind: TNPNodeKind read FKind;
    property Position: TNPSourcePos read FPosition;
  end;

  { TNPASTNodeList }
  TNPASTNodeList = class(TObjectList<TNPASTNode>)
  end;

  { TNPProgramNode }
  TNPProgramNode = class(TNPASTNode)
  public
    Name: string;
    Declarations: TNPASTNodeList;
    MainBlock: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPModuleNode }
  TNPModuleNode = class(TNPASTNode)
  public
    Name: string;
    Declarations: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPLibraryNode }
  TNPLibraryNode = class(TNPASTNode)
  public
    Name: string;
    Declarations: TNPASTNodeList;
    InitBlock: TNPASTNodeList;
    FinalizeBlock: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPImportNode }
  TNPImportNode = class(TNPASTNode)
  public
    ModuleName: string;
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPExternNode }
  TNPExternNode = class(TNPASTNode)
  public
    Source: string;           // Header file or DLL name
    RoutineName: string;      // Name in NitroPascal
    ExternalName: string;     // Name in C/DLL (if different)
    Parameters: TNPASTNodeList;
    ReturnType: TNPASTNode;   // Can be nil for procedures
    IsDLL: Boolean;
    CallConv: string;         // stdcall, cdecl, fastcall
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPTypeDeclNode }
  TNPTypeDeclNode = class(TNPASTNode)
  public
    TypeName: string;
    TypeDef: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPConstDeclNode }
  TNPConstDeclNode = class(TNPASTNode)
  public
    ConstName: string;
    TypeNode: TNPASTNode;     // Can be nil (inferred)
    Value: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPVarDeclNode }
  TNPVarDeclNode = class(TNPASTNode)
  public
    VarNames: TArray<string>;
    TypeNode: TNPASTNode;
    InitValue: TNPASTNode;    // Can be nil
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPParameterNode }
  TNPParameterNode = class(TNPASTNode)
  public
    Names: TArray<string>;
    TypeNode: TNPASTNode;
    Modifier: string;         // '', 'const', 'var', 'out'
    IsVariadic: Boolean;      // True for variadic (...) parameters
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPRoutineDeclNode }
  TNPRoutineDeclNode = class(TNPASTNode)
  public
    RoutineName: string;
    Parameters: TNPASTNodeList;
    ReturnType: TNPASTNode;   // Can be nil for procedures
    LocalVars: TNPASTNodeList;
    Body: TNPASTNodeList;
    IsPublic: Boolean;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPRecordNode }
  TNPRecordNode = class(TNPASTNode)
  public
    Fields: TNPASTNodeList;   // List of TNPVarDeclNode
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPEnumNode }
  TNPEnumNode = class(TNPASTNode)
  public
    Values: TArray<string>;
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPArrayNode }
  TNPArrayNode = class(TNPASTNode)
  public
    Dimensions: TArray<TPair<TNPASTNode, TNPASTNode>>; // Array of (Low, High) bound expressions
    ElementType: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPPointerNode }
  TNPPointerNode = class(TNPASTNode)
  public
    BaseType: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPSubrangeNode }
  TNPSubrangeNode = class(TNPASTNode)
  public
    LowBound: Int64;
    HighBound: Int64;
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPFunctionTypeNode }
  TNPFunctionTypeNode = class(TNPASTNode)
  public
    IsFunction: Boolean;
    Parameters: TNPASTNodeList;
    ReturnType: TNPASTNode;  // Nil for procedures
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPCompoundNode }
  TNPCompoundNode = class(TNPASTNode)
  public
    Statements: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPAssignmentNode }
  TNPAssignmentNode = class(TNPASTNode)
  public
    Target: TNPASTNode;
    Value: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPIfNode }
  TNPIfNode = class(TNPASTNode)
  public
    Condition: TNPASTNode;
    ThenBranch: TNPASTNode;
    ElseBranch: TNPASTNode;   // Can be nil
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPWhileNode }
  TNPWhileNode = class(TNPASTNode)
  public
    Condition: TNPASTNode;
    Body: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPRepeatNode }
  TNPRepeatNode = class(TNPASTNode)
  public
    Body: TNPASTNodeList;
    Condition: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPForNode }
  TNPForNode = class(TNPASTNode)
  public
    VarName: string;
    StartValue: TNPASTNode;
    EndValue: TNPASTNode;
    Body: TNPASTNode;
    IsDownto: Boolean;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPCaseElementNode }
  TNPCaseElementNode = class(TNPASTNode)
  public
    Labels: TNPASTNodeList;   // List of expressions or ranges
    Statement: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPCaseNode }
  TNPCaseNode = class(TNPASTNode)
  public
    Expression: TNPASTNode;
    Elements: TNPASTNodeList;  // List of TNPCaseElementNode
    ElseStatements: TNPASTNodeList; // Can be nil
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPBreakNode }
  TNPBreakNode = class(TNPASTNode)
  public
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPContinueNode }
  TNPContinueNode = class(TNPASTNode)
  public
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPReturnNode }
  TNPReturnNode = class(TNPASTNode)
  public
    Value: TNPASTNode;  // Can be nil
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPHaltNode }
  TNPHaltNode = class(TNPASTNode)
  public
    ExitCode: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPBinaryOpNode }
  TNPBinaryOpNode = class(TNPASTNode)
  public
    Left: TNPASTNode;
    Op: TNPTokenKind;
    Right: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPUnaryOpNode }
  TNPUnaryOpNode = class(TNPASTNode)
  public
    Op: TNPTokenKind;
    Operand: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPCallNode }
  TNPCallNode = class(TNPASTNode)
  public
    Callee: TNPASTNode;
    Arguments: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPMethodCallNode }
  TNPMethodCallNode = class(TNPASTNode)
  public
    ObjectExpr: TNPASTNode;
    MethodName: string;
    Arguments: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPIndexNode }
  TNPIndexNode = class(TNPASTNode)
  public
    ArrayExpr: TNPASTNode;
    IndexExpr: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPFieldAccessNode }
  TNPFieldAccessNode = class(TNPASTNode)
  public
    RecordExpr: TNPASTNode;
    FieldName: string;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPDerefNode }
  TNPDerefNode = class(TNPASTNode)
  public
    PointerExpr: TNPASTNode;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPTypeCastNode }
  TNPTypeCastNode = class(TNPASTNode)
  public
    TargetType: TNPASTNode;    // Type to cast to
    Expression: TNPASTNode;     // Expression being cast
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPIdentifierNode }
  TNPIdentifierNode = class(TNPASTNode)
  public
    Name: string;
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPIntLiteralNode }
  TNPIntLiteralNode = class(TNPASTNode)
  public
    Value: Int64;
    constructor Create(const APos: TNPSourcePos; AValue: Int64);
  end;

  { TNPFloatLiteralNode }
  TNPFloatLiteralNode = class(TNPASTNode)
  public
    Value: Double;
    constructor Create(const APos: TNPSourcePos; AValue: Double);
  end;

  { TNPStringLiteralNode }
  TNPStringLiteralNode = class(TNPASTNode)
  public
    Value: string;
    constructor Create(const APos: TNPSourcePos; const AValue: string);
  end;

  { TNPCharLiteralNode }
  TNPCharLiteralNode = class(TNPASTNode)
  public
    Value: Char;
    constructor Create(const APos: TNPSourcePos; AValue: Char);
  end;

  { TNPBoolLiteralNode }
  TNPBoolLiteralNode = class(TNPASTNode)
  public
    Value: Boolean;
    constructor Create(const APos: TNPSourcePos; AValue: Boolean);
  end;

  { TNPNilLiteralNode }
  TNPNilLiteralNode = class(TNPASTNode)
  public
    constructor Create(const APos: TNPSourcePos);
  end;

  { TNPArrayLiteralNode }
  TNPArrayLiteralNode = class(TNPASTNode)
  public
    Elements: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPRecordLiteralNode }
  TNPRecordLiteralNode = class(TNPASTNode)
  public
    FieldNames: TArray<string>;
    FieldValues: TNPASTNodeList;
    constructor Create(const APos: TNPSourcePos);
    destructor Destroy; override;
  end;

  { TNPGeneratedFile }
  TNPGeneratedFile = record
    Filename: string;
    Content: string;
    IsHeader: Boolean;
  end;

implementation

{ TNPSourcePos }

class function TNPSourcePos.Create(const AFilename: string; ALine, AColumn: Integer): TNPSourcePos;
begin
  Result.Filename := AFilename;
  Result.Line := ALine;
  Result.Column := AColumn;
end;

function TNPSourcePos.ToString(): string;
begin
  Result := Format('%s(%d,%d)', [Filename, Line, Column]);
end;

{ TNPError }

class function TNPError.Create(const APos: TNPSourcePos; const AMsg: string; ACode: Integer): TNPError;
begin
  Result.Position := APos;
  Result.Message := AMsg;
  Result.ErrorCode := ACode;
end;

function TNPError.ToString(): string;
begin
  Result := Format('%s: error: %s', [Position.ToString(), Message]);
end;

{ TNPToken }

class function TNPToken.Create(AKind: TNPTokenKind; const APos: TNPSourcePos; const ALexeme: string): TNPToken;
begin
  Result.Kind := AKind;
  Result.Position := APos;
  Result.Lexeme := ALexeme;
  Result.Value := TValue.Empty;
end;

class function TNPToken.Create(AKind: TNPTokenKind; const APos: TNPSourcePos; const ALexeme: string; const AValue: TValue): TNPToken;
begin
  Result.Kind := AKind;
  Result.Position := APos;
  Result.Lexeme := ALexeme;
  Result.Value := AValue;
end;

function TNPToken.ToString(): string;
begin
  if not Value.IsEmpty then
    Result := Format('%s ''%s'' (%s)', [GetEnumName(TypeInfo(TNPTokenKind), Ord(Kind)), Lexeme, Value.ToString()])
  else
    Result := Format('%s ''%s''', [GetEnumName(TypeInfo(TNPTokenKind), Ord(Kind)), Lexeme]);
end;

{ TNPASTNode }

constructor TNPASTNode.Create(AKind: TNPNodeKind; const APos: TNPSourcePos);
begin
  inherited Create();
  FKind := AKind;
  FPosition := APos;
end;

{ TNPProgramNode }

constructor TNPProgramNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkProgram, APos);
  Declarations := TNPASTNodeList.Create(True);
  MainBlock := TNPASTNodeList.Create(True);
end;

destructor TNPProgramNode.Destroy;
begin
  Declarations.Free();
  MainBlock.Free();
  inherited;
end;

{ TNPModuleNode }

constructor TNPModuleNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkModule, APos);
  Declarations := TNPASTNodeList.Create(True);
end;

destructor TNPModuleNode.Destroy;
begin
  Declarations.Free();
  inherited;
end;

{ TNPLibraryNode }

constructor TNPLibraryNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkLibrary, APos);
  Declarations := TNPASTNodeList.Create(True);
  InitBlock := TNPASTNodeList.Create(True);
  FinalizeBlock := TNPASTNodeList.Create(True);
end;

destructor TNPLibraryNode.Destroy;
begin
  Declarations.Free();
  InitBlock.Free();
  FinalizeBlock.Free();
  inherited;
end;

{ TNPImportNode }

constructor TNPImportNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkImport, APos);
end;

{ TNPExternNode }

constructor TNPExternNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkExtern, APos);
  Parameters := TNPASTNodeList.Create(True);
end;

destructor TNPExternNode.Destroy;
begin
  Parameters.Free();
  if Assigned(ReturnType) then
    ReturnType.Free();
  inherited;
end;

{ TNPTypeDeclNode }

constructor TNPTypeDeclNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkTypeDecl, APos);
end;

destructor TNPTypeDeclNode.Destroy;
begin
  if Assigned(TypeDef) then
    TypeDef.Free();
  inherited;
end;

{ TNPConstDeclNode }

constructor TNPConstDeclNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkConstDecl, APos);
end;

destructor TNPConstDeclNode.Destroy;
begin
  if Assigned(TypeNode) then
    TypeNode.Free();
  if Assigned(Value) then
    Value.Free();
  inherited;
end;

{ TNPVarDeclNode }

constructor TNPVarDeclNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkVarDecl, APos);
end;

destructor TNPVarDeclNode.Destroy;
begin
  if Assigned(TypeNode) then
    TypeNode.Free();
  if Assigned(InitValue) then
    InitValue.Free();
  inherited;
end;

{ TNPParameterNode }

constructor TNPParameterNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkParameter, APos);
end;

destructor TNPParameterNode.Destroy;
begin
  if Assigned(TypeNode) then
    TypeNode.Free();
  inherited;
end;

{ TNPRoutineDeclNode }

constructor TNPRoutineDeclNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkRoutineDecl, APos);
  Parameters := TNPASTNodeList.Create(True);
  LocalVars := TNPASTNodeList.Create(True);
  Body := TNPASTNodeList.Create(True);
end;

destructor TNPRoutineDeclNode.Destroy;
begin
  Parameters.Free();
  LocalVars.Free();
  Body.Free();
  if Assigned(ReturnType) then
    ReturnType.Free();
  inherited;
end;

{ TNPRecordNode }

constructor TNPRecordNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkRecord, APos);
  Fields := TNPASTNodeList.Create(True);
end;

destructor TNPRecordNode.Destroy;
begin
  Fields.Free();
  inherited;
end;

{ TNPEnumNode }

constructor TNPEnumNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkEnum, APos);
end;

{ TNPArrayNode }

constructor TNPArrayNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkArray, APos);
end;

destructor TNPArrayNode.Destroy;
var
  LDim: TPair<TNPASTNode, TNPASTNode>;
begin
  // Free dimension expression nodes
  for LDim in Dimensions do
  begin
    if Assigned(LDim.Key) then
      LDim.Key.Free();
    if Assigned(LDim.Value) then
      LDim.Value.Free();
  end;
  
  if Assigned(ElementType) then
    ElementType.Free();
  inherited;
end;

{ TNPPointerNode }

constructor TNPPointerNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkPointer, APos);
end;

destructor TNPPointerNode.Destroy;
begin
  if Assigned(BaseType) then
    BaseType.Free();
  inherited;
end;

{ TNPSubrangeNode }

constructor TNPSubrangeNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkSubrange, APos);
end;

{ TNPFunctionTypeNode }

constructor TNPFunctionTypeNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkFunctionType, APos);
  Parameters := TNPASTNodeList.Create(True);
end;

destructor TNPFunctionTypeNode.Destroy;
begin
  Parameters.Free();
  if Assigned(ReturnType) then
    ReturnType.Free();
  inherited;
end;

{ TNPCompoundNode }

constructor TNPCompoundNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkCompound, APos);
  Statements := TNPASTNodeList.Create(True);
end;

destructor TNPCompoundNode.Destroy;
begin
  Statements.Free();
  inherited;
end;

{ TNPAssignmentNode }

constructor TNPAssignmentNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkAssignment, APos);
end;

destructor TNPAssignmentNode.Destroy;
begin
  if Assigned(Target) then
    Target.Free();
  if Assigned(Value) then
    Value.Free();
  inherited;
end;

{ TNPIfNode }

constructor TNPIfNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkIf, APos);
end;

destructor TNPIfNode.Destroy;
begin
  if Assigned(Condition) then
    Condition.Free();
  if Assigned(ThenBranch) then
    ThenBranch.Free();
  if Assigned(ElseBranch) then
    ElseBranch.Free();
  inherited;
end;

{ TNPWhileNode }

constructor TNPWhileNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkWhile, APos);
end;

destructor TNPWhileNode.Destroy;
begin
  if Assigned(Condition) then
    Condition.Free();
  if Assigned(Body) then
    Body.Free();
  inherited;
end;

{ TNPRepeatNode }

constructor TNPRepeatNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkRepeat, APos);
  Body := TNPASTNodeList.Create(True);
end;

destructor TNPRepeatNode.Destroy;
begin
  Body.Free();
  if Assigned(Condition) then
    Condition.Free();
  inherited;
end;

{ TNPForNode }

constructor TNPForNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkFor, APos);
end;

destructor TNPForNode.Destroy;
begin
  if Assigned(StartValue) then
    StartValue.Free();
  if Assigned(EndValue) then
    EndValue.Free();
  if Assigned(Body) then
    Body.Free();
  inherited;
end;

{ TNPCaseElementNode }

constructor TNPCaseElementNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkCase, APos);
  Labels := TNPASTNodeList.Create(True);
end;

destructor TNPCaseElementNode.Destroy;
begin
  Labels.Free();
  if Assigned(Statement) then
    Statement.Free();
  inherited;
end;

{ TNPCaseNode }

constructor TNPCaseNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkCase, APos);
  Elements := TNPASTNodeList.Create(True);
  ElseStatements := TNPASTNodeList.Create(True);
end;

destructor TNPCaseNode.Destroy;
begin
  if Assigned(Expression) then
    Expression.Free();
  Elements.Free();
  ElseStatements.Free();
  inherited;
end;

{ TNPBreakNode }

constructor TNPBreakNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkBreak, APos);
end;

{ TNPContinueNode }

constructor TNPContinueNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkContinue, APos);
end;

{ TNPReturnNode }

constructor TNPReturnNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkReturn, APos);
end;

destructor TNPReturnNode.Destroy;
begin
  if Assigned(Value) then
    Value.Free();
  inherited;
end;

{ TNPHaltNode }

constructor TNPHaltNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkHalt, APos);
end;

destructor TNPHaltNode.Destroy;
begin
  if Assigned(ExitCode) then
    ExitCode.Free();
  inherited;
end;

{ TNPBinaryOpNode }

constructor TNPBinaryOpNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkBinary, APos);
end;

destructor TNPBinaryOpNode.Destroy;
begin
  if Assigned(Left) then
    Left.Free();
  if Assigned(Right) then
    Right.Free();
  inherited;
end;

{ TNPUnaryOpNode }

constructor TNPUnaryOpNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkUnary, APos);
end;

destructor TNPUnaryOpNode.Destroy;
begin
  if Assigned(Operand) then
    Operand.Free();
  inherited;
end;

{ TNPCallNode }

constructor TNPCallNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkCall, APos);
  Arguments := TNPASTNodeList.Create(True);
end;

destructor TNPCallNode.Destroy;
begin
  if Assigned(Callee) then
    Callee.Free();
  Arguments.Free();
  inherited;
end;

{ TNPMethodCallNode }

constructor TNPMethodCallNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkMethodCall, APos);
  Arguments := TNPASTNodeList.Create(True);
end;

destructor TNPMethodCallNode.Destroy;
begin
  if Assigned(ObjectExpr) then
    ObjectExpr.Free();
  Arguments.Free();
  inherited;
end;

{ TNPIndexNode }

constructor TNPIndexNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkIndex, APos);
end;

destructor TNPIndexNode.Destroy;
begin
  if Assigned(ArrayExpr) then
    ArrayExpr.Free();
  if Assigned(IndexExpr) then
    IndexExpr.Free();
  inherited;
end;

{ TNPFieldAccessNode }

constructor TNPFieldAccessNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkFieldAccess, APos);
end;

destructor TNPFieldAccessNode.Destroy;
begin
  if Assigned(RecordExpr) then
    RecordExpr.Free();
  inherited;
end;

{ TNPDerefNode }

constructor TNPDerefNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkDeref, APos);
end;

destructor TNPDerefNode.Destroy;
begin
  if Assigned(PointerExpr) then
    PointerExpr.Free();
  inherited;
end;

{ TNPTypeCastNode }

constructor TNPTypeCastNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkTypeCast, APos);
end;

destructor TNPTypeCastNode.Destroy;
begin
  if Assigned(TargetType) then
    TargetType.Free();
  if Assigned(Expression) then
    Expression.Free();
  inherited;
end;

{ TNPIdentifierNode }

constructor TNPIdentifierNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkIdentifier, APos);
end;

{ TNPIntLiteralNode }

constructor TNPIntLiteralNode.Create(const APos: TNPSourcePos; AValue: Int64);
begin
  inherited Create(nkIntLiteral, APos);
  Value := AValue;
end;

{ TNPFloatLiteralNode }

constructor TNPFloatLiteralNode.Create(const APos: TNPSourcePos; AValue: Double);
begin
  inherited Create(nkFloatLiteral, APos);
  Value := AValue;
end;

{ TNPStringLiteralNode }

constructor TNPStringLiteralNode.Create(const APos: TNPSourcePos; const AValue: string);
begin
  inherited Create(nkStringLiteral, APos);
  Value := AValue;
end;

{ TNPCharLiteralNode }

constructor TNPCharLiteralNode.Create(const APos: TNPSourcePos; AValue: Char);
begin
  inherited Create(nkCharLiteral, APos);
  Value := AValue;
end;

{ TNPBoolLiteralNode }

constructor TNPBoolLiteralNode.Create(const APos: TNPSourcePos; AValue: Boolean);
begin
  inherited Create(nkBoolLiteral, APos);
  Value := AValue;
end;

{ TNPNilLiteralNode }

constructor TNPNilLiteralNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkNilLiteral, APos);
end;

{ TNPArrayLiteralNode }

constructor TNPArrayLiteralNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkArrayLiteral, APos);
  Elements := TNPASTNodeList.Create(True);
end;

destructor TNPArrayLiteralNode.Destroy;
begin
  Elements.Free();
  inherited;
end;

{ TNPRecordLiteralNode }

constructor TNPRecordLiteralNode.Create(const APos: TNPSourcePos);
begin
  inherited Create(nkRecordLiteral, APos);
  FieldValues := TNPASTNodeList.Create(True);
end;

destructor TNPRecordLiteralNode.Destroy;
begin
  FieldValues.Free();
  inherited;
end;

end.
