program pTestEntityMapper;

uses
  Vcl.Forms,
  Test.EntityMapper in '..\Test.EntityMapper.pas' {frmTestEntityMapper},
  Assis.RttiInterceptor in '..\RttiInterceptor\Assis.RttiInterceptor.pas',
  Assis.SQLExtractor in '..\SqlExtrator\Assis.SQLExtractor.pas',
  Assis.EntityMapper in 'Assis.EntityMapper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  ReportMemoryLeaksOnShutdown := true;

  Application.CreateForm(TfrmTestEntityMapper, frmTestEntityMapper);
  Application.Run;
end.
