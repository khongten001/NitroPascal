{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Errors;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections;

const
  // Common error types (can be extended by any unit)
  NP_ERROR_SYNTAX       = 'SyntaxError';
  NP_ERROR_FILENOTFOUND = 'FileNotFound';
  NP_ERROR_ACCESSDENIED = 'AccessDenied';
  NP_ERROR_INVALID      = 'InvalidInput';
  NP_ERROR_IO           = 'IOError';
  NP_ERROR_INTERNAL     = 'InternalError';

type
  { TNPError }
  TNPError = record
    ErrorType: string;
    Line: Integer;
    Column: Integer;
    FileName: string;
    Message: string;
  end;

  { TNPErrorManager }
  TNPErrorManager = class
  strict private
    FErrors: TList<TNPError>;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure AddError(const AType: string; const ALine: Integer; const ACol: Integer;
      const AFileName: string; const AMsg: string); overload;
    procedure AddError(const AType: string; const AMsg: string); overload;
    
    function HasErrors: Boolean;
    function ErrorCount: Integer;
    function GetErrors: TArray<TNPError>;
    procedure ClearErrors;
  end;

implementation

{ TNPErrorManager }

constructor TNPErrorManager.Create;
begin
  inherited;
  FErrors := TList<TNPError>.Create();
end;

destructor TNPErrorManager.Destroy;
begin
  FErrors.Free();
  inherited;
end;

procedure TNPErrorManager.AddError(const AType: string; const ALine: Integer; const ACol: Integer;
  const AFileName: string; const AMsg: string);
var
  LError: TNPError;
begin
  LError.ErrorType := AType;
  LError.Line := ALine;
  LError.Column := ACol;
  LError.FileName := AFileName;
  LError.Message := AMsg;
  FErrors.Add(LError);
end;

procedure TNPErrorManager.AddError(const AType: string; const AMsg: string);
begin
  AddError(AType, 0, 0, '', AMsg);
end;

function TNPErrorManager.HasErrors: Boolean;
begin
  Result := FErrors.Count > 0;
end;

function TNPErrorManager.ErrorCount: Integer;
begin
  Result := FErrors.Count;
end;

function TNPErrorManager.GetErrors: TArray<TNPError>;
begin
  Result := FErrors.ToArray();
end;

procedure TNPErrorManager.ClearErrors;
begin
  FErrors.Clear();
end;

end.
