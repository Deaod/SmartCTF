// This class gets spawned in the mutator, serverside.
// Because of its Role, it will also get copied to clients.
// The replicated variables are accessible there.

class SmartCTFGameReplicationInfo expands ReplicationInfo;

var int TickRate;
var bool bShowFCLocation, bStatsDrawFaces, bPlay30SecSound, bDrawLogo, bExtraStats, bShowSpecs, bDoKeybind, bSCTFSbDef, bSnowyScoreboard, bXmasImages;
var float SbDelayC;
var color SpectatorColor;
var string CountryFlagsPackage;
var class<ScoreBoard> NormalScoreBoardClass;
var SmartCTFEndStats EndStats;
var SmartCTFPlayerReplicationInfo PRIArray[64];
var bool bInitialized, bServerInfoSetServerSide, bDoneBind;
var class<HUD> DefaultHUDType;

replication
{
  // Settings
  reliable if( Role == ROLE_Authority )
    bShowFCLocation, bPlay30SecSound, bStatsDrawFaces, bDrawLogo, bExtraStats, CountryFlagsPackage, bShowSpecs, bSCTFSbDef, bDoKeybind, bSnowyScoreboard, bXmasImages;

  reliable if( Role == ROLE_Authority )
    bInitialized, TickRate, NormalScoreBoardClass, EndStats, bServerInfoSetServerSide, DefaultHUDType, DoBind, SbDelayC, SpectatorColor;
}

simulated function PostBeginPlay()
{
  //default.NormalScoreBoardClass = Level.Game.ScoreBoardType;
  SetTimer( 0.5, True );
}

simulated function Timer()
{
	local PlayerPawn P;

	RefreshPRI();

	if (Level.Netmode == NM_DedicatedServer || bDoneBind || !bDoKeybind) return; // Only execute on clients,  if bind hasn't been done yet and if bind should be done.

	foreach AllActors(class 'PlayerPawn', P)
	if (Viewport(P.Player) != None) break;
	if(P!=None) DoBind(P);
	bDoneBind=true;
}

simulated function SmartCTFPlayerReplicationInfo GetStats( Actor P )
{
  local int i;
  local PlayerReplicationInfo PRI;

  if( !P.IsA( 'Pawn' ) ) return None;
  PRI = Pawn( P ).PlayerReplicationInfo;
  if( PRI == None ) return None;

  for( i = 0; i < 64; i++ )
  {
    if( PRIArray[i] == None ) break;
    if( PRIArray[i].Owner == PRI ) return PRIArray[i];
  }
  return None;
}

simulated function SmartCTFPlayerReplicationInfo GetStatsByPRI( PlayerReplicationInfo PRI )
{
  local int i;

  if( PRI == None ) return None;
  for( i = 0; i < 64; i++ )
  {
    if( PRIArray[i] == None ) break;
    if( PRIArray[i].Owner == PRI ) return PRIArray[i];
  }
  return None;
}

simulated function SmartCTFPlayerReplicationInfo GetStatNr( byte i )
{
  return PRIArray[i];
}

simulated function ClearStats()
{
  local int i;
  for( i = 0; i < 64; i++ )
  {
    if( PRIArray[i] == None ) break;
    PRIArray[i].ClearStats();
  }
}

simulated function RefreshPRI()
{
  local SmartCTFPlayerReplicationInfo PRI;
  local int i;

  for( i = 0; i < 64; i++ ) PRIArray[i] = None;

  i = 0;
  ForEach AllActors( class'SmartCTFPlayerReplicationInfo', PRI )
  {
    if( i < 64 )
    {
      if( PRI.Owner != None ) PRIArray[i++] = PRI;
    }
    else break;
  }
}

simulated function DoBind(PlayerPawn P)
{	
	local string keyBinding;

		if ((InStr( Caps(P.ConsoleCommand("Keybinding F3")), "MUTATE SMARTCTF SHOWSTATS") == -1))
		{
			keyBinding = P.ConsoleCommand("Keybinding F3");
			P.ConsoleCommand("SET INPUT F3 mutate smartctf showstats|"$keyBinding);
		}
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
}
