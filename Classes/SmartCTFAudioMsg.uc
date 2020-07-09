// This is a fix to be able to get certain sounds to play. Certain sounds like Assist and Capture only
// work on the client. By simply sending this message instead of ClientPlaySound on the server we don't need
// to include the sounds in the pack.

class SmartCTFAudioMsg expands LocalMessagePlus;

#exec AUDIO IMPORT FILE="Sounds\capture.wav" NAME="capture" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\assist.wav" NAME="assist" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\nicecatch.wav" NAME="nicecatch" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\takeslead.wav" NAME="takeslead" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\lostLead.wav" NAME="lostLead" GROUP="Sounds"

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  return "";
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  super.ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

  switch( Switch )
  {
    case 0:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.capture', , true );
       break;
    case 1:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.assist', , true );
       break;
    case 2:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.nicecatch', , true );
       break;
    case 3:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.takeslead', , true );
       break;
    case 4:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.lostlead', , true );
       break;
  }
}

defaultproperties
{
     bIsConsoleMessage=False
     Lifetime=0
}
