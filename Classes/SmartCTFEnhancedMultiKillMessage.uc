//=============================================================================
// SmartCTFEnhancedMultiKillMessage.
// - v1.0 29-Feb-2004 by {DnF2}SiNiSTeR -
// SmartCTF Edited by SC]-[WARTZ_{HoF} May 2017
//=============================================================================
class SmartCTFEnhancedMultiKillMessage extends MultiKillMessage;

#exec AUDIO IMPORT FILE="Sounds\DoubleKill_F.wav" NAME="DoubleKill" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\MultiKill_F.wav" NAME="MultiKill" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\MegaKill_F.wav" NAME="MegaKill" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\UltraKill_F.wav" NAME="UltraKill" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\MonsterKill_F.wav" NAME="MonsterKill" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\LudicrousKill_F.wav" NAME="LudicrousKill" GROUP="Sounds"
#exec AUDIO IMPORT FILE="Sounds\HolyShitKill_F.wav" NAME="HolyShitKill" GROUP="Sounds"

var(Messages) localized string DoubleKillString;
var(Messages) localized string MultiKillString;
var(Messages) localized string MegaKillString;
var(Messages) localized string UltraKillString;
var(Messages) localized string MonsterKillString;
var(Messages) localized string LudicrousKillString;
var(Messages) localized string HolyShitKillString;

static function int GetFontSize( int Switch )
{
  if( Switch < 3 ) return default.FontSize;
  else return 2;
}

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  switch( Switch )
  {
    case 0:  return "";
       break;
    case 1:  return default.DoubleKillString;
       break;
    case 2:  return default.MultiKillString;
       break;
    case 3:  return default.MegaKillString;
       break;
    case 4:  return default.UltraKillString;
       break;
    case 5:  return default.MonsterKillString;
      break;
    case 6:  return default.LudicrousKillString;
       break;
    default:  return default.HolyShitKillString;
       break;
  }
}

static function string GetBroadcastString( int MultiLevel )
{
  if( MultiLevel == 8 ) return "had an" @ static.GetString( MultiLevel );
  else return "had a" @ static.GetString( MultiLevel );
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  super( LocalMessagePlus ).ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

  switch( Switch )
  {
    case 0:  break;
    case 1:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.DoubleKill', , true );
       break;
    case 2:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.MultiKill', , true );
       break;
    case 3:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.MegaKill', , true );
       break;
    case 4:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.UltraKill', , true );
       break;
    case 5:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.MonsterKill', , true );
       break;
    case 6:  P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.LudicrousKill', , true );
       break;
    default: P.ClientPlaySound( sound'SmartCTF_4F_002.Sounds.HolyShitKill', , true );
       break;
  }
}

static function color GetColor( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2 )
{
  local Color cres;

  cres = Default.DrawColor;
  if( Switch >= 1 && Switch <= 5 )
  {
    cres.G = 48 * ( 5 - Switch );
    return cres;
  }
  else if( Switch > 5 )
  {
    cres.B = Min( 48 * ( Switch - 5 ), 255 );
    return cres;
  }
  else
  {
    return cres;
  }
}

defaultproperties
{
     DoubleKillString="Double Kill!"
     MultiKillString="Multi Kill!"
     MegaKillString="Mega Kill!"
     UltraKillString="ULTRA KILL!!"
     MonsterKillString="M O N S T E R   K I L L !!"
     LudicrousKillString="L U D I C R O U S   K I L L  !!!"
     HolyShitKillString="H O L Y   S H I T !!!"
}
