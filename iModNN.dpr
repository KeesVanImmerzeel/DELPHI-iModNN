program iModNN;

uses
  Vcl.Forms,
  u_iModNN in 'u_iModNN.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
