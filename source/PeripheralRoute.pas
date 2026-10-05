unit PeripheralRoute;
interface
type
  TPeripheralRoute = class
  private
    FCassetteActive, FUsedPreparation: Boolean;
    FUsedGeneration:Cardinal;
  public
    procedure Update(PortBPins: Byte; TapeReady: Boolean; Preparation:Cardinal=0);
    property CassetteActive: Boolean read FCassetteActive;
    function OrganConnected: Boolean;
  end;
implementation
procedure TPeripheralRoute.Update(PortBPins:Byte;TapeReady:Boolean;Preparation:Cardinal);
begin
  { WAV prepared/recording armed + physical relay ON selects tape.
    Keep it selected through EOF/stop until the relay goes OFF. }
  if (PortBPins and $02)<>0 then FCassetteActive:=False
  else if TapeReady and not FCassetteActive and
          (not FUsedPreparation or (Preparation<>FUsedGeneration)) then
  begin
    FCassetteActive:=True;FUsedPreparation:=True;FUsedGeneration:=Preparation;
  end;
end;
function TPeripheralRoute.OrganConnected:Boolean;
begin Result:=not FCassetteActive end;
end.
