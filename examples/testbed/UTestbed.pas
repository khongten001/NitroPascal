{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

{-------------------------------------------------------------------------------
  TESTBED USAGE GUIDE

  The testbed provides a comprehensive test suite for NitroPascal with 376 tests
  organized by functional area. Tests can be run individually, in ranges, or all
  at once.

  COMMAND-LINE PARAMETERS:
  ------------------------
  <none>              Runs the default test (currently test 374)
  <number>            Runs a single test by number (1-376)
                      Example: testbed 42
  <start>-<end>       Runs a range of tests (inclusive)
                      Example: testbed 124-128
  all                 Runs all 376 tests sequentially
                      Example: testbed all

  TEST CATEGORIES:
  ----------------
  001-010  Lexer Tests           - Tokenization, identifiers, literals, comments
  011-022  Parser Tests          - Syntax tree construction, expressions, statements
  023-036  CodeGen Tests         - Program/Module/Library code generation
  037-072  String Tests          - String operations, methods, parameters, escaping
  073-123  Number Tests          - Integer/float arithmetic, bitwise, precedence
  124-159  Array Tests           - Indexing, multi-dim, parameters, operations
  160-195  Record Tests          - Field access, nesting, methods, initialization
  196-238  Pointer Tests         - Declaration, dereferencing, arithmetic, casting
  239-272  Control Flow Tests    - If/While/For/Repeat/Case, Break/Continue
  273-312  Type Tests            - Aliases, casting, conversion, custom types
  313-356  Parameter Tests       - By-value/const/var/out, arrays, records, pointers
  357-376  Conditional Compilation - Define/Undef, Ifdef/Ifndef, nesting

  EXAMPLES:
  ---------
  testbed                   // Runs default test (374)
  testbed 50                // Runs test 50 (StringLength)
  testbed 1-10              // Runs tests 1 through 10 (all Lexer tests)
  testbed 124-128           // Runs tests 124-128 (array declaration tests)
  testbed all               // Runs all 376 tests
  testbed all > results.txt // Runs all tests and output to text file

  NOTES:
  ------
  - When no parameter is provided, the testbed pauses after execution
  - With parameters (automated mode), no pause occurs
  - Invalid parameters display helpful error messages
  - Each test is wrapped in exception handling for error reporting
-------------------------------------------------------------------------------}

unit UTestbed;

interface

procedure RunTests();

implementation

uses
  System.SysUtils,
  System.IOUtils,
  NitroPascal.Utils,
  UTest.Lexer,
  UTest.Parser,
  UTest.CodeGen,
  UTest.Strings,
  UTest.Numbers,
  UTest.Arrays,
  UTest.Records,
  UTest.Pointers,
  UTest.ControlFlow,
  UTest.Types,
  UTest.Parameters,
  UTest.ConditionalCompilation,
  NitroPascal.Compiler;

const
  MAX_TEST_COUNT = 376;

procedure RunTests();
var
  LNum: Integer;
  LParam: string;
  LI: Integer;
  LStartTest: Integer;
  LEndTest: Integer;
  LIsAutomated: Boolean;
  LDashPos: Integer;
  LStartStr: string;
  LEndStr: string;
begin

  LIsAutomated := False;
  
  // Check for command-line parameter
  if ParamCount > 0 then
  begin
    LIsAutomated := True;
    LParam := ParamStr(1).ToLower;
    
    if LParam = 'all' then
    begin
      // Run all tests
      LStartTest := 1;
      LEndTest := MAX_TEST_COUNT;
    end
    else if Pos('-', LParam) > 0 then
    begin
      // Parse range format: "start-end"
      LDashPos := Pos('-', LParam);
      LStartStr := Copy(LParam, 1, LDashPos - 1);
      LEndStr := Copy(LParam, LDashPos + 1, Length(LParam) - LDashPos);
      
      if not TryStrToInt(LStartStr, LStartTest) then
      begin
        TNPUtils.PrintLn('Invalid start number in range. Use format: "start-end"');
        Exit;
      end;
      
      if not TryStrToInt(LEndStr, LEndTest) then
      begin
        TNPUtils.PrintLn('Invalid end number in range. Use format: "start-end"');
        Exit;
      end;
      
      if (LStartTest < 1) or (LStartTest > MAX_TEST_COUNT) then
      begin
        TNPUtils.PrintLn(Format('Start test number must be between 1 and %d', [MAX_TEST_COUNT]));
        Exit;
      end;
      
      if (LEndTest < 1) or (LEndTest > MAX_TEST_COUNT) then
      begin
        TNPUtils.PrintLn(Format('End test number must be between 1 and %d', [MAX_TEST_COUNT]));
        Exit;
      end;
      
      if LStartTest > LEndTest then
      begin
        TNPUtils.PrintLn('Start test must be less than or equal to end test');
        Exit;
      end;
    end
    else
    begin
      // Try to parse as single integer
      if not TryStrToInt(LParam, LNum) then
      begin
        TNPUtils.PrintLn(Format('Invalid parameter. Use a test number (1-%d), range (e.g. "124-128"), or "all"', [MAX_TEST_COUNT]));
        Exit;
      end;
      
      if (LNum < 1) or (LNum > MAX_TEST_COUNT) then
      begin
        TNPUtils.PrintLn(Format('Test number must be between 1 and %d', [MAX_TEST_COUNT]));
        Exit;
      end;
      
      LStartTest := LNum;
      LEndTest := LNum;
    end;
  end
  else
  begin
    // No parameter - use default
    LNum := 1;
    LStartTest := LNum;
    LEndTest := LNum;
  end;

  // Execute tests
  for LI := LStartTest to LEndTest do
  begin
    LNum := LI;
    
    try

    case LNum of
      // === LEXER TESTS ===
      01: UTest.Lexer.SimpleIdentifiers();
      02: UTest.Lexer.Keywords();
      03: UTest.Lexer.IntegerLiterals();
      04: UTest.Lexer.FloatLiterals();
      05: UTest.Lexer.StringLiterals();
      06: UTest.Lexer.ArithmeticOperators();
      07: UTest.Lexer.ComparisonOperators();
      08: UTest.Lexer.AssignmentOperator();
      09: UTest.Lexer.LineComments();
      10: UTest.Lexer.BlockComments();
      
      // === PARSER TESTS ===
      11: UTest.Parser.SimpleProgram();
      12: UTest.Parser.ProgramWithDeclarations();
      13: UTest.Parser.EmptyProgram();
      14: UTest.Parser.SimpleModule();
      15: UTest.Parser.ModuleWithRoutines();
      16: UTest.Parser.SimpleBinaryExpression();
      17: UTest.Parser.ComplexExpression();
      18: UTest.Parser.UnaryExpression();
      19: UTest.Parser.AssignmentStatement();
      20: UTest.Parser.IfStatement();
      21: UTest.Parser.WhileLoop();
      22: UTest.Parser.ForLoop();
      
      // === CODEGEN TESTS - Programs ===
      23: UTest.CodeGen.SimpleProgramCodeGen();
      24: UTest.CodeGen.ProgramWithVariables();
      25: UTest.CodeGen.ProgramWithRoutine();
      26: UTest.CodeGen.ArithmeticExpression();
      27: UTest.CodeGen.BooleanExpression();
      28: UTest.CodeGen.IfStatementCodeGen();
      29: UTest.CodeGen.WhileLoopCodeGen();
      30: UTest.CodeGen.ForLoopCodeGen();
      
      // === CODEGEN TESTS - Modules ===
      31: UTest.CodeGen.SimpleModuleCodeGen();
      32: UTest.CodeGen.ModuleWithPublicRoutines();
      33: UTest.CodeGen.ModuleWithTypes();
      34: UTest.CodeGen.ModuleVisibilityTest();

      // === CODEGEN TESTS - Libraries ===
      35: UTest.CodeGen.SimpleLibraryCodeGen();
      36: UTest.CodeGen.LibraryWithExports();
      
      // === STRING TESTS - Basic ===
      37: UTest.Strings.StringLiteral();
      38: UTest.Strings.StringVariable();
      39: UTest.Strings.StringAssignment();
      40: UTest.Strings.EmptyString();
      
      // === STRING TESTS - Concatenation ===
      41: UTest.Strings.StringConcatenation();
      42: UTest.Strings.StringConcatenationMultiple();
      43: UTest.Strings.StringConcatenationWithEmpty();
      
      // === STRING TESTS - Comparison ===
      44: UTest.Strings.StringEquality();
      45: UTest.Strings.StringInequality();
      46: UTest.Strings.StringLessThan();
      47: UTest.Strings.StringGreaterThan();
      
      // === STRING TESTS - Indexing ===
      48: UTest.Strings.StringIndexing();
      49: UTest.Strings.StringIndexAssignment();
      
      // === STRING TESTS - Methods ===
      50: UTest.Strings.StringLength();
      51: UTest.Strings.StringSubstr();
      52: UTest.Strings.StringFind();
      53: UTest.Strings.StringEmpty();
      54: UTest.Strings.StringClear();
      
      // === STRING TESTS - Parameters ===
      55: UTest.Strings.StringParameterByValue();
      56: UTest.Strings.StringParameterByConst();
      57: UTest.Strings.StringParameterByVar();
      
      // === STRING TESTS - Return Values ===
      58: UTest.Strings.StringReturnValue();
      59: UTest.Strings.StringReturnEmpty();
      
      // === STRING TESTS - Escape Sequences ===
      60: UTest.Strings.StringEscapeNewline();
      61: UTest.Strings.StringEscapeTab();
      62: UTest.Strings.StringEscapeQuote();
      63: UTest.Strings.StringEscapeBackslash();
      
      // === STRING TESTS - Edge Cases ===
      64: UTest.Strings.StringWithSpaces();
      65: UTest.Strings.StringWithNumbers();
      66: UTest.Strings.StringWithSpecialChars();
      
      // === STRING TESTS - Modules ===
      67: UTest.Strings.ModuleWithStringPublic();
      68: UTest.Strings.ModuleWithStringPrivate();
      
      // === STRING TESTS - Libraries ===
      69: UTest.Strings.LibraryWithString();
      
      // === STRING TESTS - Complex ===
      70: UTest.Strings.StringComplexExpression();
      71: UTest.Strings.StringInControlFlow();
      72: UTest.Strings.StringInLoop();

      // === NUMBER TESTS - Integer Literals ===
      73: UTest.Numbers.IntegerLiteral();
      74: UTest.Numbers.NegativeInteger();
      75: UTest.Numbers.ZeroInteger();
      76: UTest.Numbers.LargeInteger();

      // === NUMBER TESTS - Integer Arithmetic ===
      77: UTest.Numbers.IntegerAddition();
      78: UTest.Numbers.IntegerSubtraction();
      79: UTest.Numbers.IntegerMultiplication();
      80: UTest.Numbers.IntegerDivision();
      81: UTest.Numbers.IntegerModulo();
      82: UTest.Numbers.IntegerMixedArithmetic();

      // === NUMBER TESTS - Integer Comparisons ===
      83: UTest.Numbers.IntegerEquals();
      84: UTest.Numbers.IntegerNotEquals();
      85: UTest.Numbers.IntegerLessThan();
      86: UTest.Numbers.IntegerGreaterThan();
      87: UTest.Numbers.IntegerLessOrEqual();
      88: UTest.Numbers.IntegerGreaterOrEqual();

      // === NUMBER TESTS - Integer Bitwise ===
      89: UTest.Numbers.IntegerBitwiseAnd();
      90: UTest.Numbers.IntegerBitwiseOr();
      91: UTest.Numbers.IntegerBitwiseXor();
      92: UTest.Numbers.IntegerBitwiseNot();
      93: UTest.Numbers.IntegerShiftLeft();
      94: UTest.Numbers.IntegerShiftRight();

      // === NUMBER TESTS - Float Literals ===
      95: UTest.Numbers.FloatLiteral();
      96: UTest.Numbers.NegativeFloat();
      97: UTest.Numbers.FloatWithExponent();
      98: UTest.Numbers.FloatZero();

      // === NUMBER TESTS - Float Arithmetic ===
      99: UTest.Numbers.FloatAddition();
      100: UTest.Numbers.FloatSubtraction();
      101: UTest.Numbers.FloatMultiplication();
      102: UTest.Numbers.FloatDivision();
      103: UTest.Numbers.FloatMixedArithmetic();

      // === NUMBER TESTS - Float Comparisons ===
      104: UTest.Numbers.FloatEquals();
      105: UTest.Numbers.FloatNotEquals();
      106: UTest.Numbers.FloatLessThan();
      107: UTest.Numbers.FloatGreaterThan();
      108: UTest.Numbers.FloatLessOrEqual();
      109: UTest.Numbers.FloatGreaterOrEqual();

      // === NUMBER TESTS - Mixed Int/Float ===
      110: UTest.Numbers.MixedIntFloatAdd();
      111: UTest.Numbers.MixedIntFloatMultiply();
      112: UTest.Numbers.IntToFloatAssignment();
      113: UTest.Numbers.FloatToIntAssignment();

      // === NUMBER TESTS - Operator Precedence ===
      114: UTest.Numbers.PrecedenceMultiplyAdd();
      115: UTest.Numbers.PrecedenceParentheses();
      116: UTest.Numbers.PrecedenceDivMod();
      117: UTest.Numbers.PrecedenceUnaryMinus();
      118: UTest.Numbers.PrecedenceBitwiseLogical();
      119: UTest.Numbers.ComplexPrecedence();

      // === NUMBER TESTS - Edge Cases ===
      120: UTest.Numbers.IntegerOverflowLarge();
      121: UTest.Numbers.FloatPrecision();
      122: UTest.Numbers.DivisionByVariable();
      123: UTest.Numbers.ModuloNegative();

      // === ARRAY TESTS - Declaration ===
      124: UTest.Arrays.SimpleArrayDeclaration();
      125: UTest.Arrays.ArrayWithInitialization();
      126: UTest.Arrays.MultiDimensionalArray();
      127: UTest.Arrays.ArrayOfStrings();
      128: UTest.Arrays.ArrayOfFloats();

      // === ARRAY TESTS - Indexing ===
      129: UTest.Arrays.ArrayIndexing();
      130: UTest.Arrays.ArrayIndexAssignment();
      131: UTest.Arrays.ArrayIndexExpression();
      132: UTest.Arrays.ArrayNegativeIndex();

      // === ARRAY TESTS - Operations ===
      133: UTest.Arrays.ArrayCopy();
      134: UTest.Arrays.ArrayComparison();
      135: UTest.Arrays.ArrayInLoop();
      136: UTest.Arrays.ArrayIteration();

      // === ARRAY TESTS - Multi-Dimensional ===
      137: UTest.Arrays.TwoDimensionalArray();
      138: UTest.Arrays.ThreeDimensionalArray();
      139: UTest.Arrays.MultiDimIndexing();
      140: UTest.Arrays.MultiDimAssignment();

      // === ARRAY TESTS - Parameters ===
      141: UTest.Arrays.ArrayParameterByValue();
      142: UTest.Arrays.ArrayParameterByConst();
      143: UTest.Arrays.ArrayParameterByVar();
      144: UTest.Arrays.ArrayReturnValue();

      // === ARRAY TESTS - Bounds ===
      145: UTest.Arrays.ArrayLowerBound();
      146: UTest.Arrays.ArrayUpperBound();
      147: UTest.Arrays.ArrayLength();
      148: UTest.Arrays.ArrayDynamicSize();

      // === ARRAY TESTS - In Structures ===
      149: UTest.Arrays.ArrayInRecord();
      150: UTest.Arrays.ArrayOfRecords();
      151: UTest.Arrays.NestedArrays();

      // === ARRAY TESTS - Initialization ===
      152: UTest.Arrays.ArrayStaticInitialization();
      153: UTest.Arrays.ArrayZeroInitialization();
      154: UTest.Arrays.ArrayRuntimeInitialization();

      // === ARRAY TESTS - Complex ===
      155: UTest.Arrays.ArrayArithmetic();
      156: UTest.Arrays.ArrayStringConcatenation();
      157: UTest.Arrays.ArrayMixedTypes();
      158: UTest.Arrays.ArrayInIfStatement();
      159: UTest.Arrays.ArrayInFunction();

      // === RECORD TESTS - Declaration ===
      160: UTest.Records.SimpleRecordDeclaration();
      161: UTest.Records.RecordWithMultipleFields();
      162: UTest.Records.RecordWithMixedTypes();
      163: UTest.Records.RecordWithString();
      164: UTest.Records.RecordWithArray();

      // === RECORD TESTS - Field Access ===
      165: UTest.Records.RecordFieldAccess();
      166: UTest.Records.RecordFieldAssignment();
      167: UTest.Records.RecordNestedFieldAccess();
      168: UTest.Records.RecordFieldExpression();

      // === RECORD TESTS - Operations ===
      169: UTest.Records.RecordCopy();
      170: UTest.Records.RecordComparison();
      171: UTest.Records.RecordInLoop();
      172: UTest.Records.RecordInitialization();

      // === RECORD TESTS - Nested ===
      173: UTest.Records.NestedRecord();
      174: UTest.Records.DeepNestedRecord();
      175: UTest.Records.NestedRecordAccess();
      176: UTest.Records.NestedRecordAssignment();

      // === RECORD TESTS - Parameters ===
      177: UTest.Records.RecordParameterByValue();
      178: UTest.Records.RecordParameterByConst();
      179: UTest.Records.RecordParameterByVar();
      180: UTest.Records.RecordReturnValue();

      // === RECORD TESTS - With Arrays ===
      181: UTest.Records.RecordContainingArray();
      182: UTest.Records.ArrayOfRecords();
      183: UTest.Records.RecordWithMultiDimArray();

      // === RECORD TESTS - Methods ===
      184: UTest.Records.RecordWithRoutine();
      185: UTest.Records.RecordMethodCall();

      // === RECORD TESTS - Complex ===
      186: UTest.Records.RecordInIfStatement();
      187: UTest.Records.RecordInWhileLoop();
      188: UTest.Records.RecordInFunction();
      189: UTest.Records.RecordComplexNesting();

      // === RECORD TESTS - Initialization ===
      190: UTest.Records.RecordStaticInitialization();
      191: UTest.Records.RecordRuntimeInitialization();
      192: UTest.Records.RecordPartialInitialization();

      // === RECORD TESTS - Pointers ===
      193: UTest.Records.PointerToRecord();
      194: UTest.Records.RecordPointerDereference();
      195: UTest.Records.RecordPointerFieldAccess();

      // === POINTER TESTS - Declaration ===
      196: UTest.Pointers.SimplePointerDeclaration();
      197: UTest.Pointers.PointerToInt();
      198: UTest.Pointers.PointerToFloat();
      199: UTest.Pointers.PointerToString();
      200: UTest.Pointers.PointerToRecord();

      // === POINTER TESTS - Address-Of ===
      201: UTest.Pointers.AddressOfVariable();
      202: UTest.Pointers.AddressOfArrayElement();
      203: UTest.Pointers.AddressOfRecordField();

      // === POINTER TESTS - Dereference ===
      204: UTest.Pointers.PointerDereference();
      205: UTest.Pointers.PointerDereferenceAssignment();
      206: UTest.Pointers.PointerDereferenceExpression();

      // === POINTER TESTS - Nil ===
      207: UTest.Pointers.NilPointer();
      208: UTest.Pointers.NilPointerAssignment();
      209: UTest.Pointers.NilPointerComparison();
      210: UTest.Pointers.PointerNilCheck();

      // === POINTER TESTS - Arithmetic ===
      211: UTest.Pointers.PointerIncrement();
      212: UTest.Pointers.PointerDecrement();
      213: UTest.Pointers.PointerAddition();
      214: UTest.Pointers.PointerSubtraction();
      215: UTest.Pointers.PointerDifference();

      // === POINTER TESTS - Pointer to Pointer ===
      216: UTest.Pointers.PointerToPointer();
      217: UTest.Pointers.DoublePointerDereference();
      218: UTest.Pointers.PointerToPointerAssignment();

      // === POINTER TESTS - Parameters ===
      219: UTest.Pointers.PointerParameterByValue();
      220: UTest.Pointers.PointerParameterByConst();
      221: UTest.Pointers.PointerParameterByVar();
      222: UTest.Pointers.PointerReturnValue();

      // === POINTER TESTS - To Arrays ===
      223: UTest.Pointers.PointerToArray();
      224: UTest.Pointers.PointerArrayIndexing();
      225: UTest.Pointers.PointerArrayIteration();

      // === POINTER TESTS - To Records ===
      226: UTest.Pointers.PointerToRecordField();
      227: UTest.Pointers.PointerToNestedRecord();
      228: UTest.Pointers.RecordPointerAssignment();

      // === POINTER TESTS - Function Pointers ===
      229: UTest.Pointers.PointerToFunction();
      230: UTest.Pointers.FunctionPointerCall();
      231: UTest.Pointers.FunctionPointerParameter();

      // === POINTER TESTS - Complex ===
      232: UTest.Pointers.PointerInLoop();
      233: UTest.Pointers.PointerInIfStatement();
      234: UTest.Pointers.PointerSwap();
      235: UTest.Pointers.PointerLinkedStructure();

      // === POINTER TESTS - Type Casting ===
      236: UTest.Pointers.PointerTypeCast();
      237: UTest.Pointers.VoidPointer();
      238: UTest.Pointers.PointerConversion();

      // === CONTROL FLOW TESTS - Repeat-Until ===
      239: UTest.ControlFlow.SimpleRepeatUntil();
      240: UTest.ControlFlow.RepeatUntilWithCounter();
      241: UTest.ControlFlow.RepeatUntilWithCondition();
      242: UTest.ControlFlow.NestedRepeatUntil();

      // === CONTROL FLOW TESTS - For-Downto ===
      243: UTest.ControlFlow.SimpleForDownto();
      244: UTest.ControlFlow.ForDowntoWithStep();
      245: UTest.ControlFlow.ForDowntoWithArray();
      246: UTest.ControlFlow.NestedForDownto();

      // === CONTROL FLOW TESTS - Case ===
      247: UTest.ControlFlow.SimpleCaseStatement();
      248: UTest.ControlFlow.CaseWithMultipleValues();
      249: UTest.ControlFlow.CaseWithRanges();
      250: UTest.ControlFlow.CaseWithElse();
      251: UTest.ControlFlow.NestedCase();
      252: UTest.ControlFlow.CaseInLoop();

      // === CONTROL FLOW TESTS - Compound ===
      253: UTest.ControlFlow.CompoundInIf();
      254: UTest.ControlFlow.CompoundInWhile();
      255: UTest.ControlFlow.CompoundInFor();
      256: UTest.ControlFlow.NestedCompound();

      // === CONTROL FLOW TESTS - Nested ===
      257: UTest.ControlFlow.IfInsideWhile();
      258: UTest.ControlFlow.WhileInsideFor();
      259: UTest.ControlFlow.ForInsideIf();
      260: UTest.ControlFlow.NestedLoopsThreeDeep();

      // === CONTROL FLOW TESTS - Break/Continue ===
      261: UTest.ControlFlow.BreakInLoop();
      262: UTest.ControlFlow.BreakInNestedLoop();
      263: UTest.ControlFlow.ContinueInLoop();
      264: UTest.ControlFlow.ContinueInNestedLoop();

      // === CONTROL FLOW TESTS - Complex ===
      265: UTest.ControlFlow.MultipleIfElseIf();
      266: UTest.ControlFlow.CaseWithComplexExpression();
      267: UTest.ControlFlow.LoopWithMultipleExits();
      268: UTest.ControlFlow.ControlFlowInFunction();

      // === CONTROL FLOW TESTS - Edge Cases ===
      269: UTest.ControlFlow.EmptyLoop();
      270: UTest.ControlFlow.SingleIterationLoop();
      271: UTest.ControlFlow.InfiniteLoopWithBreak();
      272: UTest.ControlFlow.ComplexNestedStructure();

      // === TYPE TESTS - Type Aliases ===
      273: UTest.Types.SimpleTypeAlias();
      274: UTest.Types.IntegerTypeAlias();
      275: UTest.Types.FloatTypeAlias();
      276: UTest.Types.StringTypeAlias();
      277: UTest.Types.BooleanTypeAlias();

      // === TYPE TESTS - Record Types ===
      278: UTest.Types.RecordTypeDeclaration();
      279: UTest.Types.NestedRecordTypes();
      280: UTest.Types.RecordTypeAlias();

      // === TYPE TESTS - Array Types ===
      281: UTest.Types.ArrayTypeDeclaration();
      282: UTest.Types.MultiDimArrayType();
      283: UTest.Types.ArrayTypeAlias();

      // === TYPE TESTS - Pointer Types ===
      284: UTest.Types.PointerTypeDeclaration();
      285: UTest.Types.PointerToRecordType();
      286: UTest.Types.PointerTypeAlias();

      // === TYPE TESTS - Function Types ===
      287: UTest.Types.FunctionTypeDeclaration();
      288: UTest.Types.ProcedureTypeDeclaration();
      289: UTest.Types.FunctionTypeAlias();

      // === TYPE TESTS - Enum Types ===
      290: UTest.Types.EnumTypeDeclaration();
      291: UTest.Types.EnumWithValues();
      292: UTest.Types.EnumTypeAlias();

      // === TYPE TESTS - Subrange Types ===
      293: UTest.Types.SubrangeTypeDeclaration();
      294: UTest.Types.SubrangeInArray();
      295: UTest.Types.SubrangeVariable();

      // === TYPE TESTS - Type Casting ===
      296: UTest.Types.IntToFloatCast();
      297: UTest.Types.FloatToIntCast();
      298: UTest.Types.PointerCast();
      299: UTest.Types.RecordCast();

      // === TYPE TESTS - Type Conversion ===
      300: UTest.Types.ExplicitConversion();
      301: UTest.Types.ImplicitConversion();
      302: UTest.Types.StringConversion();

      // === TYPE TESTS - Complex Types ===
      303: UTest.Types.ArrayOfRecordType();
      304: UTest.Types.RecordWithArrayType();
      305: UTest.Types.PointerToArrayType();
      306: UTest.Types.NestedTypeDeclarations();

      // === TYPE TESTS - In Parameters ===
      307: UTest.Types.CustomTypeParameter();
      308: UTest.Types.CustomTypeReturn();
      309: UTest.Types.CustomTypeByRef();

      // === TYPE TESTS - Scope ===
      310: UTest.Types.TypeInProgram();
      311: UTest.Types.TypeInModule();
      312: UTest.Types.TypeVisibility();

      // === PARAMETER TESTS - Basic ===
      313: UTest.Parameters.ParameterByValue();
      314: UTest.Parameters.ParameterByConst();
      315: UTest.Parameters.ParameterByVar();
      316: UTest.Parameters.ParameterByOut();
      317: UTest.Parameters.NoParameters();

      // === PARAMETER TESTS - Multiple ===
      318: UTest.Parameters.MultipleValueParameters();
      319: UTest.Parameters.MixedParameterModes();
      320: UTest.Parameters.ManyParameters();

      // === PARAMETER TESTS - Types ===
      321: UTest.Parameters.IntParameter();
      322: UTest.Parameters.FloatParameter();
      323: UTest.Parameters.StringParameter();
      324: UTest.Parameters.BoolParameter();
      325: UTest.Parameters.ArrayParameter();
      326: UTest.Parameters.RecordParameter();
      327: UTest.Parameters.PointerParameter();

      // === PARAMETER TESTS - Out ===
      328: UTest.Parameters.SimpleOutParameter();
      329: UTest.Parameters.MultipleOutParameters();
      330: UTest.Parameters.OutParameterWithReturn();
      331: UTest.Parameters.OutParameterInRecord();

      // === PARAMETER TESTS - Arrays ===
      332: UTest.Parameters.ArrayByValue();
      333: UTest.Parameters.ArrayByConst();
      334: UTest.Parameters.ArrayByVar();
      335: UTest.Parameters.ArrayByOut();
      336: UTest.Parameters.MultiDimArrayParameter();

      // === PARAMETER TESTS - Records ===
      337: UTest.Parameters.RecordByValue();
      338: UTest.Parameters.RecordByConst();
      339: UTest.Parameters.RecordByVar();
      340: UTest.Parameters.RecordByOut();
      341: UTest.Parameters.NestedRecordParameter();

      // === PARAMETER TESTS - Pointers ===
      342: UTest.Parameters.PointerByValue();
      343: UTest.Parameters.PointerByConst();
      344: UTest.Parameters.PointerByVar();
      345: UTest.Parameters.PointerByOut();
      346: UTest.Parameters.PointerToPointerParameter();

      // === PARAMETER TESTS - Complex ===
      347: UTest.Parameters.ArrayOfRecordsParameter();
      348: UTest.Parameters.RecordWithArrayParameter();
      349: UTest.Parameters.PointerToRecordParameter();
      350: UTest.Parameters.FunctionPointerParameter();

      // === PARAMETER TESTS - Edge Cases ===
      351: UTest.Parameters.UnusedParameter();
      352: UTest.Parameters.ParameterShadowsGlobal();
      353: UTest.Parameters.ParameterModification();
      354: UTest.Parameters.ConstParameterNoModify();

      // === PARAMETER TESTS - Variadic ===
      355: UTest.Parameters.VariadicParameters();
      356: UTest.Parameters.VariadicWithFixedParams();

      // === CONDITIONAL COMPILATION TESTS - Define/Undef ===
      357: UTest.ConditionalCompilation.SimpleDefine();
      358: UTest.ConditionalCompilation.DefineMultiple();
      359: UTest.ConditionalCompilation.UndefSymbol();
      360: UTest.ConditionalCompilation.RedefinedSymbol();

      // === CONDITIONAL COMPILATION TESTS - Ifdef/Ifndef ===
      361: UTest.ConditionalCompilation.IfdefTrue();
      362: UTest.ConditionalCompilation.IfdefFalse();
      363: UTest.ConditionalCompilation.IfndefTrue();
      364: UTest.ConditionalCompilation.IfndefFalse();
      365: UTest.ConditionalCompilation.IfdefWithElse();
      366: UTest.ConditionalCompilation.IfndefWithElse();
      367: UTest.ConditionalCompilation.NestedIfdef();
      368: UTest.ConditionalCompilation.NestedIfndef();

      // === CONDITIONAL COMPILATION TESTS - Complex Cases ===
      369: UTest.ConditionalCompilation.MultipleConditionals();
      370: UTest.ConditionalCompilation.ConditionalInProgram();
      371: UTest.ConditionalCompilation.ConditionalInModule();
      372: UTest.ConditionalCompilation.ConditionalCodeBlock();
      373: UTest.ConditionalCompilation.ConditionalVariableDeclaration();
      374: UTest.ConditionalCompilation.ConditionalRoutineDeclaration();
      375: UTest.ConditionalCompilation.MixedConditionals();
      376: UTest.ConditionalCompilation.DeepNestedConditionals();
    end;

    except
      on E: Exception do
      begin
        TNPUtils.PrintLn('');
        TNPUtils.PrintLn('Test failed with error:');
        TNPUtils.PrintLn('========================================');
        TNPUtils.PrintLn(E.ClassName + ': ' + E.Message);
        TNPUtils.PrintLn('========================================');
      end;
    end;
  end;

  if not LIsAutomated then
    TNPUtils.Pause();
end;

end.
