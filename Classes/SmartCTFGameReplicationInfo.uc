// This class gets spawned in the mutator, serverside.
// Because of its Role, it will also get copied to clients.
// The replicated variables are accessible there.

class SmartCTFGameReplicationInfo expands ReplicationInfo;

var int TickRate;
var bool bShowFCLocation, bStatsDrawFaces, bPlay30SecSound, bDrawLogo, bExtraStats, bShowSpecs, bDoKeybind;
var float SbDelayC;
var string CountryFlagsPackage;
var class<ScoreBoard> NormalScoreBoardClass;
var SmartCTFEndStats EndStats;
var SmartCTFPlayerReplicationInfo PRIArray[64];
var bool bInitialized, bServerInfoSetServerSide, bDoneBind;
var class<HUD> DefaultHUDType;
var bool bShowFrags;
var Mutator WarmupMutator;
var bool bWarmup;

replication
{
  // Settings
  reliable if( Role == ROLE_Authority )
    bDoKeybind,
    bDrawLogo,
    bExtraStats,
    bInitialized,
    bPlay30SecSound,
    bServerInfoSetServerSide,
    bShowFCLocation,
    bShowFrags,
    bShowSpecs,
    bStatsDrawFaces,
    bWarmup,
    CountryFlagsPackage,
    DefaultHUDType,
    DoBind,
    EndStats,
    NormalScoreBoardClass,
    SbDelayC,
    TickRate;
}

simulated function PostBeginPlay()
{
  //default.NormalScoreBoardClass = Level.Game.ScoreBoardType;
  SetTimer( 0.5, True );
}

simulated function Timer()
{
  local PlayerPawn P;
  local int i;

  RefreshPRI();

  if (Role == ROLE_Authority) {
    for(i = 0; PRIArray[i] != none; ++i)
      if (PRIArray[i].Owner != none && PRIArray[i].Owner.Owner != none &&  PRIArray[i].Owner.Owner.IsA('PlayerPawn'))
        PRIArray[i].bIsReady = PlayerPawn(PRIArray[i].Owner.Owner).bReadyToPlay;

    bWarmup = IsInWarmup();
  }

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

simulated function Mutator FindWarmupMutator() {
  if (WarmupMutator != none)
    return WarmupMutator;

  foreach AllActors(class'Mutator', WarmupMutator)
    if (WarmupMutator.IsA('MutWarmup'))
      break;

  if (WarmupMutator.IsA('MutWarmup') == false)
    WarmupMutator = none;

  return WarmupMutator;
}

simulated function bool IsInWarmup() {
  local Mutator M;
  local string S;
  local ENetRole R;

  if (Role == ROLE_Authority)
  {
    M = FindWarmupMutator();
    if (M == none)
      return false;

    R = M.Role;
    M.Role = ROLE_Authority;
    S = M.GetPropertyText("bInWarmup");
    M.Role = R;

    return S ~= "true" || DeathMatchPlus(Level.Game).CountDown > 0;
  }
  else
  {
    return bWarmup;
  }
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
}
