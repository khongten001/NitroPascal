{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTest.ConditionalCompilation;

interface

// === CONDITIONAL COMPILATION TESTS - Define/Undef ===
procedure SimpleDefine();
procedure DefineMultiple();
procedure UndefSymbol();
procedure RedefinedSymbol();

// === CONDITIONAL COMPILATION TESTS - Ifdef/Ifndef ===
procedure IfdefTrue();
procedure IfdefFalse();
procedure IfndefTrue();
procedure IfndefFalse();
procedure IfdefWithElse();
procedure IfndefWithElse();
procedure NestedIfdef();
procedure NestedIfndef();

// === CONDITIONAL COMPILATION TESTS - Complex Cases ===
procedure MultipleConditionals();
procedure ConditionalInProgram();
procedure ConditionalInModule();
procedure ConditionalCodeBlock();
procedure ConditionalVariableDeclaration();
procedure ConditionalRoutineDeclaration();
procedure MixedConditionals();
procedure DeepNestedConditionals();

implementation

uses
  UTest.Common;

{ === CONDITIONAL COMPILATION TESTS - Define/Undef === }

procedure SimpleDefine();
const
  CSource =
  '''
  #define DEBUG
  
  program Test;
  begin
  end.
  ''';
begin
  RunCompilerTest('Simple #define', CSource);
end;

procedure DefineMultiple();
const
  CSource =
  '''
  #define DEBUG
  #define TESTING
  #define VERBOSE
  
  program Test;
  begin
  end.
  ''';
begin
  RunCompilerTest('Multiple #define', CSource);
end;

procedure UndefSymbol();
const
  CSource =
  '''
  #define DEBUG
  #undef DEBUG
  
  program Test;
  begin
  end.
  ''';
begin
  RunCompilerTest('#undef Symbol', CSource);
end;

procedure RedefinedSymbol();
const
  CSource =
  '''
  #define VERSION
  #undef VERSION
  #define VERSION
  
  program Test;
  begin
  end.
  ''';
begin
  RunCompilerTest('Redefined Symbol', CSource);
end;

{ === CONDITIONAL COMPILATION TESTS - Ifdef/Ifndef === }

procedure IfdefTrue();
const
  CSource =
  '''
  #define DEBUG
  
  program Test;
  var
    LX: Integer;
  begin
    #ifdef DEBUG
    LX := 42;
    #endif
  end.
  ''';
begin
  RunCompilerTest('#ifdef True Condition', CSource);
end;

procedure IfdefFalse();
const
  CSource =
  '''
  program Test;
  var
    LX: Integer;
  begin
    #ifdef DEBUG
    LX := 42;
    #endif
    LX := 10;
  end.
  ''';
begin
  RunCompilerTest('#ifdef False Condition', CSource);
end;

procedure IfndefTrue();
const
  CSource =
  '''
  program Test;
  var
    LX: Integer;
  begin
    #ifndef DEBUG
    LX := 42;
    #endif
  end.
  ''';
begin
  RunCompilerTest('#ifndef True Condition', CSource);
end;

procedure IfndefFalse();
const
  CSource =
  '''
  #define DEBUG
  
  program Test;
  var
    LX: Integer;
  begin
    #ifndef DEBUG
    LX := 42;
    #endif
    LX := 10;
  end.
  ''';
begin
  RunCompilerTest('#ifndef False Condition', CSource);
end;

procedure IfdefWithElse();
const
  CSource =
  '''
  #define DEBUG
  
  program Test;
  var
    LX: Integer;
  begin
    #ifdef DEBUG
    LX := 42;
    #else
    LX := 0;
    #endif
  end.
  ''';
begin
  RunCompilerTest('#ifdef With #else', CSource);
end;

procedure IfndefWithElse();
const
  CSource =
  '''
  #define RELEASE
  
  program Test;
  var
    LX: Integer;
  begin
    #ifndef DEBUG
    LX := 100;
    #else
    LX := 0;
    #endif
  end.
  ''';
begin
  RunCompilerTest('#ifndef With #else', CSource);
end;

procedure NestedIfdef();
const
  CSource =
  '''
  #define DEBUG
  #define VERBOSE
  
  program Test;
  var
    LX: Integer;
  begin
    #ifdef DEBUG
      #ifdef VERBOSE
      LX := 42;
      #endif
    #endif
  end.
  ''';
begin
  RunCompilerTest('Nested #ifdef', CSource);
end;

procedure NestedIfndef();
const
  CSource =
  '''
  program Test;
  var
    LX: Integer;
  begin
    #ifndef RELEASE
      #ifndef TESTING
      LX := 42;
      #endif
    #endif
  end.
  ''';
begin
  RunCompilerTest('Nested #ifndef', CSource);
end;

{ === CONDITIONAL COMPILATION TESTS - Complex Cases === }

procedure MultipleConditionals();
const
  CSource =
  '''
  #define FEATURE_A
  #define FEATURE_B
  
  program Test;
  var
    LX: Integer;
    LY: Integer;
  begin
    #ifdef FEATURE_A
    LX := 1;
    #endif
    
    #ifdef FEATURE_B
    LY := 2;
    #endif
    
    #ifndef FEATURE_C
    LX := LX + LY;
    #endif
  end.
  ''';
begin
  RunCompilerTest('Multiple Conditionals', CSource);
end;

procedure ConditionalInProgram();
const
  CSource =
  '''
  #define DEBUG
  
  program Test;
  var
    LValue: Integer;
  begin
    #ifdef DEBUG
    LValue := 42;
    #else
    LValue := 0;
    #endif
  end.
  ''';
begin
  RunCompilerTest('Conditional In Program', CSource);
end;

procedure ConditionalInModule();
const
  CSource =
  '''
  #define EXPORTED
  
  module TestModule;
  
  #ifdef EXPORTED
  public routine GetValue(): Integer;
  begin
    return 42;
  end;
  #endif
  
  end.
  ''';
begin
  RunCompilerTest('Conditional In Module', CSource);
end;

procedure ConditionalCodeBlock();
const
  CSource =
  '''
  #define FEATURE_ENABLED
  
  program Test;
  var
    LX: Integer;
    LY: Integer;
  begin
    LX := 10;
    
    #ifdef FEATURE_ENABLED
    LY := 20;
    LX := LX + LY;
    #else
    LY := 5;
    LX := LX - LY;
    #endif
  end.
  ''';
begin
  RunCompilerTest('Conditional Code Block', CSource);
end;

procedure ConditionalVariableDeclaration();
const
  CSource =
  '''
  #define USE_EXTENDED
  
  program Test;
  var
    LX: Integer;
    #ifdef USE_EXTENDED
    LY: Integer;
    LZ: Integer;
    #endif
  begin
    LX := 10;
    #ifdef USE_EXTENDED
    LY := 20;
    LZ := 30;
    #endif
  end.
  ''';
begin
  RunCompilerTest('Conditional Variable Declaration', CSource);
end;

procedure ConditionalRoutineDeclaration();
const
  CSource =
  '''
  #define INCLUDE_HELPER
  program Test;

  #ifdef INCLUDE_HELPER
  routine Helper(): Integer;
  begin
    return 42;
  end;
  #endif

  #ifdef INCLUDE_HELPER
  var
    LX: Integer;
  #endif

  begin
    #ifdef INCLUDE_HELPER
    LX := Helper();
    #endif
  end.
  ''';
begin
  RunCompilerTest('Conditional Routine Declaration', CSource);
end;

procedure MixedConditionals();
const
  CSource =
  '''
  #define FEATURE_A
  #undef FEATURE_B
  #define FEATURE_B
  
  program Test;
  var
    LX: Integer;
  begin
    #ifdef FEATURE_A
      #ifdef FEATURE_B
      LX := 42;
      #else
      LX := 10;
      #endif
    #else
      #ifndef FEATURE_C
      LX := 0;
      #endif
    #endif
  end.
  ''';
begin
  RunCompilerTest('Mixed Conditionals', CSource);
end;

procedure DeepNestedConditionals();
const
  CSource =
  '''
  #define LEVEL1
  #define LEVEL2
  #define LEVEL3
  
  program Test;
  var
    LX: Integer;
  begin
    #ifdef LEVEL1
      #ifdef LEVEL2
        #ifdef LEVEL3
        LX := 42;
        #else
        LX := 30;
        #endif
      #else
      LX := 20;
      #endif
    #else
    LX := 10;
    #endif
  end.
  ''';
begin
  RunCompilerTest('Deep Nested Conditionals', CSource);
end;

end.
