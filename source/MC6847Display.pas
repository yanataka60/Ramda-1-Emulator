unit MC6847Display;

interface

const
  MC6847CellWidth = 8;
  MC6847CellHeight = 12;
  MC6847Columns = 32;
  MC6847Rows = 16;
  MC6847Width = 256;
  MC6847Height = 192;
  MC6847Black = 8;

{ A/G=0, INT/EXT=0, INV=0; A/S is connected to DD7.
  Return palette index 0..7 (green..orange), or 8 (black).
  CSS changes alphanumeric colour only. This is a digital active-area model. }
function MC6847CellPixel(Data: Byte; X, Y: Integer; CSS: Boolean): Byte;
function MC6847TextOffset(X, Y: Integer): Integer;

{ Control byte: bit0=A/G, bit1=GM0, bit3=CSS; GM1/GM2 stay LOW. }
function Ramda1TVControl(PortBPins: Byte): Byte;
function MC6847BorderColour(Control: Byte): Byte;
function MC6847GraphicsOffset(HiRes: Boolean; X, Y: Integer): Integer;
function MC6847GraphicsPixel(Data: Byte; X: Integer; CSS, HiRes: Boolean): Byte;

implementation

const
  { Existing 5x7 font. Complete ROM dot-by-dot comparison is still pending. }
  Glyph: array[0..63,0..6] of Byte = (
    ($00,$00,$00,$00,$00,$00,$00), {20 space}
    ($04,$04,$04,$04,$04,$00,$04), {21 !}
    ($0A,$0A,$0A,$00,$00,$00,$00), {22 "}
    ($0A,$0A,$1F,$0A,$1F,$0A,$0A), {23 #}
    ($04,$0F,$14,$0E,$05,$1E,$04), {24 $}
    ($18,$19,$02,$04,$08,$13,$03), {25 %}
    ($0C,$12,$14,$08,$15,$12,$0D), {26 &}
    ($04,$04,$08,$00,$00,$00,$00), {27 '}
    ($02,$04,$08,$08,$08,$04,$02), {28 (}
    ($08,$04,$02,$02,$02,$04,$08), {29 )}
    ($00,$04,$15,$0E,$15,$04,$00), {2A *}
    ($00,$04,$04,$1F,$04,$04,$00), {2B +}
    ($00,$00,$00,$00,$04,$04,$08), {2C ,}
    ($00,$00,$00,$1F,$00,$00,$00), {2D -}
    ($00,$00,$00,$00,$00,$0C,$0C), {2E .}
    ($01,$02,$02,$04,$08,$08,$10), {2F /}
    ($0E,$11,$13,$15,$19,$11,$0E), {30 0}
    ($04,$0C,$04,$04,$04,$04,$0E), {31 1}
    ($0E,$11,$01,$02,$04,$08,$1F), {32 2}
    ($1E,$01,$01,$0E,$01,$01,$1E), {33 3}
    ($02,$06,$0A,$12,$1F,$02,$02), {34 4}
    ($1F,$10,$10,$1E,$01,$01,$1E), {35 5}
    ($06,$08,$10,$1E,$11,$11,$0E), {36 6}
    ($1F,$01,$02,$04,$08,$08,$08), {37 7}
    ($0E,$11,$11,$0E,$11,$11,$0E), {38 8}
    ($0E,$11,$11,$0F,$01,$02,$0C), {39 9}
    ($00,$0C,$0C,$00,$0C,$0C,$00), {3A :}
    ($00,$0C,$0C,$00,$0C,$04,$08), {3B ;}
    ($02,$04,$08,$10,$08,$04,$02), {3C <}
    ($00,$00,$1F,$00,$1F,$00,$00), {3D =}
    ($08,$04,$02,$01,$02,$04,$08), {3E >}
    ($0E,$11,$01,$02,$04,$00,$04), {3F ?}
    ($0E,$11,$17,$15,$17,$10,$0E), {40 @}
    ($0E,$11,$11,$1F,$11,$11,$11), {41 A}
    ($1E,$11,$11,$1E,$11,$11,$1E), {42 B}
    ($0E,$11,$10,$10,$10,$11,$0E), {43 C}
    ($1E,$11,$11,$11,$11,$11,$1E), {44 D}
    ($1F,$10,$10,$1E,$10,$10,$1F), {45 E}
    ($1F,$10,$10,$1E,$10,$10,$10), {46 F}
    ($0E,$11,$10,$17,$11,$11,$0F), {47 G}
    ($11,$11,$11,$1F,$11,$11,$11), {48 H}
    ($0E,$04,$04,$04,$04,$04,$0E), {49 I}
    ($07,$02,$02,$02,$02,$12,$0C), {4A J}
    ($11,$12,$14,$18,$14,$12,$11), {4B K}
    ($10,$10,$10,$10,$10,$10,$1F), {4C L}
    ($11,$1B,$15,$15,$11,$11,$11), {4D M}
    ($11,$19,$15,$13,$11,$11,$11), {4E N}
    ($0E,$11,$11,$11,$11,$11,$0E), {4F O}
    ($1E,$11,$11,$1E,$10,$10,$10), {50 P}
    ($0E,$11,$11,$11,$15,$12,$0D), {51 Q}
    ($1E,$11,$11,$1E,$14,$12,$11), {52 R}
    ($0F,$10,$10,$0E,$01,$01,$1E), {53 S}
    ($1F,$04,$04,$04,$04,$04,$04), {54 T}
    ($11,$11,$11,$11,$11,$11,$0E), {55 U}
    ($11,$11,$11,$11,$11,$0A,$04), {56 V}
    ($11,$11,$11,$15,$15,$15,$0A), {57 W}
    ($11,$11,$0A,$04,$0A,$11,$11), {58 X}
    ($11,$11,$0A,$04,$04,$04,$04), {59 Y}
    ($1F,$01,$02,$04,$08,$10,$1F), {5A Z}
    ($0E,$08,$08,$08,$08,$08,$0E), {5B [}
    ($10,$08,$08,$04,$02,$02,$01), {5C backslash}
    ($0E,$02,$02,$02,$02,$02,$0E), {5D ]}
    ($04,$0E,$15,$04,$04,$04,$04), {5E up arrow}
    ($00,$04,$08,$1F,$08,$04,$00)  {5F left arrow}
  );

function MC6847TextOffset(X, Y: Integer): Integer;
begin
  if (X < 0) or (X >= MC6847Width) or
     (Y < 0) or (Y >= MC6847Height) then
    Result := -1
  else
    Result := (Y div MC6847CellHeight) * MC6847Columns +
              X div MC6847CellWidth;
end;

function MC6847CellPixel(Data: Byte; X, Y: Integer; CSS: Boolean): Byte;
var
  Code, BitNumber: Integer;
begin
  Result := MC6847Black;
  if (X < 0) or (X >= MC6847CellWidth) or
     (Y < 0) or (Y >= MC6847CellHeight) then Exit;
  if (Data and $80) <> 0 then
  begin
    { Motorola Fig.21: D3 UL, D2 UR, D1 LL, D0 LR.
      Each semigraphics-4 block is 4 half-clocks by 6 scan lines. }
    BitNumber := 3 - (Y div 6) * 2 - X div 4;
    if (Data and (1 shl BitNumber)) <> 0 then
      Result := (Data shr 4) and 7;
    Exit;
  end;
  { Six-bit internal character ROM; DD6 does not select an inverse character
    because INV is tied LOW in the Ramda1 circuit. }
  Code := Data and $3F;
  if Code < $20 then Inc(Code, $40);
  { 8x12 cell: 2 columns left, 3 lines above the 5x7 matrix.
    Half-open bounds prevent one dot from spilling into its neighbour. }
  if (X < 2) or (X >= 7) or (Y < 3) or (Y >= 10) then Exit;
  if (Glyph[Code - $20, Y - 3] and (1 shl (6 - X))) <> 0 then
  begin
    if CSS then Result := 7 else Result := 0;
  end;
end;

function Ramda1TVControl(PortBPins: Byte): Byte;
begin
  { Board inverters: PB3 -> A/G, PB2 -> GM0, PB4 -> CSS.
    Use physical output pins (including DDR/pull-ups), never raw ORB. }
  Result := ((not PortBPins) and $08) shr 3;
  Result := Result or (((not PortBPins) and $04) shr 1);
  Result := Result or (((not PortBPins) and $10) shr 1);
end;

function MC6847BorderColour(Control: Byte): Byte;
begin
  if (Control and $01) = 0 then Result := MC6847Black
  else if (Control and $08) = 0 then Result := 0
  else Result := 4;
end;

function MC6847GraphicsOffset(HiRes: Boolean; X, Y: Integer): Integer;
begin
  if (X < 0) or (X >= MC6847Width) or
     (Y < 0) or (Y >= MC6847Height) then Result := -1
  else Result := (Y div 3) * 16 + X div 16;
  { CG1: 4 pixels/byte, each pixel 4 half-clocks wide.
    RG1: 8 pixels/byte, each pixel 2 half-clocks wide.
    Both consume 16 bytes per logical row, 64 rows = 1024 bytes. }
end;

function MC6847GraphicsPixel(Data: Byte; X: Integer; CSS, HiRes: Boolean): Byte;
var Shift: Integer;
begin
  Result := MC6847Black;
  if (X < 0) or (X >= MC6847Width) then Exit;
  if HiRes then
  begin
    Shift := 7 - ((X div 2) mod 8);
    if (Data and (1 shl Shift)) <> 0 then
      if CSS then Result := 4 else Result := 0;
  end
  else
  begin
    Shift := 6 - ((X div 4) mod 4) * 2;
    Result := (Data shr Shift) and 3;
    if CSS then Inc(Result, 4);
  end;
end;

end.
