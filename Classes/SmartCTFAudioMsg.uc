// This is a fix to be able to get certain sounds to play. Certain sounds like Assist and Capture only
// work on the client. By simply sending this message instead of ClientPlaySound on the server we don't need
// to include the sounds in the pack.

class SmartCTFAudioMsg expands LocalMessagePlus;

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  return "";
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  super.ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

  switch( Switch )
  {
    case 0:  P.ClientPlaySound( sound'Announcer.capture', , true );
       break;
    case 1:  P.ClientPlaySound( sound'Announcer.assist', , true );
       break;
    case 2:  P.ClientPlaySound( sound'Announcer.nicecatch', , true );
       break;
    case 3:  P.ClientPlaySound( sound'Announcer.takenlead', , true );
       break;
    case 4:  P.ClientPlaySound( sound'Announcer.lostlead', , true );
       break;
  }
}

defaultproperties
{
     bIsConsoleMessage=False
     Lifetime=0
}
