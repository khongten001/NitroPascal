{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Lexer;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Character,
  System.Generics.Collections,
  System.Rtti,
  NitroPascal.Types;

type
  { TNPLexer }
  TNPLexer = class
  private
    type
      TConditionalBlock = record
        ConditionWasTrue: Boolean;  // What did #ifdef/#ifndef evaluate to?
        InElseBranch: Boolean;      // Are we in the else branch?
        HasSeenElse: Boolean;       // Have we seen #else yet?
        StartLine: Integer;         // Line where block started (for error reporting)
      end;
  private
    FSource: string;
    FFilename: string;
    FPosition: Integer;
    FLine: Integer;
    FColumn: Integer;
    FErrors: TList<TNPError>;
    FCurrent: Char;
    
    // Conditional compilation state
    FDefines: TDictionary<string, Boolean>;
    FConditionalStack: TStack<TConditionalBlock>;
    
    procedure Advance();
    function Peek(const AOffset: Integer = 1): Char;
    function IsEOF(): Boolean;
    function IsHexDigit(const ACh: Char): Boolean;
    
    procedure SkipWhitespace();
    procedure SkipLineComment();
    procedure SkipBlockComment();
    
    function ScanIdentifierOrKeyword(): TNPToken;
    function ScanNumber(): TNPToken;
    function ScanString(): TNPToken;
    function ScanChar(): TNPToken;
    function ScanDirective(): TNPToken;
    
    function GetCurrentPos(): TNPSourcePos;
    procedure AddError(const AMsg: string; const ACode: Integer = 0);
    
    function IsKeyword(const AIdent: string): TNPTokenKind;
    function ProcessEscapeSequence(const ACh: Char): Char;
    
    // Conditional compilation
    function IsBlockActive(): Boolean;
    procedure SkipToNextLine();
    procedure ProcessPreprocessorDirective();
    procedure ProcessDefine(const ASymbol: string);
    procedure ProcessUndef(const ASymbol: string);
    procedure ProcessIfdef(const ASymbol: string);
    procedure ProcessIfndef(const ASymbol: string);
    procedure ProcessElse();
    procedure ProcessEndif();
    
  public
    constructor Create(const ASource, AFilename: string);
    destructor Destroy; override;
    
    procedure AddDefine(const ASymbol: string);
    
    function NextToken(): TNPToken;
    
    function HasErrors(): Boolean;
    function GetErrors(): TArray<TNPError>;
  end;

implementation

const
  KEYWORDS: array[0..40] of record
    Text: string;
    Kind: TNPTokenKind;
  end = (
    (Text: 'and';      Kind: tkAnd),
    (Text: 'array';    Kind: tkArray),
    (Text: 'begin';    Kind: tkBegin),
    (Text: 'break';    Kind: tkBreak),
    (Text: 'case';     Kind: tkCase),
    (Text: 'const';    Kind: tkConst),
    (Text: 'continue'; Kind: tkContinue),
    (Text: 'div';      Kind: tkDiv),
    (Text: 'do';       Kind: tkDo),
    (Text: 'downto';   Kind: tkDownto),
    (Text: 'else';     Kind: tkElse),
    (Text: 'end';      Kind: tkEnd),
    (Text: 'extern';   Kind: tkExtern),
    (Text: 'false';    Kind: tkFalse),
    (Text: 'finalize'; Kind: tkFinalize),
    (Text: 'for';      Kind: tkFor),
    (Text: 'halt';     Kind: tkHalt),
    (Text: 'if';       Kind: tkIf),
    (Text: 'import';   Kind: tkImport),
    (Text: 'library';  Kind: tkLibrary),
    (Text: 'mod';      Kind: tkMod),
    (Text: 'module';   Kind: tkModule),
    (Text: 'shl';      Kind: tkShl),
    (Text: 'shr';      Kind: tkShr),
    (Text: 'nil';      Kind: tkNil),
    (Text: 'not';      Kind: tkNot),
    (Text: 'of';       Kind: tkOf),
    (Text: 'or';       Kind: tkOr),
    (Text: 'program';  Kind: tkProgram),
    (Text: 'public';   Kind: tkPublic),
    (Text: 'repeat';   Kind: tkRepeat),
    (Text: 'return';   Kind: tkReturn),
    (Text: 'routine';  Kind: tkRoutine),
    (Text: 'then';     Kind: tkThen),
    (Text: 'to';       Kind: tkTo),
    (Text: 'true';     Kind: tkTrue),
    (Text: 'type';     Kind: tkType),
    (Text: 'until';    Kind: tkUntil),
    (Text: 'var';      Kind: tkVar),
    (Text: 'while';    Kind: tkWhile),
    (Text: 'xor';      Kind: tkXor)
  );

{ TNPLexer }

constructor TNPLexer.Create(const ASource, AFilename: string);
begin
  inherited Create();
  FSource := ASource;
  FFilename := AFilename;
  FPosition := 1;
  FLine := 1;
  FColumn := 1;
  FErrors := TList<TNPError>.Create();
  FDefines := TDictionary<string, Boolean>.Create();
  FConditionalStack := TStack<TConditionalBlock>.Create();
  
  if not FSource.IsEmpty then
    FCurrent := FSource[FPosition]
  else
    FCurrent := #0;
end;

destructor TNPLexer.Destroy;
begin
  FConditionalStack.Free();
  FDefines.Free();
  FErrors.Free();
  inherited;
end;

procedure TNPLexer.Advance();
begin
  if FPosition > FSource.Length then
  begin
    FCurrent := #0;
    Exit;
  end;
  
  if FCurrent = #10 then
  begin
    Inc(FLine);
    FColumn := 1;
  end
  else
    Inc(FColumn);
  
  Inc(FPosition);
  if FPosition <= FSource.Length then
    FCurrent := FSource[FPosition]
  else
    FCurrent := #0;
end;

function TNPLexer.Peek(const AOffset: Integer): Char;
var
  LPos: Integer;
begin
  LPos := FPosition + AOffset;
  if (LPos > 0) and (LPos <= FSource.Length) then
    Result := FSource[LPos]
  else
    Result := #0;
end;

function TNPLexer.IsEOF(): Boolean;
begin
  Result := FPosition > FSource.Length;
end;

function TNPLexer.IsHexDigit(const ACh: Char): Boolean;
begin
  Result := ACh.IsDigit() or ((ACh >= 'A') and (ACh <= 'F')) or ((ACh >= 'a') and (ACh <= 'f'));
end;

procedure TNPLexer.SkipWhitespace();
begin
  while not IsEOF() and FCurrent.IsWhiteSpace() do
    Advance();
end;

procedure TNPLexer.SkipLineComment();
begin
  // Skip //
  Advance();
  Advance();
  
  while not IsEOF() and (FCurrent <> #10) do
    Advance();
end;

procedure TNPLexer.SkipBlockComment();
var
  LStartLine: Integer;
  LIsParenStyle: Boolean;
begin
  LStartLine := FLine;
  LIsParenStyle := FCurrent = '(';
  
  // Skip (* or {
  Advance();
  if LIsParenStyle then
    Advance();
  
  while not IsEOF() do
  begin
    if LIsParenStyle then
    begin
      if (FCurrent = '*') and (Peek() = ')') then
      begin
        Advance(); // *
        Advance(); // )
        Exit;
      end;
    end
    else
    begin
      if FCurrent = '}' then
      begin
        Advance();
        Exit;
      end;
    end;
    Advance();
  end;
  
  AddError(Format('Unterminated comment started at line %d', [LStartLine]));
end;

function TNPLexer.GetCurrentPos(): TNPSourcePos;
begin
  Result := TNPSourcePos.Create(FFilename, FLine, FColumn);
end;

procedure TNPLexer.AddError(const AMsg: string; const ACode: Integer);
begin
  FErrors.Add(TNPError.Create(GetCurrentPos(), AMsg, ACode));
end;

function TNPLexer.IsKeyword(const AIdent: string): TNPTokenKind;
var
  LI: Integer;
begin
  for LI := Low(KEYWORDS) to High(KEYWORDS) do
  begin
    if KEYWORDS[LI].Text = AIdent then
      Exit(KEYWORDS[LI].Kind);
  end;
  Result := tkIdentifier;
end;

function TNPLexer.ProcessEscapeSequence(const ACh: Char): Char;
begin
  case ACh of
    'n': Result := #10;
    't': Result := #9;
    'r': Result := #13;
    '\': Result := '\';
    '"': Result := '"';
    '''': Result := '''';
    '0': Result := #0;
  else
    Result := ACh;
  end;
end;

function TNPLexer.ScanIdentifierOrKeyword(): TNPToken;
var
  LStart: Integer;
  LStartPos: TNPSourcePos;
  LIdent: string;
  LKind: TNPTokenKind;
begin
  LStartPos := GetCurrentPos();
  LStart := FPosition;
  
  while not IsEOF() and (FCurrent.IsLetterOrDigit() or (FCurrent = '_')) do
    Advance();
  
  LIdent := FSource.Substring(LStart - 1, FPosition - LStart);
  LKind := IsKeyword(LIdent);
  
  Result := TNPToken.Create(LKind, LStartPos, LIdent);
end;

function TNPLexer.ScanNumber(): TNPToken;
var
  LStart: Integer;
  LStartPos: TNPSourcePos;
  LLexeme: string;
  LIsFloat: Boolean;
  LIsHex: Boolean;
  LIsBinary: Boolean;
  LValue: Int64;
  LFloatValue: Double;
begin
  LStartPos := GetCurrentPos();
  LStart := FPosition;
  LIsFloat := False;
  LIsHex := False;
  LIsBinary := False;
  
  // Check for hex (0x) or binary (0b)
  if (FCurrent = '0') and not IsEOF() then
  begin
    if (Peek() = 'x') or (Peek() = 'X') then
    begin
      LIsHex := True;
      Advance(); // 0
      Advance(); // x
      LStart := FPosition;
      while not IsEOF() and IsHexDigit(FCurrent) do
        Advance();
    end
    else if (Peek() = 'b') or (Peek() = 'B') then
    begin
      LIsBinary := True;
      Advance(); // 0
      Advance(); // b
      LStart := FPosition;
      while not IsEOF() and ((FCurrent = '0') or (FCurrent = '1')) do
        Advance();
    end;
  end;
  
  // Regular decimal number
  if not LIsHex and not LIsBinary then
  begin
    while not IsEOF() and FCurrent.IsDigit() do
      Advance();
    
    // Check for decimal point
    if (FCurrent = '.') and (Peek() <> '.') then
    begin
      LIsFloat := True;
      Advance();
      while not IsEOF() and FCurrent.IsDigit() do
        Advance();
    end;
    
    // Check for exponent
    if (FCurrent = 'e') or (FCurrent = 'E') then
    begin
      LIsFloat := True;
      Advance();
      if (FCurrent = '+') or (FCurrent = '-') then
        Advance();
      while not IsEOF() and FCurrent.IsDigit() do
        Advance();
    end;
  end;
  
  LLexeme := FSource.Substring(LStart - 1, FPosition - LStart);
  
  if LIsFloat then
  begin
    if TryStrToFloat(LLexeme, LFloatValue) then
      Result := TNPToken.Create(tkFloat, LStartPos, LLexeme, TValue.From<Double>(LFloatValue))
    else
    begin
      AddError('Invalid float literal: ' + LLexeme);
      Result := TNPToken.Create(tkError, LStartPos, LLexeme);
    end;
  end
  else
  begin
    try
      if LIsHex then
        LValue := StrToInt64('$' + LLexeme)
      else if LIsBinary then
      begin
        LValue := 0;
        for var LCh in LLexeme do
          LValue := (LValue shl 1) or Ord(LCh = '1');
      end
      else
        LValue := StrToInt64(LLexeme);
      
      Result := TNPToken.Create(tkInteger, LStartPos, LLexeme, TValue.From<Int64>(LValue));
    except
      on E: Exception do
      begin
        AddError('Invalid integer literal: ' + LLexeme);
        Result := TNPToken.Create(tkError, LStartPos, LLexeme);
      end;
    end;
  end;
end;

function TNPLexer.ScanString(): TNPToken;
var
  LStartPos: TNPSourcePos;
  LStartLine: Integer;
  LValue: string;
begin
  LStartPos := GetCurrentPos();
  LStartLine := FLine;
  LValue := '';
  
  Advance(); // Skip opening "
  
  while not IsEOF() and (FCurrent <> '"') do
  begin
    if FCurrent = '\' then
    begin
      Advance();
      if not IsEOF() then
      begin
        LValue := LValue + ProcessEscapeSequence(FCurrent);
        Advance();
      end;
    end
    else
    begin
      LValue := LValue + FCurrent;
      Advance();
    end;
  end;
  
  if IsEOF() then
  begin
    AddError(Format('Unterminated string started at line %d', [LStartLine]));
    Result := TNPToken.Create(tkError, LStartPos, LValue);
  end
  else
  begin
    Advance(); // Skip closing "
    Result := TNPToken.Create(tkString, LStartPos, '"' + LValue + '"', TValue.From<string>(LValue));
  end;
end;

function TNPLexer.ScanChar(): TNPToken;
var
  LStartPos: TNPSourcePos;
  LValue: Char;
begin
  LStartPos := GetCurrentPos();
  
  Advance(); // Skip opening '
  
  if IsEOF() then
  begin
    AddError('Unterminated character literal');
    Exit(TNPToken.Create(tkError, LStartPos, ''''));
  end;
  
  if FCurrent = '\' then
  begin
    Advance();
    if IsEOF() then
    begin
      AddError('Unterminated character literal');
      Exit(TNPToken.Create(tkError, LStartPos, '''\'));
    end;
    LValue := ProcessEscapeSequence(FCurrent);
    Advance();
  end
  else
  begin
    LValue := FCurrent;
    Advance();
  end;
  
  if FCurrent <> '''' then
  begin
    AddError('Unterminated character literal');
    Result := TNPToken.Create(tkError, LStartPos, '''' + LValue);
  end
  else
  begin
    Advance(); // Skip closing '
    Result := TNPToken.Create(tkChar, LStartPos, '''' + LValue + '''', TValue.From<Char>(LValue));
  end;
end;

function TNPLexer.ScanDirective(): TNPToken;
var
  LStartPos: TNPSourcePos;
  LStart: Integer;
  LDirectiveName: string;
  LStringToken: TNPToken;
  LValue: string;
begin
  LStartPos := GetCurrentPos();
  
  // Skip $
  Advance();
  
  // Scan directive name (letters, digits, underscores)
  LStart := FPosition;
  while not IsEOF() and (FCurrent.IsLetterOrDigit() or (FCurrent = '_')) do
    Advance();
  
  if LStart = FPosition then
  begin
    AddError('Expected directive name after $');
    Exit(TNPToken.Create(tkError, LStartPos, '$'));
  end;
  
  LDirectiveName := FSource.Substring(LStart - 1, FPosition - LStart);
  
  // Skip whitespace
  SkipWhitespace();
  
  // Expect quoted string value
  if FCurrent <> '"' then
  begin
    AddError('Directive value must be enclosed in double quotes');
    Exit(TNPToken.Create(tkError, LStartPos, '$' + LDirectiveName));
  end;
  
  // Scan string value (reuse existing string scanner)
  LStringToken := ScanString();
  LValue := LStringToken.Value.AsString;
  
  // Create directive token with name as lexeme, value in Value field
  Result := TNPToken.Create(tkDirective, LStartPos, LDirectiveName, TValue.From<string>(LValue));
end;

{ Conditional Compilation Methods }

function TNPLexer.IsBlockActive(): Boolean;
var
  LBlock: TConditionalBlock;
  LBlockIsActive: Boolean;
begin
  // All blocks in the stack must be active for code to execute
  for LBlock in FConditionalStack do
  begin
    // Determine if this block is active based on which branch we're in
    if LBlock.InElseBranch then
      LBlockIsActive := not LBlock.ConditionWasTrue
    else
      LBlockIsActive := LBlock.ConditionWasTrue;
    
    // If any block in the stack is inactive, the entire stack is inactive
    if not LBlockIsActive then
      Exit(False);
  end;
  
  Result := True;
end;

procedure TNPLexer.SkipToNextLine();
begin
  while not IsEOF() and (FCurrent <> #10) and (FCurrent <> #13) do
    Advance();
  
  if FCurrent = #13 then
  begin
    Advance();
    if FCurrent = #10 then
      Advance();
  end
  else if FCurrent = #10 then
    Advance();
end;

procedure TNPLexer.ProcessDefine(const ASymbol: string);
begin
  if ASymbol.IsEmpty() then
  begin
    AddError('Expected symbol name after #define');
    Exit;
  end;
  
  // Only process define if we're in an active block
  if IsBlockActive() then
    FDefines.AddOrSetValue(ASymbol, True);
end;

procedure TNPLexer.ProcessUndef(const ASymbol: string);
begin
  if ASymbol.IsEmpty() then
  begin
    AddError('Expected symbol name after #undef');
    Exit;
  end;
  
  // Only process undef if we're in an active block
  if IsBlockActive() then
    FDefines.Remove(ASymbol);
end;

procedure TNPLexer.ProcessIfdef(const ASymbol: string);
var
  LBlock: TConditionalBlock;
  LConditionResult: Boolean;
begin
  if ASymbol.IsEmpty() then
  begin
    AddError('Expected symbol name after #ifdef');
    Exit;
  end;
  
  // Evaluate the condition: is the symbol defined?
  LConditionResult := FDefines.ContainsKey(ASymbol);
  
  // Push new block onto stack
  LBlock.ConditionWasTrue := LConditionResult;
  LBlock.InElseBranch := False;
  LBlock.HasSeenElse := False;
  LBlock.StartLine := FLine;
  
  FConditionalStack.Push(LBlock);
end;

procedure TNPLexer.ProcessIfndef(const ASymbol: string);
var
  LBlock: TConditionalBlock;
  LConditionResult: Boolean;
begin
  if ASymbol.IsEmpty() then
  begin
    AddError('Expected symbol name after #ifndef');
    Exit;
  end;
  
  // Evaluate the condition: is the symbol NOT defined?
  LConditionResult := not FDefines.ContainsKey(ASymbol);
  
  // Push new block onto stack
  LBlock.ConditionWasTrue := LConditionResult;
  LBlock.InElseBranch := False;
  LBlock.HasSeenElse := False;
  LBlock.StartLine := FLine;
  
  FConditionalStack.Push(LBlock);
end;

procedure TNPLexer.ProcessElse();
var
  LBlock: TConditionalBlock;
begin
  if FConditionalStack.Count = 0 then
  begin
    AddError('#else without matching #ifdef or #ifndef');
    Exit;
  end;
  
  // Get the top block (pop, modify, push back)
  LBlock := FConditionalStack.Pop();
  
  if LBlock.HasSeenElse then
  begin
    AddError('Multiple #else directives for same conditional block');
    // Still push back to maintain stack state
    FConditionalStack.Push(LBlock);
    Exit;
  end;
  
  // Mark that we're now in the else branch
  LBlock.InElseBranch := True;
  LBlock.HasSeenElse := True;
  
  // Push the modified block back onto the stack
  FConditionalStack.Push(LBlock);
end;

procedure TNPLexer.ProcessEndif();
begin
  if FConditionalStack.Count = 0 then
  begin
    AddError('#endif without matching #ifdef or #ifndef');
    Exit;
  end;
  
  // Pop the top block from the stack
  FConditionalStack.Pop();
end;

procedure TNPLexer.ProcessPreprocessorDirective();
var
  LStart: Integer;
  LDirective: string;
  LSymbol: string;
begin
  Advance(); // Skip #
  
  // Skip leading whitespace
  while not IsEOF() and ((FCurrent = ' ') or (FCurrent = #9)) do
    Advance();
  
  // Read directive name
  LStart := FPosition;
  while not IsEOF() and (FCurrent.IsLetterOrDigit() or (FCurrent = '_')) do
    Advance();
  
  if LStart = FPosition then
  begin
    AddError('Expected preprocessor directive after #');
    SkipToNextLine();
    Exit;
  end;
  
  LDirective := FSource.Substring(LStart - 1, FPosition - LStart).ToLower();
  
  // Skip whitespace
  while not IsEOF() and ((FCurrent = ' ') or (FCurrent = #9)) do
    Advance();
  
  // Read symbol name if applicable
  if (LDirective = 'ifdef') or (LDirective = 'ifndef') or 
     (LDirective = 'define') or (LDirective = 'undef') then
  begin
    LStart := FPosition;
    while not IsEOF() and (FCurrent.IsLetterOrDigit() or (FCurrent = '_')) do
      Advance();
    
    if LStart = FPosition then
    begin
      AddError('Expected symbol name after #' + LDirective);
      SkipToNextLine();
      Exit;
    end;
    
    LSymbol := FSource.Substring(LStart - 1, FPosition - LStart);
  end
  else
    LSymbol := '';
  
  // Process the directive
  if LDirective = 'define' then
    ProcessDefine(LSymbol)
  else if LDirective = 'undef' then
    ProcessUndef(LSymbol)
  else if LDirective = 'ifdef' then
    ProcessIfdef(LSymbol)
  else if LDirective = 'ifndef' then
    ProcessIfndef(LSymbol)
  else if LDirective = 'else' then
    ProcessElse()
  else if LDirective = 'endif' then
    ProcessEndif()
  else
    AddError('Unknown preprocessor directive: #' + LDirective);
  
  // Skip rest of line
  SkipToNextLine();
end;

procedure TNPLexer.AddDefine(const ASymbol: string);
begin
  FDefines.AddOrSetValue(ASymbol, True);
end;

function TNPLexer.NextToken(): TNPToken;
var
  LPos: TNPSourcePos;
begin
  SkipWhitespace();
  
  if IsEOF() then
  begin
    // Check for unclosed conditional blocks at EOF
    if FConditionalStack.Count > 0 then
    begin
      AddError(Format('Unclosed conditional block started at line %d', 
        [FConditionalStack.Peek().StartLine]));
    end;
    Exit(TNPToken.Create(tkEOF, GetCurrentPos(), ''));
  end;
  
  LPos := GetCurrentPos();
  
  // Handle preprocessor directives
  if FCurrent = '#' then
  begin
    ProcessPreprocessorDirective();
    Exit(NextToken());
  end;
  
  // Skip tokens in inactive conditional blocks
  if not IsBlockActive() then
  begin
    SkipToNextLine();
    Exit(NextToken());
  end;
  
  // Comments
  if (FCurrent = '/') and (Peek() = '/') then
  begin
    SkipLineComment();
    Exit(NextToken());
  end;
  
  if (FCurrent = '(') and (Peek() = '*') then
  begin
    SkipBlockComment();
    Exit(NextToken());
  end;
  
  if FCurrent = '{' then
  begin
    SkipBlockComment();
    Exit(NextToken());
  end;
  
  // Identifiers and keywords
  if FCurrent.IsLetter() or (FCurrent = '_') then
    Exit(ScanIdentifierOrKeyword());
  
  // Numbers
  if FCurrent.IsDigit() then
    Exit(ScanNumber());
  
  // String literals
  if FCurrent = '"' then
    Exit(ScanString());
  
  // Character literals
  if FCurrent = '''' then
    Exit(ScanChar());
  
  // Compiler directives
  if FCurrent = '$' then
    Exit(ScanDirective());
  
  // Two-character operators
  if (FCurrent = ':') and (Peek() = '=') then
  begin
    Advance();
    Advance();
    Exit(TNPToken.Create(tkAssign, LPos, ':='));
  end;
  
  if (FCurrent = '<') and (Peek() = '>') then
  begin
    Advance();
    Advance();
    Exit(TNPToken.Create(tkNotEqual, LPos, '<>'));
  end;
  
  if (FCurrent = '<') and (Peek() = '=') then
  begin
    Advance();
    Advance();
    Exit(TNPToken.Create(tkLessEqual, LPos, '<='));
  end;
  
  if (FCurrent = '>') and (Peek() = '=') then
  begin
    Advance();
    Advance();
    Exit(TNPToken.Create(tkGreaterEqual, LPos, '>='));
  end;
  
  if (FCurrent = '.') and (Peek() = '.') then
  begin
    Advance();
    Advance();
    Exit(TNPToken.Create(tkDotDot, LPos, '..'));
  end;
  
  // Single-character tokens
  case FCurrent of
    '+': begin Advance(); Exit(TNPToken.Create(tkPlus, LPos, '+')); end;
    '-': begin Advance(); Exit(TNPToken.Create(tkMinus, LPos, '-')); end;
    '*': begin Advance(); Exit(TNPToken.Create(tkStar, LPos, '*')); end;
    '/': begin Advance(); Exit(TNPToken.Create(tkSlash, LPos, '/')); end;
    '=': begin Advance(); Exit(TNPToken.Create(tkEquals, LPos, '=')); end;
    '<': begin Advance(); Exit(TNPToken.Create(tkLess, LPos, '<')); end;
    '>': begin Advance(); Exit(TNPToken.Create(tkGreater, LPos, '>')); end;
    '(': begin Advance(); Exit(TNPToken.Create(tkLParen, LPos, '(')); end;
    ')': begin Advance(); Exit(TNPToken.Create(tkRParen, LPos, ')')); end;
    '[': begin Advance(); Exit(TNPToken.Create(tkLBracket, LPos, '(')); end;
    ']': begin Advance(); Exit(TNPToken.Create(tkRBracket, LPos, ']')); end;
    '.': begin Advance(); Exit(TNPToken.Create(tkDot, LPos, '.')); end;
    ',': begin Advance(); Exit(TNPToken.Create(tkComma, LPos, ',')); end;
    ':': begin Advance(); Exit(TNPToken.Create(tkColon, LPos, ':')); end;
    ';': begin Advance(); Exit(TNPToken.Create(tkSemicolon, LPos, ';')); end;
    '^': begin Advance(); Exit(TNPToken.Create(tkCaret, LPos, '^')); end;
    '@': begin Advance(); Exit(TNPToken.Create(tkAt, LPos, '@')); end;
  else
    AddError('Unexpected character: ' + FCurrent);
    Advance();
    Result := TNPToken.Create(tkError, LPos, FCurrent);
  end;
end;

function TNPLexer.HasErrors(): Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPLexer.GetErrors(): TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

end.
