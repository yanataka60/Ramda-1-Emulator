unit PrinterTextBuffer;
interface
const PrinterDisplayMaxChars=65536;
type
 TPrinterTextBuffer=class
 private
  FText:UnicodeString;
  FLastCR:Boolean;
 public
  procedure Append(const Data:AnsiString);
  property Text:UnicodeString read FText;
 end;
implementation
procedure TPrinterTextBuffer.Append(const Data:AnsiString);
var Chunk:UnicodeString;I,N,Excess,Cut:Integer;B:Byte;
 procedure Add(C:WideChar);
 begin Inc(N);Chunk[N]:=C end;
 procedure NewLine;
 begin Add(#13);Add(#10)end;
begin
 if Data=''then Exit;
 SetLength(Chunk,Length(Data)*2);N:=0;
 for I:=1 to Length(Data)do begin
  B:=Ord(Data[I]);
  case B of
   13:begin NewLine;FLastCR:=True end;
   10:begin if not FLastCR then NewLine;FLastCR:=False end;
   8:begin
    FLastCR:=False;
    if(N>0)and(Chunk[N]<>#10)then Dec(N)
    else if(N=0)and(Length(FText)>0)and(FText[Length(FText)]<>#10)then
     SetLength(FText,Length(FText)-1);
   end;
   9:begin Add(#9);FLastCR:=False end;
   12:begin NewLine;FLastCR:=False end;
  else
   if B>=32 then begin
    FLastCR:=False;
    if (B>=$A1)and(B<=$DF)then Add(WideChar($FF61+B-$A1))
    else if B<>127 then Add(WideChar(B));
   end;
  end;
 end;
 SetLength(Chunk,N);FText:=FText+Chunk;
 Excess:=Length(FText)-PrinterDisplayMaxChars;
 if Excess>0 then begin
  { Prefer dropping complete old lines. A very long single line is clipped. }
  Cut:=Excess;
  while(Cut<Length(FText))and(FText[Cut]<>#10)do Inc(Cut);
  if Cut=Length(FText)then Cut:=Excess;
  Delete(FText,1,Cut);
 end;
end;
end.
