{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.Parser;

interface

// Program structure tests
procedure SimpleProgram();
procedure ProgramWithDeclarations();
procedure EmptyProgram();

// Module tests
procedure SimpleModule();
procedure ModuleWithRoutines();

// Expression tests
procedure SimpleBinaryExpression();
procedure ComplexExpression();
procedure UnaryExpression();

// Statement tests
procedure AssignmentStatement();
procedure IfStatement();
procedure WhileLoop();
procedure ForLoop();

implementation

uses
  System.SysUtils,
  NitroPascal.Types,
  UTest.Common;

procedure SimpleProgram();
const
  CSource =
  '''
  program Hello;
  begin
  end.
  ''';
begin
  RunParserTestWithVerify('Simple Program', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      if LProgram.Name <> 'Hello' then
        raise Exception.CreateFmt('Expected program name "Hello" but got "%s"', [LProgram.Name]);
      
      if LProgram.MainBlock.Count <> 0 then
        raise Exception.CreateFmt('Expected empty main block but got %d statements', [LProgram.MainBlock.Count]);
    end
  );
end;

procedure ProgramWithDeclarations();
const
  CSource =
  '''
  program Test;
  var x: int;
  const MAX: int = 100;
  begin
    x := 5;
  end.
  ''';
begin
  RunParserTestWithVerify('Program With Declarations', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LVarDecl: TNPASTNode;
      LConstDecl: TNPASTNode;
      LAssignment: TNPASTNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Check we have declarations
      if LProgram.Declarations.Count < 2 then
        raise Exception.CreateFmt('Expected at least 2 declarations but got %d', [LProgram.Declarations.Count]);
      
      // Find var declaration
      LVarDecl := FindNodeByKind(AAST, nkVarDecl);
      AssertNotNil(LVarDecl, 'Should have var declaration');
      
      // Find const declaration
      LConstDecl := FindNodeByKind(AAST, nkConstDecl);
      AssertNotNil(LConstDecl, 'Should have const declaration');
      
      // Verify const value
      AssertIntValue(TNPConstDeclNode(LConstDecl).Value, 100, 'Const MAX value');
      
      // Find assignment in main block
      LAssignment := FindNodeByKind(AAST, nkAssignment);
      AssertNotNil(LAssignment, 'Should have assignment statement');
      
      AssertIdentifierName(TNPAssignmentNode(LAssignment).Target, 'x', 'Assignment target');
      AssertIntValue(TNPAssignmentNode(LAssignment).Value, 5, 'Assignment value');
    end
  );
end;

procedure EmptyProgram();
const
  CSource =
  '''
  program Empty;
  begin
  end.
  ''';
begin
  RunParserTestWithVerify('Empty Program', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      if LProgram.Name <> 'Empty' then
        raise Exception.CreateFmt('Expected program name "Empty" but got "%s"', [LProgram.Name]);
      
      if LProgram.Declarations.Count <> 0 then
        raise Exception.CreateFmt('Expected no declarations but got %d', [LProgram.Declarations.Count]);
      
      if LProgram.MainBlock.Count <> 0 then
        raise Exception.CreateFmt('Expected empty main block but got %d statements', [LProgram.MainBlock.Count]);
    end
  );
end;

procedure SimpleModule();
const
  CSource =
  '''
  module MyModule;
  end.
  ''';
begin
  RunParserTestWithVerify('Simple Module', CSource,
    procedure(AAST: TNPASTNode)
    var
      LModule: TNPModuleNode;
    begin
      LModule := GetModuleNode(AAST);
      AssertNotNil(LModule, 'Root should be module node');
      
      if LModule.Name <> 'MyModule' then
        raise Exception.CreateFmt('Expected module name "MyModule" but got "%s"', [LModule.Name]);
      
      if LModule.Declarations.Count <> 0 then
        raise Exception.CreateFmt('Expected no declarations but got %d', [LModule.Declarations.Count]);
    end
  );
end;

procedure ModuleWithRoutines();
const
  CSource =
  '''
  module Math;
  public routine Add(const a, b: int): int;
  begin
    return a + b;
  end;
  end.
  ''';
begin
  RunParserTestWithVerify('Module With Routines', CSource,
    procedure(AAST: TNPASTNode)
    var
      LModule: TNPModuleNode;
      LRoutine: TNPASTNode;
      LRoutineDecl: TNPRoutineDeclNode;
      LReturn: TNPASTNode;
      LBinaryOp: TNPBinaryOpNode;
    begin
      LModule := GetModuleNode(AAST);
      AssertNotNil(LModule, 'Root should be module node');
      
      // Find routine declaration
      LRoutine := FindNodeByKind(AAST, nkRoutineDecl);
      AssertNotNil(LRoutine, 'Should have routine declaration');
      
      LRoutineDecl := TNPRoutineDeclNode(LRoutine);
      
      if LRoutineDecl.RoutineName <> 'Add' then
        raise Exception.CreateFmt('Expected routine name "Add" but got "%s"', [LRoutineDecl.RoutineName]);
      
      if not LRoutineDecl.IsPublic then
        raise Exception.Create('Routine should be public');
      
      // Find return statement
      LReturn := FindNodeByKind(AAST, nkReturn);
      AssertNotNil(LReturn, 'Should have return statement');
      
      // Verify return expression is binary op
      AssertNodeKind(TNPReturnNode(LReturn).Value, nkBinary, 'Return value should be binary op');
      LBinaryOp := TNPBinaryOpNode(TNPReturnNode(LReturn).Value);
      
      AssertBinaryOp(LBinaryOp, tkPlus, 'Return expression operator');
      AssertIdentifierName(LBinaryOp.Left, 'a', 'Left operand');
      AssertIdentifierName(LBinaryOp.Right, 'b', 'Right operand');
    end
  );
end;

procedure SimpleBinaryExpression();
const
  CSource =
  '''
  program Expr;
  var x: int;
  begin
    x := 5 + 3;
  end.
  ''';
begin
  RunParserTestWithVerify('Simple Binary Expression', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LAssignment: TNPASTNode;
      LBinaryOp: TNPBinaryOpNode;
    begin
      // Verify it's a program node
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be a program node');
      
      // Verify program name
      if LProgram.Name <> 'Expr' then
        raise Exception.CreateFmt('Expected program name "Expr" but got "%s"', [LProgram.Name]);
      
      // Find the assignment in main block
      LAssignment := FindNodeByKind(AAST, nkAssignment);
      AssertNotNil(LAssignment, 'Should have an assignment statement');
      
      // Verify assignment target is identifier "x"
      AssertIdentifierName(TNPAssignmentNode(LAssignment).Target, 'x', 'Assignment target');
      
      // Verify assignment value is a binary op
      AssertNodeKind(TNPAssignmentNode(LAssignment).Value, nkBinary, 'Assignment value should be binary operation');
      LBinaryOp := TNPBinaryOpNode(TNPAssignmentNode(LAssignment).Value);
      
      // Verify operator is plus
      AssertBinaryOp(LBinaryOp, tkPlus, 'Binary operator');
      
      // Verify left operand is 5
      AssertIntValue(LBinaryOp.Left, 5, 'Left operand');
      
      // Verify right operand is 3
      AssertIntValue(LBinaryOp.Right, 3, 'Right operand');
    end
  );
end;

procedure ComplexExpression();
const
  CSource =
  '''
  program Expr;
  var result: int;
  begin
    result := (5 + 3) * 2 - 1;
  end.
  ''';
begin
  RunParserTestWithVerify('Complex Expression', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LAssignment: TNPASTNode;
      LSubtraction: TNPBinaryOpNode;
      LMultiplication: TNPBinaryOpNode;
      LAddition: TNPBinaryOpNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Find assignment: result := (5 + 3) * 2 - 1
      LAssignment := FindNodeByKind(AAST, nkAssignment);
      AssertNotNil(LAssignment, 'Should have assignment statement');
      AssertIdentifierName(TNPAssignmentNode(LAssignment).Target, 'result', 'Assignment target');
      
      // Root operation should be subtraction: (...) - 1
      AssertNodeKind(TNPAssignmentNode(LAssignment).Value, nkBinary, 'Assignment value should be binary op');
      LSubtraction := TNPBinaryOpNode(TNPAssignmentNode(LAssignment).Value);
      AssertBinaryOp(LSubtraction, tkMinus, 'Root operator should be minus');
      
      // Right side of subtraction should be 1
      AssertIntValue(LSubtraction.Right, 1, 'Right operand of subtraction');
      
      // Left side should be multiplication: (5 + 3) * 2
      AssertNodeKind(LSubtraction.Left, nkBinary, 'Left side should be binary op');
      LMultiplication := TNPBinaryOpNode(LSubtraction.Left);
      AssertBinaryOp(LMultiplication, tkStar, 'Should be multiplication');
      
      // Right side of multiplication should be 2
      AssertIntValue(LMultiplication.Right, 2, 'Right operand of multiplication');
      
      // Left side should be addition: (5 + 3)
      AssertNodeKind(LMultiplication.Left, nkBinary, 'Should be binary op');
      LAddition := TNPBinaryOpNode(LMultiplication.Left);
      AssertBinaryOp(LAddition, tkPlus, 'Should be addition');
      
      // Verify operands of addition
      AssertIntValue(LAddition.Left, 5, 'Left operand of addition');
      AssertIntValue(LAddition.Right, 3, 'Right operand of addition');
    end
  );
end;

procedure UnaryExpression();
const
  CSource =
  '''
  program Expr;
  var x, y: int;
  begin
    x := -5;
    y := not true;
  end.
  ''';
begin
  RunParserTestWithVerify('Unary Expression', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LAssignment1: TNPAssignmentNode;
      LAssignment2: TNPAssignmentNode;
      LUnaryOp1: TNPUnaryOpNode;
      LUnaryOp2: TNPUnaryOpNode;
      LAssignments: array[0..1] of TNPASTNode;
      LIdx: Integer;
      LCount: Integer;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Find both assignments
      LCount := 0;
      for LIdx := 0 to LProgram.MainBlock.Count - 1 do
      begin
        if LProgram.MainBlock[LIdx].Kind = nkAssignment then
        begin
          if LCount < 2 then
            LAssignments[LCount] := LProgram.MainBlock[LIdx];
          Inc(LCount);
        end;
      end;
      
      if LCount <> 2 then
        raise Exception.CreateFmt('Expected 2 assignments but found %d', [LCount]);
      
      // First assignment: x := -5
      LAssignment1 := TNPAssignmentNode(LAssignments[0]);
      AssertIdentifierName(LAssignment1.Target, 'x', 'First assignment target');
      AssertNodeKind(LAssignment1.Value, nkUnary, 'First assignment value should be unary op');
      
      LUnaryOp1 := TNPUnaryOpNode(LAssignment1.Value);
      if LUnaryOp1.Op <> tkMinus then
        raise Exception.CreateFmt('Expected unary minus operator but got %d', [Ord(LUnaryOp1.Op)]);
      AssertIntValue(LUnaryOp1.Operand, 5, 'Unary minus operand');
      
      // Second assignment: y := not true
      LAssignment2 := TNPAssignmentNode(LAssignments[1]);
      AssertIdentifierName(LAssignment2.Target, 'y', 'Second assignment target');
      AssertNodeKind(LAssignment2.Value, nkUnary, 'Second assignment value should be unary op');
      
      LUnaryOp2 := TNPUnaryOpNode(LAssignment2.Value);
      if LUnaryOp2.Op <> tkNot then
        raise Exception.CreateFmt('Expected not operator but got %d', [Ord(LUnaryOp2.Op)]);
      
      // Verify operand is boolean literal true
      AssertNodeKind(LUnaryOp2.Operand, nkBoolLiteral, 'not operand should be boolean literal');
    end
  );
end;

procedure AssignmentStatement();
const
  CSource =
  '''
  program Test;
  var x, y: int;
  begin
    x := 5;
    y := x + 10;
  end.
  ''';
begin
  RunParserTestWithVerify('Assignment Statement', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LAssignment1: TNPAssignmentNode;
      LAssignment2: TNPAssignmentNode;
      LBinaryOp: TNPBinaryOpNode;
      LAssignments: array[0..1] of TNPASTNode;
      LIdx: Integer;
      LCount: Integer;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Find both assignments
      LCount := 0;
      for LIdx := 0 to LProgram.MainBlock.Count - 1 do
      begin
        if LProgram.MainBlock[LIdx].Kind = nkAssignment then
        begin
          if LCount < 2 then
            LAssignments[LCount] := LProgram.MainBlock[LIdx];
          Inc(LCount);
        end;
      end;
      
      if LCount <> 2 then
        raise Exception.CreateFmt('Expected 2 assignments but found %d', [LCount]);
      
      // First assignment: x := 5
      LAssignment1 := TNPAssignmentNode(LAssignments[0]);
      AssertIdentifierName(LAssignment1.Target, 'x', 'First assignment target');
      AssertIntValue(LAssignment1.Value, 5, 'First assignment value');
      
      // Second assignment: y := x + 10
      LAssignment2 := TNPAssignmentNode(LAssignments[1]);
      AssertIdentifierName(LAssignment2.Target, 'y', 'Second assignment target');
      AssertNodeKind(LAssignment2.Value, nkBinary, 'Second assignment value should be binary op');
      
      LBinaryOp := TNPBinaryOpNode(LAssignment2.Value);
      AssertBinaryOp(LBinaryOp, tkPlus, 'Binary operator');
      AssertIdentifierName(LBinaryOp.Left, 'x', 'Left operand');
      AssertIntValue(LBinaryOp.Right, 10, 'Right operand');
    end
  );
end;

procedure IfStatement();
const
  CSource =
  '''
  program Test;
  var x: int;
  begin
    if x > 0 then
      x := 1
    else
      x := 0;
  end.
  ''';
begin
  RunParserTestWithVerify('If Statement', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LIfNode: TNPASTNode;
      LIfStmt: TNPIfNode;
      LCondition: TNPBinaryOpNode;
      LThenAssignment: TNPAssignmentNode;
      LElseAssignment: TNPAssignmentNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Find if statement
      LIfNode := FindNodeByKind(AAST, nkIf);
      AssertNotNil(LIfNode, 'Should have if statement');
      LIfStmt := TNPIfNode(LIfNode);
      
      // Verify condition: x > 0
      AssertNodeKind(LIfStmt.Condition, nkBinary, 'Condition should be binary op');
      LCondition := TNPBinaryOpNode(LIfStmt.Condition);
      AssertBinaryOp(LCondition, tkGreater, 'Condition operator');
      AssertIdentifierName(LCondition.Left, 'x', 'Condition left operand');
      AssertIntValue(LCondition.Right, 0, 'Condition right operand');
      
      // Verify then branch: x := 1
      AssertNodeKind(LIfStmt.ThenBranch, nkAssignment, 'Then branch should be assignment');
      LThenAssignment := TNPAssignmentNode(LIfStmt.ThenBranch);
      AssertIdentifierName(LThenAssignment.Target, 'x', 'Then branch target');
      AssertIntValue(LThenAssignment.Value, 1, 'Then branch value');
      
      // Verify else branch: x := 0
      AssertNotNil(LIfStmt.ElseBranch, 'Should have else branch');
      AssertNodeKind(LIfStmt.ElseBranch, nkAssignment, 'Else branch should be assignment');
      LElseAssignment := TNPAssignmentNode(LIfStmt.ElseBranch);
      AssertIdentifierName(LElseAssignment.Target, 'x', 'Else branch target');
      AssertIntValue(LElseAssignment.Value, 0, 'Else branch value');
    end
  );
end;

procedure WhileLoop();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    i := 0;
    while i < 10 do
      i := i + 1;
  end.
  ''';
begin
  RunParserTestWithVerify('While Loop', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LWhileNode: TNPASTNode;
      LWhileStmt: TNPWhileNode;
      LCondition: TNPBinaryOpNode;
      LBodyAssignment: TNPAssignmentNode;
      LBodyBinaryOp: TNPBinaryOpNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Find while statement
      LWhileNode := FindNodeByKind(AAST, nkWhile);
      AssertNotNil(LWhileNode, 'Should have while statement');
      LWhileStmt := TNPWhileNode(LWhileNode);
      
      // Verify condition: i < 10
      AssertNodeKind(LWhileStmt.Condition, nkBinary, 'Condition should be binary op');
      LCondition := TNPBinaryOpNode(LWhileStmt.Condition);
      AssertBinaryOp(LCondition, tkLess, 'Condition operator');
      AssertIdentifierName(LCondition.Left, 'i', 'Condition left operand');
      AssertIntValue(LCondition.Right, 10, 'Condition right operand');
      
      // Verify body: i := i + 1
      AssertNodeKind(LWhileStmt.Body, nkAssignment, 'Body should be assignment');
      LBodyAssignment := TNPAssignmentNode(LWhileStmt.Body);
      AssertIdentifierName(LBodyAssignment.Target, 'i', 'Body assignment target');
      
      // Verify assignment value is i + 1
      AssertNodeKind(LBodyAssignment.Value, nkBinary, 'Body assignment value should be binary op');
      LBodyBinaryOp := TNPBinaryOpNode(LBodyAssignment.Value);
      AssertBinaryOp(LBodyBinaryOp, tkPlus, 'Body assignment operator');
      AssertIdentifierName(LBodyBinaryOp.Left, 'i', 'Body assignment left operand');
      AssertIntValue(LBodyBinaryOp.Right, 1, 'Body assignment right operand');
    end
  );
end;

procedure ForLoop();
const
  CSource =
  '''
  program Test;
  var i: int;
  begin
    for i := 1 to 10 do
      halt(0);
  end.
  ''';
begin
  RunParserTestWithVerify('For Loop', CSource,
    procedure(AAST: TNPASTNode)
    var
      LProgram: TNPProgramNode;
      LForNode: TNPASTNode;
      LForStmt: TNPForNode;
      LBodyHalt: TNPHaltNode;
    begin
      LProgram := GetProgramNode(AAST);
      AssertNotNil(LProgram, 'Root should be program node');
      
      // Find for statement
      LForNode := FindNodeByKind(AAST, nkFor);
      AssertNotNil(LForNode, 'Should have for statement');
      LForStmt := TNPForNode(LForNode);
      
      // Verify loop variable name
      if LForStmt.VarName <> 'i' then
        raise Exception.CreateFmt('Expected loop variable "i" but got "%s"', [LForStmt.VarName]);
      
      // Verify start value: 1
      AssertIntValue(LForStmt.StartValue, 1, 'Start value');
      
      // Verify end value: 10
      AssertIntValue(LForStmt.EndValue, 10, 'End value');
      
      // Verify direction is upward (to, not downto)
      if LForStmt.IsDownTo then
        raise Exception.Create('Expected upward loop (to) but got downward (downto)');
      
      // Verify body: halt(0)
      AssertNodeKind(LForStmt.Body, nkHalt, 'Body should be halt statement');
      LBodyHalt := TNPHaltNode(LForStmt.Body);
      
      // Verify halt exit code is 0
      AssertNotNil(LBodyHalt.ExitCode, 'Halt should have exit code');
      AssertIntValue(LBodyHalt.ExitCode, 0, 'Halt exit code');
    end
  );
end;

end.
