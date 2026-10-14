unit MC6800;

interface

type
  TRead8 = function(Address: Word): Byte of object;
  TWrite8 = procedure(Address: Word; Value: Byte) of object;

  TMC6800 = class
  private
    FRead: TRead8;
    FWrite: TWrite8;
    FWaitStacked: Boolean;
    FNMIHigh, FNMIPending: Boolean;
    function EnterNMI: Integer;
    function R(Addr: Word): Byte; inline;
    procedure W(Addr: Word; Value: Byte); inline;
    function RW(Addr: Word): Word;
    procedure Push(Value: Byte);
    procedure PushW(Value: Word);
    function Pull: Byte;
    function PullW: Word;
    procedure SetNZ8(Value: Byte);
    procedure SetNZ16(Value: Word);
    procedure SetNZV8(Value: Byte);
    procedure SetNZV16(Value: Word);
    function Add8(L, Rhs, CarryIn: Byte): Byte;
    function Sub8(L, Rhs, BorrowIn: Byte): Byte;
    procedure Compare16(L, Rhs: Word);
    function Branch(Condition: Boolean): Integer;
    procedure StackInterruptFrame;
  public
    A, B, CC: Byte;
    X, SP, PC: Word;
    Halted: Boolean;
    LastIllegalOpcode: Integer;
    constructor Create(ARead: TRead8; AWrite: TWrite8);
    procedure Reset;
    procedure SetNMILevel(HighLevel: Boolean);
    function Step: Integer;
  end;

implementation

const
  FLAG_C = $01;
  FLAG_V = $02;
  FLAG_Z = $04;
  FLAG_N = $08;
  FLAG_I = $10;
  FLAG_H = $20;

constructor TMC6800.Create(ARead: TRead8; AWrite: TWrite8);
begin
  FRead := ARead;
  FWrite := AWrite;
  Reset;
end;

function TMC6800.R(Addr: Word): Byte;
begin
  Result := FRead(Addr);
end;

procedure TMC6800.W(Addr: Word; Value: Byte);
begin
  FWrite(Addr, Value);
end;

function TMC6800.RW(Addr: Word): Word;
begin
  Result := (Word(R(Addr)) shl 8) or R(Word(Addr + 1));
end;

procedure TMC6800.Push(Value: Byte);
begin
  W(SP, Value);
  Dec(SP);
end;

procedure TMC6800.PushW(Value: Word);
begin
  { MC6800 stores low byte first, then high byte while SP decrements. }
  Push(Byte(Value));
  Push(Byte(Value shr 8));
end;

function TMC6800.Pull: Byte;
begin
  Inc(SP);
  Result := R(SP);
end;

function TMC6800.PullW: Word;
var
  Hi, Lo: Byte;
begin
  Hi := Pull;
  Lo := Pull;
  Result := (Word(Hi) shl 8) or Lo;
end;

procedure TMC6800.SetNZ8(Value: Byte);
begin
  CC := CC and not (FLAG_N or FLAG_Z);
  if Value = 0 then CC := CC or FLAG_Z;
  if (Value and $80) <> 0 then CC := CC or FLAG_N;
end;

procedure TMC6800.SetNZ16(Value: Word);
begin
  CC := CC and not (FLAG_N or FLAG_Z);
  if Value = 0 then CC := CC or FLAG_Z;
  if (Value and $8000) <> 0 then CC := CC or FLAG_N;
end;

procedure TMC6800.SetNZV8(Value: Byte);
begin
  SetNZ8(Value);
  CC := CC and not FLAG_V;
end;

procedure TMC6800.SetNZV16(Value: Word);
begin
  SetNZ16(Value);
  CC := CC and not FLAG_V;
end;

function TMC6800.Add8(L, Rhs, CarryIn: Byte): Byte;
var
  T: Integer;
  V8: Byte;
begin
  T := Integer(L) + Integer(Rhs) + Integer(CarryIn);
  V8 := Byte(T);
  CC := CC and not (FLAG_H or FLAG_N or FLAG_Z or FLAG_V or FLAG_C);
  if ((L and $0F) + (Rhs and $0F) + CarryIn) > $0F then CC := CC or FLAG_H;
  if V8 = 0 then CC := CC or FLAG_Z;
  if (V8 and $80) <> 0 then CC := CC or FLAG_N;
  if ((not (L xor Rhs) and (L xor V8) and $80) <> 0) then CC := CC or FLAG_V;
  if T > $FF then CC := CC or FLAG_C;
  Result := V8;
end;

function TMC6800.Sub8(L, Rhs, BorrowIn: Byte): Byte;
var
  T: Integer;
  V8: Byte;
begin
  T := Integer(L) - Integer(Rhs) - Integer(BorrowIn);
  V8 := Byte(T);
  { H is not affected by SUB/CMP/SBC on MC6800. }
  CC := CC and not (FLAG_N or FLAG_Z or FLAG_V or FLAG_C);
  if V8 = 0 then CC := CC or FLAG_Z;
  if (V8 and $80) <> 0 then CC := CC or FLAG_N;
  if (((L xor Rhs) and (L xor V8) and $80) <> 0) then CC := CC or FLAG_V;
  if T < 0 then CC := CC or FLAG_C;
  Result := V8;
end;

procedure TMC6800.Compare16(L, Rhs: Word);
var
  D: Word;
begin
  D := Word(Byte((L shr 8) - (Rhs shr 8))) shl 8;
  { MC6800 CPX: N/V from high-byte subtraction, Z from all 16 bits; C unchanged. }
  CC := CC and not (FLAG_N or FLAG_Z or FLAG_V);
  if L = Rhs then CC := CC or FLAG_Z;
  if (D and $8000) <> 0 then CC := CC or FLAG_N;
  if (((L xor Rhs) and (L xor D) and $8000) <> 0) then CC := CC or FLAG_V;
end;

function TMC6800.Branch(Condition: Boolean): Integer;
var
  Disp: ShortInt;
begin
  Disp := ShortInt(R(PC));
  Inc(PC);
  if Condition then PC := Word(Integer(PC) + Disp);
  Result := 4; { all MC6800 relative conditional branches are 4 cycles }
end;

procedure TMC6800.StackInterruptFrame;
begin
  PushW(PC);
  PushW(X);
  Push(A);
  Push(B);
  Push(CC);
end;

procedure TMC6800.Reset;
begin
  A := 0;
  B := 0;
  X := 0;
  SP := $00FF;
  CC := $D0; { reserved high bits + interrupt mask }
  PC := RW($FFFE);
  Halted := False;
  FWaitStacked := False;
  LastIllegalOpcode := -1;
  FNMIHigh := True;
  FNMIPending := False;
end;

procedure TMC6800.SetNMILevel(HighLevel: Boolean);
begin
  { Hardware NMI edge latch. Never change CPU registers from an I/O callback. }
  if FNMIHigh and not HighLevel then FNMIPending := True;
  FNMIHigh := HighLevel;
end;

function TMC6800.EnterNMI: Integer;
begin
  FNMIPending := False;
  if FWaitStacked then Result := 4 else Result := 12;
  { WAI has already stacked the complete machine state. }
  if not FWaitStacked then
    StackInterruptFrame;
  FWaitStacked := False;
  CC := CC or FLAG_I;
  PC := RW($FFFC);
  Halted := False;
end;

function TMC6800.Step: Integer;
var
  Op, V8, OldC, OldV, Corr: Byte;
  EA, V16, Tmp16: Word;
  T: Integer;

  function Fetch8: Byte;
  begin
    Result := R(PC);
    Inc(PC);
  end;

  function Fetch16: Word;
  begin
    Result := RW(PC);
    Inc(PC, 2);
  end;

  function EADirect: Word;
  begin
    Result := Fetch8;
  end;

  function EAIndexed: Word;
  begin
    Result := Word(X + Fetch8);
  end;

  function EAExtended: Word;
  begin
    Result := Fetch16;
  end;

  procedure LogicFlags(Value: Byte);
  begin
    SetNZ8(Value);
    CC := CC and not FLAG_V;
  end;

  procedure StoreFlags8(Value: Byte);
  begin
    SetNZ8(Value);
    CC := CC and not FLAG_V;
  end;

  procedure StoreFlags16(Value: Word);
  begin
    SetNZ16(Value);
    CC := CC and not FLAG_V;
  end;

  procedure Unary8(var Value: Byte; Code: Byte; DoWrite: Boolean; Addr: Word);
  var
    Before, CarryIn, CarryOut: Byte;
  begin
    Before := Value;
    CarryIn := Ord((CC and FLAG_C) <> 0);
    case Code of
      $0: begin { NEG }
        Value := Byte(0 - Value);
        CC := CC and not (FLAG_N or FLAG_Z or FLAG_V or FLAG_C);
        SetNZ8(Value);
        if Before = $80 then CC := CC or FLAG_V;
        if Before <> 0 then CC := CC or FLAG_C;
      end;
      $3: begin { COM }
        Value := not Value;
        SetNZ8(Value);
        CC := (CC and not FLAG_V) or FLAG_C;
      end;
      $4: begin { LSR }
        CarryOut := Before and 1;
        Value := Before shr 1;
        CC := CC and not (FLAG_N or FLAG_Z or FLAG_V or FLAG_C);
        if Value = 0 then CC := CC or FLAG_Z;
        if CarryOut <> 0 then CC := CC or FLAG_C or FLAG_V; { N=0, V=N xor C }
      end;
      $6: begin { ROR }
        CarryOut := Before and 1;
        Value := (Before shr 1) or (CarryIn shl 7);
        SetNZ8(Value);
        CC := CC and not (FLAG_V or FLAG_C);
        if CarryOut <> 0 then CC := CC or FLAG_C;
        if (((CC and FLAG_N) <> 0) xor ((CC and FLAG_C) <> 0)) then CC := CC or FLAG_V;
      end;
      $7: begin { ASR }
        CarryOut := Before and 1;
        Value := (Before shr 1) or (Before and $80);
        SetNZ8(Value);
        CC := CC and not (FLAG_V or FLAG_C);
        if CarryOut <> 0 then CC := CC or FLAG_C;
        if (((CC and FLAG_N) <> 0) xor ((CC and FLAG_C) <> 0)) then CC := CC or FLAG_V;
      end;
      $8: begin { ASL }
        CarryOut := (Before shr 7) and 1;
        Value := Byte(Before shl 1);
        SetNZ8(Value);
        CC := CC and not (FLAG_V or FLAG_C);
        if CarryOut <> 0 then CC := CC or FLAG_C;
        if (((CC and FLAG_N) <> 0) xor ((CC and FLAG_C) <> 0)) then CC := CC or FLAG_V;
      end;
      $9: begin { ROL }
        CarryOut := (Before shr 7) and 1;
        Value := Byte((Before shl 1) or CarryIn);
        SetNZ8(Value);
        CC := CC and not (FLAG_V or FLAG_C);
        if CarryOut <> 0 then CC := CC or FLAG_C;
        if (((CC and FLAG_N) <> 0) xor ((CC and FLAG_C) <> 0)) then CC := CC or FLAG_V;
      end;
      $A: begin { DEC }
        Value := Byte(Before - 1);
        SetNZ8(Value);
        CC := CC and not FLAG_V;
        if Before = $80 then CC := CC or FLAG_V;
      end;
      $C: begin { INC }
        Value := Byte(Before + 1);
        SetNZ8(Value);
        CC := CC and not FLAG_V;
        if Before = $7F then CC := CC or FLAG_V;
      end;
      $D: begin { TST }
        SetNZ8(Value);
        CC := CC and not (FLAG_V or FLAG_C);
      end;
      $F: begin { CLR }
        Value := 0;
        CC := (CC and not (FLAG_N or FLAG_V or FLAG_C)) or FLAG_Z;
      end;
    end;
    if DoWrite and (Code <> $D) then W(Addr, Value);
  end;

  procedure Illegal;
  begin
    LastIllegalOpcode := Op;
    Halted := True;
    Result := 1;
  end;

begin
  { Sample the latched NMI at an instruction boundary, also when WAI is waiting.
    A continuously low NMI input does not request another interrupt. }
  if FNMIPending then Exit(EnterNMI);
  if Halted then Exit(1);
  Op := Fetch8;
  Result := 2;

  case Op of
    $01: Result := 2; { NOP }
    $06: begin CC := (CC and $C0) or (A and $3F); Result := 2 end; { TAP }
    $07: begin A := CC; Result := 2 end; { TPA }
    $08: begin Inc(X); CC := CC and not FLAG_Z; if X=0 then CC:=CC or FLAG_Z; Result:=4 end; { INX: Z only }
    $09: begin Dec(X); CC := CC and not FLAG_Z; if X=0 then CC:=CC or FLAG_Z; Result:=4 end; { DEX: Z only }
    $0A: begin CC:=CC and not FLAG_V; Result:=2 end;
    $0B: begin CC:=CC or FLAG_V; Result:=2 end;
    $0C: begin CC:=CC and not FLAG_C; Result:=2 end;
    $0D: begin CC:=CC or FLAG_C; Result:=2 end;
    $0E: begin CC:=CC and not FLAG_I; Result:=2 end;
    $0F: begin CC:=CC or FLAG_I; Result:=2 end;
    $10: begin A:=Sub8(A,B,0); Result:=2 end; { SBA }
    $11: begin Sub8(A,B,0); Result:=2 end; { CBA }
    $16: begin B:=A; SetNZV8(B); Result:=2 end;
    $17: begin A:=B; SetNZV8(A); Result:=2 end;
    $19: begin { DAA }
      OldC := Ord((CC and FLAG_C) <> 0);
      Corr := 0;
      if ((A and $0F) > 9) or ((CC and FLAG_H) <> 0) then Corr := Corr or $06;
      if (A > $99) or (OldC <> 0) then Corr := Corr or $60;
      T := Integer(A) + Corr;
      A := Byte(T);
      SetNZ8(A);
      if (T > $FF) or (OldC <> 0) then CC := CC or FLAG_C else CC := CC and not FLAG_C;
      { V is undefined by the original documentation; preserve it. }
      Result := 2;
    end;
    $1B: begin A:=Add8(A,B,0); Result:=2 end;

    $20: Result:=Branch(True);
    $22: Result:=Branch((CC and (FLAG_C or FLAG_Z))=0);
    $23: Result:=Branch((CC and (FLAG_C or FLAG_Z))<>0);
    $24: Result:=Branch((CC and FLAG_C)=0);
    $25: Result:=Branch((CC and FLAG_C)<>0);
    $26: Result:=Branch((CC and FLAG_Z)=0);
    $27: Result:=Branch((CC and FLAG_Z)<>0);
    $28: Result:=Branch((CC and FLAG_V)=0);
    $29: Result:=Branch((CC and FLAG_V)<>0);
    $2A: Result:=Branch((CC and FLAG_N)=0);
    $2B: Result:=Branch((CC and FLAG_N)<>0);
    $2C: Result:=Branch(((CC and FLAG_N)=0)=((CC and FLAG_V)=0));
    $2D: Result:=Branch(((CC and FLAG_N)=0)<>((CC and FLAG_V)=0));
    $2E: Result:=Branch(((CC and FLAG_Z)=0) and (((CC and FLAG_N)=0)=((CC and FLAG_V)=0)));
    $2F: Result:=Branch(((CC and FLAG_Z)<>0) or (((CC and FLAG_N)=0)<>((CC and FLAG_V)=0)));

    $30: begin X:=SP+1; Result:=4 end;
    $31: begin Inc(SP); Result:=4 end;
    $32: begin A:=Pull; Result:=4 end;
    $33: begin B:=Pull; Result:=4 end;
    $34: begin Dec(SP); Result:=4 end;
    $35: begin SP:=X-1; Result:=4 end;
    $36: begin Push(A); Result:=4 end;
    $37: begin Push(B); Result:=4 end;
    $39: begin PC:=PullW; Result:=5 end;
    $3B: begin CC:=Pull; B:=Pull; A:=Pull; X:=PullW; PC:=PullW; FWaitStacked:=False; Result:=10 end;
    $3E: begin StackInterruptFrame; FWaitStacked:=True; Halted:=True; Result:=9 end;
    $3F: begin StackInterruptFrame; CC:=CC or FLAG_I; PC:=RW($FFFA); Result:=12 end;

    $40,$43,$44,$46..$4A,$4C..$4D,$4F:
      begin V8:=A; Unary8(V8,Op and $0F,False,0); A:=V8; Result:=2 end;
    $50,$53,$54,$56..$5A,$5C..$5D,$5F:
      begin V8:=B; Unary8(V8,Op and $0F,False,0); B:=V8; Result:=2 end;

    $60,$63,$64,$66..$6A,$6C..$6D,$6F:
      begin EA:=EAIndexed; V8:=R(EA); Unary8(V8,Op and $0F,True,EA); Result:=7 end;
    $6E: begin PC:=EAIndexed; Result:=4 end;

    { Fujitsu MB8861 extensions. }
    $71: begin V8:=Fetch8; EA:=Word(X+Fetch8); V8:=R(EA) and V8; W(EA,V8); SetNZV8(V8); Result:=8 end;
    $72: begin V8:=Fetch8; EA:=Word(X+Fetch8); V8:=R(EA) or V8; W(EA,V8); SetNZV8(V8); Result:=8 end;
    $75: begin V8:=Fetch8; EA:=Word(X+Fetch8); V8:=R(EA) xor V8; W(EA,V8); SetNZV8(V8); Result:=8 end;
    $7B: begin V8:=Fetch8; EA:=Word(X+Fetch8); V8:=(R(EA) and V8) xor V8; SetNZV8(V8); Result:=7 end;

    $70,$73,$74,$76..$7A,$7C,$7D,$7F:
      begin EA:=EAExtended; V8:=R(EA); Unary8(V8,Op and $0F,True,EA); Result:=6 end;
    $7E: begin PC:=EAExtended; Result:=3 end;

    { A accumulator: immediate/direct/indexed/extended }
    $80: begin A:=Sub8(A,Fetch8,0); Result:=2 end;
    $81: begin Sub8(A,Fetch8,0); Result:=2 end;
    $82: begin A:=Sub8(A,Fetch8,Ord((CC and FLAG_C)<>0)); Result:=2 end;
    $84: begin A:=A and Fetch8; LogicFlags(A); Result:=2 end;
    $85: begin V8:=A and Fetch8; LogicFlags(V8); Result:=2 end;
    $86: begin A:=Fetch8; SetNZV8(A); Result:=2 end;
    $88: begin A:=A xor Fetch8; LogicFlags(A); Result:=2 end;
    $89: begin A:=Add8(A,Fetch8,Ord((CC and FLAG_C)<>0)); Result:=2 end;
    $8A: begin A:=A or Fetch8; LogicFlags(A); Result:=2 end;
    $8B: begin A:=Add8(A,Fetch8,0); Result:=2 end;
    $8C: begin V16:=Fetch16; Compare16(X,V16); Result:=3 end;
    $8D: begin V8:=Fetch8; PushW(PC); PC:=Word(Integer(PC)+ShortInt(V8)); Result:=8 end;
    $8E: begin SP:=Fetch16; SetNZV16(SP); Result:=3 end;

    $90: begin EA:=EADirect; A:=Sub8(A,R(EA),0); Result:=3 end;
    $91: begin EA:=EADirect; Sub8(A,R(EA),0); Result:=3 end;
    $92: begin EA:=EADirect; A:=Sub8(A,R(EA),Ord((CC and FLAG_C)<>0)); Result:=3 end;
    $94: begin EA:=EADirect; A:=A and R(EA); LogicFlags(A); Result:=3 end;
    $95: begin EA:=EADirect; V8:=A and R(EA); LogicFlags(V8); Result:=3 end;
    $96: begin EA:=EADirect; A:=R(EA); SetNZV8(A); Result:=3 end;
    $97: begin EA:=EADirect; W(EA,A); StoreFlags8(A); Result:=4 end;
    $98: begin EA:=EADirect; A:=A xor R(EA); LogicFlags(A); Result:=3 end;
    $99: begin EA:=EADirect; A:=Add8(A,R(EA),Ord((CC and FLAG_C)<>0)); Result:=3 end;
    $9A: begin EA:=EADirect; A:=A or R(EA); LogicFlags(A); Result:=3 end;
    $9B: begin EA:=EADirect; A:=Add8(A,R(EA),0); Result:=3 end;
    $9C: begin EA:=EADirect; Compare16(X,RW(EA)); Result:=4 end;
    $9E: begin EA:=EADirect; SP:=RW(EA); SetNZV16(SP); Result:=4 end;
    $9F: begin EA:=EADirect; W(EA,Byte(SP shr 8)); W(EA+1,Byte(SP)); StoreFlags16(SP); Result:=5 end;

    $A0: begin EA:=EAIndexed; A:=Sub8(A,R(EA),0); Result:=5 end;
    $A1: begin EA:=EAIndexed; Sub8(A,R(EA),0); Result:=5 end;
    $A2: begin EA:=EAIndexed; A:=Sub8(A,R(EA),Ord((CC and FLAG_C)<>0)); Result:=5 end;
    $A4: begin EA:=EAIndexed; A:=A and R(EA); LogicFlags(A); Result:=5 end;
    $A5: begin EA:=EAIndexed; V8:=A and R(EA); LogicFlags(V8); Result:=5 end;
    $A6: begin EA:=EAIndexed; A:=R(EA); SetNZV8(A); Result:=5 end;
    $A7: begin EA:=EAIndexed; W(EA,A); StoreFlags8(A); Result:=6 end;
    $A8: begin EA:=EAIndexed; A:=A xor R(EA); LogicFlags(A); Result:=5 end;
    $A9: begin EA:=EAIndexed; A:=Add8(A,R(EA),Ord((CC and FLAG_C)<>0)); Result:=5 end;
    $AA: begin EA:=EAIndexed; A:=A or R(EA); LogicFlags(A); Result:=5 end;
    $AB: begin EA:=EAIndexed; A:=Add8(A,R(EA),0); Result:=5 end;
    $AC: begin EA:=EAIndexed; Compare16(X,RW(EA)); Result:=6 end;
    $AD: begin EA:=EAIndexed; PushW(PC); PC:=EA; Result:=8 end;
    $AE: begin EA:=EAIndexed; SP:=RW(EA); SetNZV16(SP); Result:=6 end;
    $AF: begin EA:=EAIndexed; W(EA,Byte(SP shr 8)); W(EA+1,Byte(SP)); StoreFlags16(SP); Result:=7 end;

    $B0: begin EA:=EAExtended; A:=Sub8(A,R(EA),0); Result:=4 end;
    $B1: begin EA:=EAExtended; Sub8(A,R(EA),0); Result:=4 end;
    $B2: begin EA:=EAExtended; A:=Sub8(A,R(EA),Ord((CC and FLAG_C)<>0)); Result:=4 end;
    $B4: begin EA:=EAExtended; A:=A and R(EA); LogicFlags(A); Result:=4 end;
    $B5: begin EA:=EAExtended; V8:=A and R(EA); LogicFlags(V8); Result:=4 end;
    $B6: begin EA:=EAExtended; A:=R(EA); SetNZV8(A); Result:=4 end;
    $B7: begin EA:=EAExtended; W(EA,A); StoreFlags8(A); Result:=5 end;
    $B8: begin EA:=EAExtended; A:=A xor R(EA); LogicFlags(A); Result:=4 end;
    $B9: begin EA:=EAExtended; A:=Add8(A,R(EA),Ord((CC and FLAG_C)<>0)); Result:=4 end;
    $BA: begin EA:=EAExtended; A:=A or R(EA); LogicFlags(A); Result:=4 end;
    $BB: begin EA:=EAExtended; A:=Add8(A,R(EA),0); Result:=4 end;
    $BC: begin EA:=EAExtended; Compare16(X,RW(EA)); Result:=5 end;
    $BD: begin EA:=EAExtended; PushW(PC); PC:=EA; Result:=9 end;
    $BE: begin EA:=EAExtended; SP:=RW(EA); SetNZV16(SP); Result:=5 end;
    $BF: begin EA:=EAExtended; W(EA,Byte(SP shr 8)); W(EA+1,Byte(SP)); StoreFlags16(SP); Result:=6 end;

    { B accumulator and X register group }
    $C0: begin B:=Sub8(B,Fetch8,0); Result:=2 end;
    $C1: begin Sub8(B,Fetch8,0); Result:=2 end;
    $C2: begin B:=Sub8(B,Fetch8,Ord((CC and FLAG_C)<>0)); Result:=2 end;
    $C4: begin B:=B and Fetch8; LogicFlags(B); Result:=2 end;
    $C5: begin V8:=B and Fetch8; LogicFlags(V8); Result:=2 end;
    $C6: begin B:=Fetch8; SetNZV8(B); Result:=2 end;
    $C8: begin B:=B xor Fetch8; LogicFlags(B); Result:=2 end;
    $C9: begin B:=Add8(B,Fetch8,Ord((CC and FLAG_C)<>0)); Result:=2 end;
    $CA: begin B:=B or Fetch8; LogicFlags(B); Result:=2 end;
    $CB: begin B:=Add8(B,Fetch8,0); Result:=2 end;
    $CE: begin X:=Fetch16; SetNZV16(X); Result:=3 end;

    $D0: begin EA:=EADirect; B:=Sub8(B,R(EA),0); Result:=3 end;
    $D1: begin EA:=EADirect; Sub8(B,R(EA),0); Result:=3 end;
    $D2: begin EA:=EADirect; B:=Sub8(B,R(EA),Ord((CC and FLAG_C)<>0)); Result:=3 end;
    $D4: begin EA:=EADirect; B:=B and R(EA); LogicFlags(B); Result:=3 end;
    $D5: begin EA:=EADirect; V8:=B and R(EA); LogicFlags(V8); Result:=3 end;
    $D6: begin EA:=EADirect; B:=R(EA); SetNZV8(B); Result:=3 end;
    $D7: begin EA:=EADirect; W(EA,B); StoreFlags8(B); Result:=4 end;
    $D8: begin EA:=EADirect; B:=B xor R(EA); LogicFlags(B); Result:=3 end;
    $D9: begin EA:=EADirect; B:=Add8(B,R(EA),Ord((CC and FLAG_C)<>0)); Result:=3 end;
    $DA: begin EA:=EADirect; B:=B or R(EA); LogicFlags(B); Result:=3 end;
    $DB: begin EA:=EADirect; B:=Add8(B,R(EA),0); Result:=3 end;
    $DE: begin EA:=EADirect; X:=RW(EA); SetNZV16(X); Result:=4 end;
    $DF: begin EA:=EADirect; W(EA,Byte(X shr 8)); W(EA+1,Byte(X)); StoreFlags16(X); Result:=5 end;

    $E0: begin EA:=EAIndexed; B:=Sub8(B,R(EA),0); Result:=5 end;
    $E1: begin EA:=EAIndexed; Sub8(B,R(EA),0); Result:=5 end;
    $E2: begin EA:=EAIndexed; B:=Sub8(B,R(EA),Ord((CC and FLAG_C)<>0)); Result:=5 end;
    $E4: begin EA:=EAIndexed; B:=B and R(EA); LogicFlags(B); Result:=5 end;
    $E5: begin EA:=EAIndexed; V8:=B and R(EA); LogicFlags(V8); Result:=5 end;
    $E6: begin EA:=EAIndexed; B:=R(EA); SetNZV8(B); Result:=5 end;
    $E7: begin EA:=EAIndexed; W(EA,B); StoreFlags8(B); Result:=6 end;
    $E8: begin EA:=EAIndexed; B:=B xor R(EA); LogicFlags(B); Result:=5 end;
    $E9: begin EA:=EAIndexed; B:=Add8(B,R(EA),Ord((CC and FLAG_C)<>0)); Result:=5 end;
    $EA: begin EA:=EAIndexed; B:=B or R(EA); LogicFlags(B); Result:=5 end;
    $EB: begin EA:=EAIndexed; B:=Add8(B,R(EA),0); Result:=5 end;
    $EC: begin { MB8861 ADX immediate: X + unsigned immediate byte -> X }
      V8:=Fetch8; Tmp16:=X; X:=Word(LongWord(X)+LongWord(V8));
      CC:=CC and not (FLAG_N or FLAG_Z or FLAG_V or FLAG_C);
      if X=0 then CC:=CC or FLAG_Z;
      if (X and $8000)<>0 then CC:=CC or FLAG_N;
      if ((not(Tmp16 xor Word(V8)) and (Tmp16 xor X) and $8000)<>0) then CC:=CC or FLAG_V;
      if LongWord(Tmp16)+LongWord(V8)>$FFFF then CC:=CC or FLAG_C;
      Result:=4
    end;
    $EE: begin EA:=EAIndexed; X:=RW(EA); SetNZV16(X); Result:=6 end;
    $EF: begin EA:=EAIndexed; W(EA,Byte(X shr 8)); W(EA+1,Byte(X)); StoreFlags16(X); Result:=7 end;

    $F0: begin EA:=EAExtended; B:=Sub8(B,R(EA),0); Result:=4 end;
    $F1: begin EA:=EAExtended; Sub8(B,R(EA),0); Result:=4 end;
    $F2: begin EA:=EAExtended; B:=Sub8(B,R(EA),Ord((CC and FLAG_C)<>0)); Result:=4 end;
    $F4: begin EA:=EAExtended; B:=B and R(EA); LogicFlags(B); Result:=4 end;
    $F5: begin EA:=EAExtended; V8:=B and R(EA); LogicFlags(V8); Result:=4 end;
    $F6: begin EA:=EAExtended; B:=R(EA); SetNZV8(B); Result:=4 end;
    $F7: begin EA:=EAExtended; W(EA,B); StoreFlags8(B); Result:=5 end;
    $F8: begin EA:=EAExtended; B:=B xor R(EA); LogicFlags(B); Result:=4 end;
    $F9: begin EA:=EAExtended; B:=Add8(B,R(EA),Ord((CC and FLAG_C)<>0)); Result:=4 end;
    $FA: begin EA:=EAExtended; B:=B or R(EA); LogicFlags(B); Result:=4 end;
    $FB: begin EA:=EAExtended; B:=Add8(B,R(EA),0); Result:=4 end;
    $FC: begin { MB8861 ADX extended: X + big-endian 16-bit M -> X }
      EA:=EAExtended; V16:=RW(EA); Tmp16:=X; X:=Word(LongWord(X)+LongWord(V16));
      CC:=CC and not (FLAG_N or FLAG_Z or FLAG_V or FLAG_C);
      if X=0 then CC:=CC or FLAG_Z;
      if (X and $8000)<>0 then CC:=CC or FLAG_N;
      if ((not(Tmp16 xor V16) and (Tmp16 xor X) and $8000)<>0) then CC:=CC or FLAG_V;
      if LongWord(Tmp16)+LongWord(V16)>$FFFF then CC:=CC or FLAG_C;
      Result:=7
    end;
    $FE: begin EA:=EAExtended; X:=RW(EA); SetNZV16(X); Result:=5 end;
    $FF: begin EA:=EAExtended; W(EA,Byte(X shr 8)); W(EA+1,Byte(X)); StoreFlags16(X); Result:=6 end;

  else
    Illegal;
  end;
end;

end.
