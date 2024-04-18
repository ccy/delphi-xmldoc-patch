unit UBL21.TestCase;

interface

uses
  System.SysUtils, TestFramework,
  UBLInvoice21;

type
  TUBL21_Example = class(TTestCase)
  const
    CAC = 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2';
    CBC = 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';
  type
    IDoc = IXMLInvoiceType;
  strict private
    X: IDoc;
    NewDocument: TFunc<IDoc>;
  private
    class function LoadDoc: IDoc;
    class function NewDoc: IDoc;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  public
    class function NewSuite(aFactory: TFunc<IDoc>): ITestSuite;
  published
    procedure Test_UBLVersionID;
    procedure Test_AllowanceCharge;
    procedure Test_TaxTotal;
    procedure Test_TaxTotal_TaxAmount;
  end;

implementation

uses
  Winapi.ActiveX, Xml.XMLDoc;

class function TUBL21_Example.LoadDoc: IDoc;
begin
  Result := LoadInvoice('V:\prototype\UBL-2.1\xml\UBL-Invoice-2.1-Example.xml');
end;

class function TUBL21_Example.NewDoc: IDoc;
begin
  var o := NewInvoice;
  o.UBLVersionID.Text := '2.1';
  o.TaxTotal.Add.TaxAmount.Text := '292.20';

  with o.AllowanceCharge.Add do begin
    ChargeIndicator.NodeValue := True;
    AllowanceChargeReason.add.Text := 'Packing cost';
    Amount.Text := '100';
  end;

  with o.AllowanceCharge.Add do begin
    ChargeIndicator.NodeValue := False;
    AllowanceChargeReason.add.Text := 'Promotion discount';
    Amount.Text := '100';
  end;

  Result := o;
end;

class function TUBL21_Example.NewSuite(aFactory: TFunc<IDoc>): ITestSuite;
begin
  Result := Suite;
  for var i := 0 to Result.Tests.Count - 1 do
    (Result.Tests[i] as TUBL21_Example).NewDocument := aFactory;
end;

procedure TUBL21_Example.SetUp;
begin
  inherited;
  X := NewDocument();
end;

procedure TUBL21_Example.TearDown;
begin
  inherited;
  X := nil;
end;

procedure TUBL21_Example.Test_AllowanceCharge;
begin
  CheckEquals(2, X.AllowanceCharge.Count);

  CheckTrue(X.AllowanceCharge.Items[0].ChargeIndicator.NodeValue);
  CheckEquals(1, X.AllowanceCharge.Items[0].AllowanceChargeReason.Count);
  CheckEquals('Packing cost', X.AllowanceCharge.Items[0].AllowanceChargeReason.Items[0].Text);
  CheckEquals('100', X.AllowanceCharge.Items[0].Amount.Text);

  CheckFalse(X.AllowanceCharge.Items[1].ChargeIndicator.NodeValue);
  CheckEquals(1, X.AllowanceCharge.Items[1].AllowanceChargeReason.Count);
  CheckEquals('Promotion discount', X.AllowanceCharge.Items[1].AllowanceChargeReason.Items[0].Text);
  CheckEquals('100', X.AllowanceCharge.Items[1].Amount.Text);
end;

procedure TUBL21_Example.Test_TaxTotal;
begin
  CheckEquals(1, X.TaxTotal.Count);

  var TaxTotal := X.TaxTotal.Items[0];
  CheckEquals('TaxTotal', TaxTotal.LocalName);
  CheckEquals('cac:TaxTotal', TaxTotal.NodeName);
  CheckEquals(CAC, TaxTotal.NamespaceURI);
end;

procedure TUBL21_Example.Test_TaxTotal_TaxAmount;
begin
  var TaxAmount := X.TaxTotal.Items[0].TaxAmount;

  CheckEquals('TaxAmount', TaxAmount.LocalName);
  CheckEquals('cbc:TaxAmount', TaxAmount.NodeName);
  CheckEquals(CBC, TaxAmount.NamespaceURI);
  CheckEquals('292.20', TaxAmount.Text);
end;

procedure TUBL21_Example.Test_UBLVersionID;
begin
  CheckEquals('2.1', X.UBLVersionID.Text);
end;

var NeedToUninitialize: Boolean = False;

initialization
  NeedToUninitialize := Succeeded(CoInitialize(nil));

  RegisterTest('LoadInvoice', TUBL21_Example.NewSuite(TUBL21_Example.LoadDoc));
  RegisterTest('NewInvoice', TUBL21_Example.NewSuite(TUBL21_Example.NewDoc));
finalization
  if NeedToUninitialize then CoUninitialize;
end.
