{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program NPBench_Delphi;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UNPBench in '..\..\..\bin\projects\NPBench\src\UNPBench.pas';

begin
  try
    RunBench();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
