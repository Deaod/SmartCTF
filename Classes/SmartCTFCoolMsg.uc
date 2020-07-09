class SmartCTFCoolMsg expands LocalMessagePlus;

var(Messages) string LongRangeString;
var(Messages) string UberLongRangeString;
var(Messages) string SpawnLamerString;
var(Messages) string OvertimeEnabledString;
var(Messages) string OvertimeDisabledString;
var Color EnabledColor, DisabledColor, SpawnLamerColor;

static function float GetOffset(int Switch, float YL, float ClipY )
{
  return ( default.YPos / 768.0 ) * ClipY - 2 * YL;
}

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  switch( Switch )
  {
    case 1: return default.LongRangeString;
    case 2: return default.UberLongRangeString;
    case 3: return default.OvertimeEnabledString;
    case 4: return default.OvertimeDisabledString;
    case 5: return default.SpawnLamerString;
  }
  return "";
}

static function Color GetColor( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2 )
{
  switch( Switch )
  {
    case 1: return default.DrawColor;
    case 2: return default.DrawColor;
    case 3: return default.EnabledColor;
    case 4: return default.DisabledColor;
    case 5: return default.SpawnLamerColor;
  }
  return default.DrawColor;
}

defaultproperties
{
     LongRangeString="Long Range Kill!"
     UberLongRangeString="Über Long Range Kill!"
     SpawnLamerString="Spawnkill..."
     OvertimeEnabledString="Sudden Death Overtime = Enabled"
     OvertimeDisabledString="Sudden Death Overtime = DISABLED"
     EnabledColor=(R=128,G=255,B=192)
     DisabledColor=(R=255,G=192,B=128)
     SpawnLamerColor=(R=255,G=64)
     FontSize=1
     bIsSpecial=True
     bIsUnique=True
     bFadeMessage=True
     DrawColor=(G=224,B=224)
     YPos=196.000000
     bCenter=True
}
