﻿unit kn_ExportImport;

(****** LICENSE INFORMATION **************************************************

 - This Source Code Form is subject to the terms of the Mozilla Public
 - License, v. 2.0. If a copy of the MPL was not distributed with this
 - file, You can obtain one at http://mozilla.org/MPL/2.0/.

------------------------------------------------------------------------------
 (c) 2007-2023 Daniel Prado Velasco <dprado.keynote@gmail.com> (Spain) [^]
 (c) 2000-2005 Marek Jedlinski <marek@tranglos.com> (Poland)

 [^]: Changes since v. 1.7.0. Fore more information, please see 'README.md'
     and 'doc/README_SourceCode.txt' in https://github.com/dpradov/keynote-nf

 *****************************************************************************)


interface
uses
   Winapi.Windows,
   Winapi.Messages,
   System.Classes,
   System.SysUtils,
   System.StrUtils,
   Vcl.Graphics,
   Vcl.Controls,
   Vcl.Forms,
   Vcl.Dialogs,
   Vcl.Clipbrd,
   kn_const
   ;


   function ConvertHTMLToRTF(const inFilename : string; var OutStream: TMemoryStream) : boolean; overload;
   function ConvertHTMLToRTF(HTMLText: RawByteString; var RTFText : AnsiString) : boolean; overload;
   function ConvertRTFToHTML(const outFilename : String; const RTFText : AnsiString; const HTMLExpMethod : THTMLExportMethod) : boolean;
   procedure FreeConvertLibrary;


implementation
uses
   UWebBrowserWrapper,
   gf_files,
   gf_streams,
   Kn_Global,
{$IFDEF EMBED_UTILS_DLL}
   MSWordConverter,
   MSOfficeConverters,
{$ELSE}
   kn_DllInterface,
   kn_DLLmng,
{$ENDIF}
   kn_ClipUtils,
   kn_Main,
   knt.App,
   knt.RS;

{$IFDEF EMBED_UTILS_DLL}

function ConvertHTMLToRTF(const inFilename : string; var OutStream: TMemoryStream) : boolean;
var
  s: AnsiString;
  HTMLMethod : THTMLImportMethod;
  ReleaseIE: boolean;

begin
  Result := false;
  if (not Fileexists( inFileName)) or (not assigned(OutStream)) then exit;

  try
      HTMLMethod:= KeyOptions.HTMLImportMethod;

      case HTMLMethod of
          htmlSharedTextConv :
              Result:= TextConvImportAsRTF( inFileName, 'HTML', OutStream, '' );

          htmlMSWord:
              Result:= MSWordConvertHTMLToRTF(inFileName, OutStream);

          htmlIE: begin
              // Si _IE no está asignado, saldrá sin estarlo. Sólo lo estará cuando se haya usado para convertir un texto disponible
              // en el portapapeles en formato HTML. En ese caso se dejará vivo porque lo más probable es que se use más veces, pues
              // es señal de que se está usando un programa como Firefox, que no ofrece en el portapapeles el formato RTF
              if not assigned(_IE) then begin
                 _IE:= TWebBrowserWrapper.Create(Form_Main);
                 ReleaseIE:= True;
              end
              else
                 ReleaseIE:= False;

              try
                  _IE.NavigateToLocalFile ( inFileName );
                  _IE.CopyAll;                           // Select all and then copy to clipboard
                  s:= Clipboard.AsRTF;
                  OutStream.WriteBuffer( s[1], length(s));
                  Result := True;
              finally
                  if ReleaseIE then
                     FreeAndNil(_IE);
              end;
          end;

      end; // case HTMLMethod

  except
    on E : Exception do
        App.ErrorPopup(GetRS(sExp01) + E.Message);
  end;
end; // ConvertHTMLToRTF

{$ELSE}

function ConvertHTMLToRTF(const inFilename : string; var OutStream: TMemoryStream) : boolean;
var
  s: AnsiString;
  HTMLMethod : THTMLImportMethod;
  DlgTextConvImportAsRTF:     TextConvImportAsRTFProc;
  DlgMSWordConvertHTMLToRTF : MSWordConvertHTMLToRTFProc;
  ReleaseIE: boolean;

begin
  Result := false;
  if (not Fileexists( inFileName)) or (not assigned(OutStream)) then exit;

  try
      HTMLMethod:= KeyOptions.HTMLImportMethod;

      case HTMLMethod of
          htmlSharedTextConv : begin
              @DlgTextConvImportAsRTF := GetMethodInDLL(_DLLHandle, 'TextConvImportAsRTF');
              if not assigned(DlgTextConvImportAsRTF) then exit;
              Result:= DlgTextConvImportAsRTF( inFileName, 'HTML', OutStream, '' );
          end;


          htmlMSWord: begin
              @DlgMSWordConvertHTMLToRTF := GetMethodInDLL(_DLLHandle, 'MSWordConvertHTMLToRTF');
              if not assigned(DlgMSWordConvertHTMLToRTF) then exit;
              Result:= DlgMSWordConvertHTMLToRTF(inFileName, OutStream);
          end;


          htmlIE: begin
              // Si _IE no está asignado, saldrá sin estarlo. Sólo lo estará cuando se haya usado para convertir un texto disponible
              // en el portapapeles en formato HTML. En ese caso se dejará vivo porque lo más probable es que se use más veces, pues
              // es señal de que se está usando un programa como Firefox, que no ofrece en el portapapeles el formato RTF
              if not assigned(_IE) then begin
                 _IE:= TWebBrowserWrapper.Create(Form_Main);
                 ReleaseIE:= True;
              end
              else
                 ReleaseIE:= False;

              try
                  _IE.NavigateToLocalFile ( inFileName );
                  _IE.CopyAll;                           // Select all and then copy to clipboard
                  s:= Clipboard.AsRTF;
                  OutStream.WriteBuffer( s[1], length(s));
                  Result := True;
              finally
                  if ReleaseIE then
                     FreeAndNil(_IE);
              end;
          end;

      end; // case HTMLMethod

  except
    on E : Exception do
        App.ErrorPopup(GetRS(sExp01) + E.Message);
  end;
end; // ConvertHTMLToRTF

{$ENDIF}


{$IFDEF EMBED_UTILS_DLL}

function ConvertRTFToHTML(const outFilename : String; const RTFText : AnsiString; const HTMLExpMethod : THTMLExportMethod) : boolean;
begin
  Result := false;
  if RTFText = '' then exit;

  try
      case HTMLExpMethod of
          htmlExpMicrosoftHTMLConverter :
              Result:= TextConvExportRTF( outFileName, 'HTML', PAnsiChar(RTFText), GetSystem32Directory + 'html.iec' );

          htmlExpMSWord :
              Result:= MSWordConvertRTFToHTML(outFileName, RTFText);

      end; // case HTMLMethod

  except
    on E : Exception do
        App.ErrorPopup(GetRS(sExp02) + HTMLExportMethods[HTMLExpMethod] + ') : ' + E.Message);
  end;
end; // ConvertRTFToHTML


{$ELSE}

function ConvertRTFToHTML(const outFilename : String; const RTFText : AnsiString; const HTMLExpMethod : THTMLExportMethod) : boolean;
var
  DlgTextConvExportRTF:       TextConvExportRTFProc;
  DlgMSWordConvertRTFToHTML : MSWordConvertRTFToHTMLProc;

begin
  Result := false;
  if RTFText = '' then exit;

  try
      case HTMLExpMethod of
          htmlExpMicrosoftHTMLConverter : begin
              @DlgTextConvExportRTF := GetMethodInDLL(_DLLHandle, 'TextConvExportRTF');
              if not assigned(DlgTextConvExportRTF) then exit;
              Result:= DlgTextConvExportRTF( outFileName, 'HTML', PAnsiChar(RTFText), GetSystem32Directory + 'html.iec' );
              end;

          htmlExpMSWord : begin
              @DlgMSWordConvertRTFToHTML := GetMethodInDLL(_DLLHandle, 'MSWordConvertRTFToHTML');
              if not assigned(DlgMSWordConvertRTFToHTML) then exit;
              Result:= DlgMSWordConvertRTFToHTML(outFileName, RTFText);
          end;

      end; // case HTMLMethod

  except
    on E : Exception do
        App.ErrorPopup(GetRS(sExp02) + HTMLExportMethods[HTMLExpMethod] + ') : ' + E.Message);
  end;
end; // ConvertRTFToHTML

{$ENDIF}


{ Converts HTML to RTF with the help of WebBrowser
 If conversion is possible, it will return RTF text in the parameter and also it will be available as
 RTF format in the clipboard }

function ConvertHTMLToRTF(HTMLText: RawByteString; var RTFText : AnsiString) : boolean;
begin
  Result := false;
  if (not _ConvertHTMLClipboardToRTF) or (HTMLText = '') then exit;

  screen.Cursor := crHourGlass;
  try
     try
         {$IFDEF KNT_DEBUG} Log.Add('ConvertHTMLToRTF.  HTML:', 4 );  {$ENDIF}
         {$IFDEF KNT_DEBUG} Log.Add(HTMLText, 4 );  {$ENDIF}
         if not assigned(_IE) then
            _IE:= TWebBrowserWrapper.Create(Form_Main);

         _IE.LoadFromString  (HTMLText, TEncoding.UTF8);
         _IE.CopyAll;                           // Select all and then copy to clipboard

         RTFText:= Clipboard.AsRTF;
         Result := True;

     except
        _ConvertHTMLClipboardToRTF:= false;
     end;
  finally
     screen.Cursor := crDefault;
  end;
end; // ConvertHTMLToRTF




{$IFDEF EMBED_UTILS_DLL}

procedure FreeConvertLibrary;
begin
   MSWordQuit();
end;

{$ELSE}

procedure FreeConvertLibrary;
var
   DlgMSWordQuit : MSWordQuitProc;

begin
    if _DllHandle > 0 then begin
       try
          @DlgMSWordQuit := GetMethodInDLL(_DLLHandle, 'MSWordQuit');
          if not assigned(DlgMSWordQuit) then exit;
          DlgMSWordQuit();

       finally
          FreeLibrary( _DllHandle );
          _DllHandle:= 0;
       end;
    end;
end;    // FreeConvertLibrary

{$ENDIF}

initialization
  _DLLHandle:= 0;
  _IE:= nil;

finalization

end.