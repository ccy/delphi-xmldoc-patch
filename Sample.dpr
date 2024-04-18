program Sample;

uses
  TestInsight.DUnit,
  Xml.XMLDoc.Patch in 'Xml.XMLDoc.Patch.pas',
  UBLInvoice21 in 'UBLInvoice21.pas',
  UBL21.TestCase in 'UBL21.TestCase.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;
  RunRegisteredTests;
end.

