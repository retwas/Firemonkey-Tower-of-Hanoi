program TourHanoi;

uses
  System.StartUpCopy,
  FMX.Forms,
  uFormHanoi in 'uFormHanoi.pas' {FormHanoi};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormHanoi, FormHanoi);
  Application.Run;
end.
