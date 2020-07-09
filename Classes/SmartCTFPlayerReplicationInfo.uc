class SmartCTFPlayerReplicationInfo expands ReplicationInfo;

// Replicated
var int Captures, Assists, Grabs, Covers, Seals, FlagKills;
var int Frags, HeadShots, ShieldBelts, Amps;

// Server side
var float LastKillTime;
var int MultiLevel;
var int FragSpree, CoverSpree, SealSpree, SpawnKillSpree;
var float SpawnTime;
var bool bHadFirstSpawn;

// Client side
var bool bViewingStats;
var float IndicatorStartShow;
var byte IndicatorVisibility;

replication
{
  // Stats
  reliable if( Role == ROLE_Authority )
    Captures, Assists, Grabs, Covers, Seals, FlagKills,
    Frags, HeadShots, ShieldBelts, Amps;

  // Toggle stats functions
  reliable if( Role == ROLE_Authority )
    ToggleStats, ShowStats;
}

function PostBeginPlay()
{
  super.PostBeginPlay();

  SetTimer( 0.5, True );
}

function Timer()
{
  if( Owner == None )
  {
    SetTimer( 0.0, False );
    Destroy();
  }
}

// Called on the server, executed on the client
simulated function ToggleStats()
{
  local PlayerPawn P;

  if( Owner == None ) return;
  P = PlayerPawn( Owner.Owner );
  if( P == None ) return;

  if( P.Scoring != None && !P.Scoring.IsA( 'SmartCTFScoreBoard' ) )
  {
    P.ClientMessage( "Problem loading the SmartCTF ScoreBoard..." );
  }
  else
  {
    bViewingStats = !bViewingStats;
    IndicatorStartShow = Level.TimeSeconds;
    IndicatorVisibility = 255;
    P.bShowScores = True;
  }
}

// Called on the client
simulated function ShowStats()
{
  local PlayerPawn P;

  if( Owner == None ) return;
  P = PlayerPawn( Owner.Owner );
  if( P == None ) return;

  if( P.Scoring != None && !P.Scoring.IsA( 'SmartCTFScoreBoard' ) )
  {
    P.ClientMessage( "Problem loading the SmartCTF ScoreBoard..." );
  }
  else
  {
    bViewingStats = True;
    P.bShowScores = True;
  }
}

function ClearStats()
{
  Captures = 0;
  Assists = 0;
  Grabs = 0;
  Covers = 0;
  Seals = 0;
  FlagKills = 0;
  Frags = 0;
  HeadShots = 0;
  ShieldBelts = 0;
  Amps = 0;

  FragSpree = 0;
  CoverSpree = 0;
  SealSpree = 0;
  SpawnKillSpree = 0;
  SpawnTime = 0;

  LastKillTime = 0;
  MultiLevel = 0;
}

defaultproperties
{
}
