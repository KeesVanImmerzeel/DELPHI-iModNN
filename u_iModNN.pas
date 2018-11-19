unit u_iModNN;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, {uProgramSettings,} uError, Vcl.StdCtrls,
  Vcl.ExtCtrls, FileCtrl, uTabstractESRIgrid, uTIntegerESRIgrid, LargeArrays,
  OPwstring, uTSingleESRIgrid, Vcl.ComCtrls, AVGRIDIO;

type
  TForm3 = class(TForm)
    OpenGridFileDialog: TOpenDialog;
    LabeledEdit_ve_grid: TLabeledEdit;
    ve_int_ESRIgrid: TIntegerESRIgrid;
    GoButton: TButton;
    LabeledEdit_nn_per_decade: TLabeledEdit;
    OpenDialogNNperDecade: TOpenDialog;
    MemoInfo: TMemo;
    DoubleMatrixNN_per_Decade: TDoubleMatrix;
    SingleESRIoutputGrid: TSingleESRIgrid;
    ProgressBar1: TProgressBar;
    procedure LabeledEdit_ve_gridClick(Sender: TObject);
    procedure GoButtonClick(Sender: TObject);
    procedure LabeledEdit_nn_per_decadeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation
var
  Directory: String; //Selected output directory

const
  cIni_Input_Files = 'INPUT FILES';
  cIni_Output_Files = 'OUTPUT FILES';
  cIni_ve_grid = 've_grid';
  cIni_nn_file = 'nn_file';
  cIni_Default_nn_file_name = 'nn_per_decade.txt';
  cIni_Output_dir = 'output_dir';
  cIni_DefaultInputDir = 'c:\'; cIni_DefaultOutputDir = 'c\';

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  InitialiseLogFile;
  InitialiseGridIO;
  with fini do begin
    LabeledEdit_ve_grid.Text := ReadString( cIni_Input_Files, cIni_ve_grid,
      cIni_DefaultInputDir );
    LabeledEdit_nn_per_decade.Text := ReadString( cIni_Input_Files, cIni_nn_file,
      cIni_DefaultInputDir + cIni_Default_nn_file_name );
    Directory := ReadString( cIni_Output_Files, cIni_Output_dir,
      cIni_DefaultOutputDir );
  end;
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

procedure TForm3.GoButtonClick(Sender: TObject);
Const
  WordDelims: CharSet = [' '];
var
  iResult, row, nrows, col, ncols, jaar, maand, dag, i, maxi, j, maxj,
  verdampingseenheid: Integer;
  f: TextFile;
  output_filename: string;
  nn: double;
begin
  Try
    Try
      ve_int_ESRIgrid := TIntegerESRIgrid.InitialiseFromESRIGridFile(
            LabeledEdit_ve_grid.Text, iResult, self );
      if not fileExists( LabeledEdit_nn_per_decade.text ) then
        raise Exception.CreateFmt('File does not exist [%s]', [LabeledEdit_nn_per_decade.text]);
      AssignFile( f, LabeledEdit_nn_per_decade.text ); Reset( f );
      DoubleMatrixNN_per_Decade := TDoubleMatrix.InitialiseFromTextFile( f, self );
      CloseFile( f );
      if not SelectDirectory( Directory,  [sdAllowCreate, sdPrompt, sdPerformCreate], 0 ) then
        raise Exception.Create('No output directory chosen');
      fini.WriteString( cIni_Output_Files, cIni_Output_dir, Directory );

      SetCurrentDir( Directory );
      WriteToLogFile('CurrentDir=' + Directory );
      SingleESRIoutputGrid := TSingleESRIgrid.Clone(ve_int_ESRIgrid, 'nn', iResult, self );
      maxi := ve_int_ESRIgrid.NRows;
      maxj := ve_int_ESRIgrid.NCols;

      nrows := DoubleMatrixNN_per_Decade.GetNRows;
      ncols := DoubleMatrixNN_per_Decade.GetNCols;
      ProgressBar1.Max := nrows; ProgressBar1.Visible := true;
      for row := 1 to nrows do begin
        jaar := trunc( DoubleMatrixNN_per_Decade[ row, 1] );
        maand := trunc(DoubleMatrixNN_per_Decade[ row, 2] );
        dag := trunc( DoubleMatrixNN_per_Decade[ row, 3] );
        if jaar > 0 then
          output_filename := Format( '%d', [jaar] ) +
          Format('%.*d', [2,maand]) + Format('%.*d', [2,dag]) + '.idf'
        else
          output_filename := 'avg_nn.idf';
        //writetologfile( output_filename );

        for i := 1 to maxi do begin
          for j := 1 to maxj do begin
            verdampingseenheid := ve_int_ESRIgrid[ i, j];
            col := verdampingseenheid + 3;
            if ( col > ncols ) or ( col < 1 ) then
              raise Exception.CreateFmt('Ongeldige verdampingseenheid: %d',
                [verdampingseenheid]);
            nn := DoubleMatrixNN_per_Decade[ row, col ];
            SingleESRIoutputGrid[ i, j ] := nn;
          end;
        end;
        SingleESRIoutputGrid.ExportToIDFfile(output_filename);
        if jaar <= 0 then begin
          SingleESRIoutputGrid.ExportToASC(ChangeFileExt(output_filename, '.asc'));
          SingleESRIoutputGrid.SaveAs(ChangeFileExt(output_filename, ''))
        end;
        ProgressBar1.StepIt;
      end;
      showmessage('Gereed.');
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      End;
    End;
  Finally
    ProgressBar1.Visible := false;
  End;
end;

procedure TForm3.LabeledEdit_nn_per_decadeClick(Sender: TObject);
begin
  with OpenDialogNNperDecade do begin
    if execute then begin
      LabeledEdit_nn_per_decade.Text := ExpandFileName( FileName );
      fini.WriteString( cIni_Input_Files, cIni_nn_file,
      LabeledEdit_nn_per_decade.Text );
    end;
  end;
end;

procedure TForm3.LabeledEdit_ve_gridClick(Sender: TObject);
var
  Directory: string;
begin
  Directory := GetCurrentDir;
  if SelectDirectory( Directory,  [], 0 ) then begin
    LabeledEdit_ve_grid.Text := ExpandFileName( Directory );
    fini.WriteString( cIni_Input_Files, cIni_ve_grid,
      LabeledEdit_ve_grid.Text );
  end;
end;


end.
