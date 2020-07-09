// Above all other messages.
class SmartCTFMessage extends LocalMessagePlus;

var string CoveredMsg, YouCoveredMsg;
var string CoverSpreeMsg, YouCoverSpreeMsg;
var string UltraCoverMsg, YouUltraCoverMsg;
var string SealMsg, YouSealMsg;
var string SavedMsg, YouSavedMsg;
var string SpawnKillMsg;

static function float GetOffset( int Switch, float YL, float ClipY )
{
  return ( default.YPos / 768.0 ) * ClipY - 3 * YL;
}

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  if (RelatedPRI_1 == None) return "";

  switch( Switch )
  {
    case 0: // Cover FC
      return RelatedPRI_1.PlayerName @ default.CoveredMsg;
    case 1: // Seal base
      return RelatedPRI_1.PlayerName @ default.SealMsg;
    case 4: // Ultra cover
      return RelatedPRI_1.PlayerName @ default.UltraCoverMsg;
    case 5: // Cover spree
      return RelatedPRI_1.PlayerName @ default.CoverSpreeMsg;
    case 7: // Saved by ...
      return default.SavedMsg @ RelatedPRI_1.PlayerName $ "!";
    case 10: // Spawnkilling
      return RelatedPRI_1.PlayerName @ default.SpawnKillMsg;

    case 0 + 64:
      return default.YouCoveredMsg;
    case 1 + 64:
      return default.YouSealMsg;
    case 4 + 64:
      return default.YouUltraCoverMsg;
    case 5 + 64:
      return default.YouCoverSpreeMsg;
    case 7 + 64:
      return default.YouSavedMsg;
  }
  return "";
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  super.ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

  switch( Switch )
  {
    case 5: // Cover spree - guitarsound for player, spreesound for all
      if( RelatedPRI_1 == P.PlayerReplicationInfo ) P.ClientPlaySound( sound'CaptureSound', , true );
      else P.PlaySound( sound'SpreeSound', , 4.0 );
      break;
  }
}

defaultproperties
{
     CoveredMsg="covered the flagcarrier!"
     YouCoveredMsg="You covered the flagcarrier!"
     CoverSpreeMsg="is on a cover spree!"
     YouCoverSpreeMsg="You are on a cover spree!"
     UltraCoverMsg="got a multi cover!"
     YouUltraCoverMsg="You got a multi cover!"
     SealMsg="is sealing off the base!"
     YouSealMsg="You are sealing off the base!"
     SavedMsg="Saved By"
     YouSavedMsg="Close save!!"
     SpawnKillMsg="is a spawnkilling lamer!"
     FontSize=1
     bIsSpecial=True
     bIsUnique=True
     bFadeMessage=True
     DrawColor=(R=24,G=192,B=24)
     YPos=196.000000
     bCenter=True
}
