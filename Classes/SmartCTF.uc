// SmartCTF 4 by {PiN}Kev. Released January 2004.
// SmartCTF 4A Tweaked by {DnF2}SiNiSTeR. Released December 2004.
// SmartCTF 4B/4C Uber Massively tweaked by {DnF2}SiNiSTeR. Released March 2005.
// SmartCTF 4D with IpToCountry by [es]Rush. Released January 2006.
// SmartCTF 4D++ by adminthis. Released October 2008.
//
// This mod changes the point system and adds features to ultimately promote Teamwork in CTF.
// This is a CTF Mod only. It will not load in any other gametype.
//
// Contact Info: private Message me, {PiN}Hai-Ping, on http://forums.prounreal.com
//               {DnF2}SiNiSTeR @ #DutchNet [QuakeNet IRC]
//       or if it is about version 4D explicictly
//               Rush on unrealadmin.org forums / mail and msn: rush@u.one.pl
//	or if it is about version 4D++ explicictly
//               adminthis on unrealadmin.org
//
//
// CHANGELOG: See Readme

class SmartCTF expands Mutator config( SmartCTF_4DPlusPlus );

#exec texture IMPORT NAME=meter FILE=Textures\meter.pcx GROUP=SmartCTF MIPS=OFF
#exec texture IMPORT NAME=shade File=Textures\shade.pcx GROUP=SmartCTF MIPS=OFF
#exec texture IMPORT NAME=powered File=Textures\powered.pcx GROUP=SmartCTF MIPS=OFF

/* Server Vars */
var SmartCTFGameReplicationInfo SCTFGame;
var byte RedAstIndex, BlueAstIndex;
var byte TRCount;
var string Version, GameTieMessage;
var Pawn FCs[2], RedAssisters[32], BlueAssisters[32];
var Pawn RedFlagCarrier[32], BlueFlagCarrier[32];
var float RedFlagCarrierTime[32], BlueFlagCarrierTime[32];
var byte RedFCIndex, BlueFCIndex;
var float RedAssistTimes[32], BlueAssistTimes[32], PickupTime[2];
var FlagBase FlagStands[2];
var bool bForcedEndGame, bTournamentGameStarted, bTooCloseForSaves, bStartTimeCorrected;
var int MsgPID;
var	string	GoneName[32];		//list of disconnected players
var	string	GoneIP[32];			//corresponding IP addy
var	float	GoneScore[32];		//corresponding scores
var	float	GoneDeaths[32];		//corresponding deaths
var SmartCTFPlayerReplicationInfo GoneStats[32];//corresponding smartCTF stats
var	string	StoreName[32];		//list of stored playernames
var	float	StoreScore[32];		//corresponding scores
var	float	StoreDeaths[32];	//corresponding deaths
var	string	StoreIP[32];		//corresponding IP addy
var SmartCTFPlayerReplicationInfo StoreStats[32];//corresponding stored smartCTF stats
// First backup array
var	string	B1Name[32];		//list of stored playernames
var	float	B1Score[32];	//corresponding scores
var	float	B1Deaths[32];	//corresponding deaths
var	string	B1IP[32];		//corresponding IP addy
var SmartCTFPlayerReplicationInfo B1Stats[32];//corresponding stored smartCTF stats
// Second backup array
var	string	B2Name[32];		//list of stored playernames
var	float	B2Score[32];	//corresponding scores
var	float	B2Deaths[32];	//corresponding deaths
var	string	B2IP[32];		//corresponding IP addy
var SmartCTFPlayerReplicationInfo B2Stats[32];//corresponding stored smartCTF stats
var	string	QuitMsg;		//the broadcast message when someone leaves the game
var	int		QuitMsgLen;		//length of QuitMsg

/* Client Vars */
var bool bClientJoinPlayer, bGameEnded, bInitSb;
var int LogoCounter, DrawLogo, SbCount;
var float SbDelayC;
var PlayerPawn PlayerOwner;
var FontInfo MyFonts;
var TournamentGameReplicationInfo pTGRI;
var PlayerReplicationInfo pPRI;
var ChallengeHUD MyHUD;
var Color RedTeamColor, BlueTeamColor, White, Gray;

/* Server Vars Configurable */
var() config bool bEnabled;
var() config bool bExtraStats;
var() config string CountryFlagsPackage;
var(SmartCTFBonuses) config int CapBonus, AssistBonus, FlagKillBonus, CoverBonus, SealBonus, GrabBonus;
var(SmartCTFBonuses) config float BaseReturnBonus, MidReturnBonus, EnemyBaseReturnBonus, CloseSaveReturnBonus;
var(SmartCTFBonuses) config int SpawnKillPenalty, MinimalCapBonus;
var() config bool bFixFlagBug;
var() config bool bEnhancedMultiKill;
var() config byte EnhancedMultiKillBroadcast;
var() config bool bShowFCLocation;
var() config bool bSmartCTFServerInfo;
var() config bool bNewCapAssistScoring;
var() config bool bSpawnkillDetection;
var() config float SpawnKillTimeArena;
var() config float SpawnKillTimeNW;
var() config bool bAfterGodLikeMsg;
var() config bool bStatsDrawFaces;
var() config bool bDrawLogo;
var() config bool bSCTFSbDef;
var() config bool bShowSpecs;
var() config bool bDoKeybind;
var() config bool bExtraMsg;
var() config float SbDelay;
var() config float MsgDelay;
var() config bool  bStoreStats;
var(SmartCTFMessages) config byte CoverMsgType;
var(SmartCTFMessages) config byte CoverSpreeMsgType;
var(SmartCTFMessages) config byte SealMsgType;
var(SmartCTFMessages) config byte SavedMsgType;
var(SmartCTFMessages) config bool bShowLongRangeMsg;
var(SmartCTFMessages) config bool bShowSpawnKillerGlobalMsg;
var(SmartCTFMessages) config bool bShowAssistConsoleMsg;
var(SmartCTFMessages) config bool bShowSealRewardConsoleMsg;
var(SmartCTFMessages) config bool bShowCoverRewardConsoleMsg;
var(SmartCTFSounds) config bool bPlayCaptureSound;
var(SmartCTFSounds) config bool bPlayAssistSound;
var(SmartCTFSounds) config bool bPlaySavedSound;
var(SmartCTFSounds) config bool bPlayLeadSound;
var(SmartCTFSounds) config bool bPlay30SecSound;
var(OvertimeControl) config bool bEnableOvertimeControl;
var(OvertimeControl) config bool bOvertime;
var(OvertimeControl) config bool bRememberOvertimeSetting;

var texture powered;

/*
 * Check if we should spawn a SmartCTF instance.
 * This check doesn't seem to work properly in PostBeginPlay, hence here.
 */
event Spawned()
{
  super.Spawned();

  SCTFGame = Level.Game.Spawn( class'SmartCTFGameReplicationInfo' );

  if( !ValidateSmartCTFMutator() )
  {
    SCTFGame.Destroy();
    Destroy();
  }
}

/*
 * Get the original Scoreboard and store for SmartCTFScoreboard reference.
 */
function PreBeginPlay()
{
  local Mutator M;

  super.PreBeginPlay();
  SCTFGame.NormalScoreBoardClass = Level.Game.ScoreBoardType;
  Level.Game.ScoreBoardType = class'SmartCTFScoreBoard';
  //Level.Game.default.ScoreBoardType = class'SmartCTFScoreBoard';
  // The above line was fatal in version 4B :E

  Log( "Original Scoreboard determined as" @ SCTFGame.NormalScoreBoardClass, 'SmartCTF' );

  // Change F2 Server Info screen, compatible with UTPure
  if( bSmartCTFServerInfo )
  {
    class<ChallengeHUD>( Level.Game.HUDType ).default.ServerInfoClass = class'SmartCTFServerInfo';
    for( M = Level.Game.BaseMutator; M != None; M = M.NextMutator )
    {
      if( M.IsA( 'UTPure' ) ) // Let UTPure rehandle the scoreboard
      {
        M.PreBeginPlay();
        SCTFGame.bServerInfoSetServerSide = True; // No need for the old fashioned way - it can be set server side.
        Log( "Notified UTPure HUD to use SmartCTF ServerInfo.", 'SmartCTF' );
        break;
      }
    }
    if( SCTFGame.bServerInfoSetServerSide && Level.Game.HUDType.Name != 'PureCTFHUD' )
    {
      // In this scenario another mod intervered and we still have to do it the old fashion way.
      SCTFGame.bServerInfoSetServerSide = False;
      Log( "HUD is not the UTPure HUD but" @ Level.Game.HUDType.Name $ ", so SmartCTF ServerInfo will be set clientside.", 'SmartCTF' );
    }
    if( !SCTFGame.bServerInfoSetServerSide ) SCTFGame.DefaultHUDType = Level.Game.HUDType; // And in the old fashion way, the client will have to know the current HUD type.
  }
  else
  {
    SCTFGame.bServerInfoSetServerSide = True; // We didn't change anything, but neither do we want clientside intervention.
  }
}

/*
 * Startup and initialize.
 */
function PostBeginPlay()
{
  local FlagBase fb;
  local Actor A;
  local Actor IpToCountry;

  Level.Game.Spawn( class'SmartCTFSpawnNotifyPRI');

  SaveConfig(); // Create the .ini if its not already there.

  //Register as a message mutator, as we'll be using message monitoring
  //to perform some of our code. If not registered, then many message
  //events will not be passed to our mutator.
    Level.Game.RegisterMessageMutator( self );

  // Since we have problem replicating config variables...
  SCTFGame.bShowFCLocation = bShowFCLocation;
  SCTFGame.bPlay30SecSound = bPlay30SecSound;
  SCTFGame.bStatsDrawFaces = bStatsDrawFaces;
  SCTFGame.bDrawLogo = bDrawLogo;
  SCTFGame.bExtraStats = bExtraStats;
  SCTFGame.CountryFlagsPackage = CountryFlagsPackage;
  SCTFGame.bShowSpecs = bShowSpecs;
  SCTFGame.bDoKeybind = bDoKeybind;
  SCTFGame.SbDelayC = SbDelayC;
  
  if( !bRememberOvertimeSetting ) bOvertime = True;

  // Works serverside!
  if( bEnhancedMultiKill ) Level.Game.DeathMessageClass = class'SmartCTFEnhancedDeathMessagePlus';

  // Get the Flag bases
  ForEach AllActors( class'FlagBase', fb ) FlagStands[ fb.Team ] = fb;
  if( VSize( FlagStands[0].Location - FlagStands[1].Location ) < 1.5 * 900  ) bTooCloseForSaves = True;

  SCTFGame.EndStats = Spawn( class'SmartCTFEndStats', self );
  
  super.PostBeginPlay();

  if( Level.NetMode == NM_DedicatedServer ) SetTimer( 1.0 , True);
  
  MsgPID=-1; // First PID is 0, so it wouldn't get messaged if we kept MsgPID at it's default value.

  if(bStoreStats == True)
  {
  //Register as a damage mutator, as we'll be using damage checks to
  //update the stored information (new in v3.2).
	Level.Game.RegisterDamageMutator(self);
  
  //Grab some basic info about the player left message.
  QuitMsg=Level.Game.LeftMessage;
  QuitMsgLen=Len(QuitMsg);
  
  }
  Log( "SmartCTF" @ Version @ "loaded successfully.", 'SmartCTF' );
}

/*
 * Returns True or False whether to keep this SmartCTF mutator instance, and sets bInitialized accordingly.
 */
function bool ValidateSmartCTFMutator()
{
  local Mutator M;
  local bool bRunning;

  M = Level.Game.BaseMutator;
  while( M != None )
  {
    if( M != Self && M.Class == Self.Class )
    {
      bRunning = True;
      break;
    }
    M = M.NextMutator;
  }

  if( !bEnabled )
    Log( "Instance" @ Name @ "not loaded because bEnabled in .ini = False.", 'SmartCTF' );
  else if( CTFGame( Level.Game ) == None )
    Log( "Instance" @ Name @ "not loaded because gamestyle is not CTF.", 'SmartCTF' );
  else if( bRunning )
    Log( "Instance" @ Name @ "not loaded because it is already running.", 'SmartCTF' );
  else
    SCTFGame.bInitialized = True;

  return SCTFGame.bInitialized;
}

/*
 * For the flag bug each player gets a FlagChecker inventory on spawn.
 */
function ModifyPlayer( Pawn Other )
{
  local Inventory Inv;
  local SmartCTFPlayerReplicationInfo OtherStats;
  local	string	IP;
  local int j,i;

  if( bFixFlagBug && Other.bIsPlayer && !( Other.PlayerReplicationInfo.bIsSpectator && !Other.PlayerReplicationInfo.bWaitingPlayer ) )
  {
    Inv = Spawn( class'SmartCTFFlagCheckerInventory' , Other );
    if( Inv != None ) Inv.GiveTo( Other );
  }

   SCTFGame.RefreshPRI();
   OtherStats = SCTFGame.GetStats( Other );
      if(OtherStats!=none && bStoreStats && !Level.Game.bGameEnded && Other!=none && Other.bIsPlayer&& !Other.IsA('Spectator') && !Other.IsA('Bot')	&& Other.PlayerReplicationInfo!=none&& Other.PlayerReplicationInfo.PlayerName!="Player" )
	{
		IP=PlayerPawn(Other).GetPlayerNetworkAddress();
		j=InStr(IP,":");
		if( j!=-1 )
			IP=Left(IP,j);
		for(i=0; i<32 && GoneName[i]!=""; i++)
				{
					if( Other.PlayerReplicationInfo.PlayerName~=GoneName[i] || (IP==GoneIP[i] && IP!="") )
					{
						Log("  ## SmartCTF - Caught player by name or IP "$Other.PlayerReplicationInfo.PlayerName$"@"$IP);
						Log("  ## SmartCTF is restoring stats for " $Other.PlayerReplicationInfo.PlayerName$"@"$IP);
						if(GoneStats[i]!= none)
						{
						FirstSpawn( Other );
						OtherStats.Captures=GoneStats[i].Captures;
						OtherStats.Frags=GoneStats[i].Frags;
						OtherStats.Grabs=GoneStats[i].Grabs;
						OtherStats.Covers=GoneStats[i].Covers;
						OtherStats.Assists=GoneStats[i].Assists;
						OtherStats.Seals=GoneStats[i].Seals;
						OtherStats.FlagKills=GoneStats[i].FlagKills;
						OtherStats.DefKills=GoneStats[i].DefKills;
						OtherStats.HeadShots=GoneStats[i].HeadShots;
						OtherStats.ShieldBelts=GoneStats[i].ShieldBelts;
						OtherStats.Amps=GoneStats[i].Amps;
						OtherStats.LastKillTime=GoneStats[i].LastKillTime;
						OtherStats.MultiLevel=GoneStats[i].MultiLevel;
						OtherStats.FragSpree=GoneStats[i].FragSpree;
						OtherStats.CoverSpree=GoneStats[i].CoverSpree;
						OtherStats.SealSpree=GoneStats[i].SealSpree;
						OtherStats.SpawnKillSpree=GoneStats[i].SpawnKillSpree;
						OtherStats.bHadFirstSpawn =True;
						Other.PlayerReplicationInfo.Score=GoneScore[i];
						Other.PlayerReplicationInfo.Deaths=GoneDeaths[i];
						OtherStats.bHadFirstSpawn=False;
						CleanGone(i);
						Log("  ## Stats are restored");
						}
						break;
					}
				}
	}
   
     
  //If(OtherStats == none) return;                               proves fatal for StoreStats
  if( !OtherStats.bHadFirstSpawn )
  {
    OtherStats.bHadFirstSpawn = True;
    FirstSpawn( Other );
  }

  OtherStats.SpawnTime = Level.TimeSeconds;

  super.ModifyPlayer( Other );
  if(bStoreStats)	UpdateInfo();	
  
}

/*
 * Gets called when a new player or bot joins the game, that is when they first spawn.
 */
function FirstSpawn( Pawn Other )
{
  local byte ID;
  local string SkinName, FaceName;

  // Additional logging, useful for player tracking
  if( Level.Game.LocalLog != None && PlayerPawn( Other ) != None && Other.bIsPlayer )
  {
    ID = PlayerPawn( Other ).PlayerReplicationInfo.PlayerID;
    Level.Game.LocalLog.LogSpecialEvent( "IP", ID, PlayerPawn( Other ).GetPlayerNetworkAddress() );
    Level.Game.LocalLog.LogSpecialEvent( "player", "NetSpeed", ID, PlayerPawn( Other ).Player.CurrentNetSpeed );
    Level.Game.LocalLog.LogSpecialEvent( "player", "Fov", ID, PlayerPawn( Other ).FovAngle );
    Level.Game.LocalLog.LogSpecialEvent( "player", "VoiceType", ID, Other.VoiceType );
    if( Other.IsA( 'TournamentPlayer' ) )
    {
      if( Other.Skin == None )
      {
        Other.static.GetMultiSkin( Other, SkinName, FaceName );
      }
      else
      {
        SkinName = string( Other.Skin );
        FaceName = "None";
      }
      Level.Game.LocalLog.LogSpecialEvent( "player", "Skin", ID, SkinName );
      Level.Game.LocalLog.LogSpecialEvent( "player", "Face", ID, FaceName );
    }
  }
}

/*
*Use this function to clean out entries from the gone arrays when a player
*reenters and is caught by SmartCTF
*/
function CleanGone( int R)
{
 
 local	int		i;

	for(i=R;i<32;i++)
	{	If(GoneStats[i]!=none)
		{
			
			if(i==31)
			{
			GoneName[i]="";
			GoneScore[i]=0;
			GoneDeaths[i]=0;
			GoneIP[i]="";
			GoneStats[i].ClearStats();
			break;
			}

		GoneName[i]=GoneName[i+1];
		GoneScore[i]=GoneScore[i+1];
		GoneDeaths[i]=GoneDeaths[i+1];
		GoneIP[i]=GoneIP[i+1];
		GoneStats[i]=GoneStats[i+1];	
		}
	}
	

}

function bool MutatorBroadcastMessage( Actor Sender, Pawn Receiver, out coerce string Msg, optional bool bBeep, out optional name Type )
{
	local	string	quitter;
	local	int		i,j;
	local	bool	matched;

	if(bStoreStats)
	{
		//Thanks to the WebChatLog mutator for the Reciever.NextPawn==none check
		if(Receiver != none && Receiver.NextPawn == none && !Level.Game.bGameEnded)  // prevent duplicate messages
		{
			if(Right(Msg,QuitMsgLen)==QuitMsg)
			{
				quitter=left(Msg,Len(Msg)-QuitMsgLen);	//strips out the playername

				for(i=0; i<32 && StoreName[i]!=""; i++)
				{
					if(StoreName[i]~=quitter)
					{
						matched=true;	//found our player match

						for(j=0; j<32; j++)
						{
							if(GoneName[j]=="")
							{
								GoneName[j]=StoreName[i];
								GoneScore[j]=StoreScore[i];
								GoneDeaths[j]=StoreDeaths[i];
								GoneIP[j]=StoreIP[i];
								GoneStats[j]=StoreStats[i];
								break;
							}

							if(j==31)
							{
								log("  ## SmartCtf - Gone Array is full");
								break;
							}
						}

						break;
					}
				}

				//if the  player wasn't caught in the main store array, check backup 1
				if(!matched)
				{
					for(i=0; i<32 && B1Name[i]!=""; i++)
					{
						if(B1Name[i]~=quitter)
						{
							matched=true;	//found our player match

							for(j=0; j<32; j++)
							{
								if(GoneName[j]=="")
								{
									GoneName[j]=B1Name[i];
									GoneScore[j]=B1Score[i];
									GoneDeaths[j]=B1Deaths[i];
									GoneIP[j]=B1IP[i];
									GoneStats[j]=B1Stats[i];
									break;
								}

								if(j==31)
								{
									log("  ## SmartCtf - Gone Array is full");
									break;
								}
							}

							break;
						}
					}
				}

				//if the  player wasn't caught in the backup 1 array, check backup 2
				if(!matched)
				{
					for(i=0; i<32 && B2Name[i]!=""; i++)
					{
						if(B2Name[i]~=quitter)
						{
							for(j=0; j<32; j++)
							{
								if(GoneName[j]=="")
								{
									GoneName[j]=B2Name[i];
									GoneScore[j]=B2Score[i];
									GoneDeaths[j]=B2Deaths[i];
									GoneIP[j]=B2IP[i];
									GoneStats[j]=B2Stats[i];
									break;
								}

								if(j==31)
								{
									log("  ## SmartCtf - Gone Array is full");
									break;
								}
							}

							break;
						}
					}
				}
			}
		}
	}

	if( NextMessageMutator != none )
	{
		//If there are other mutators monitoring messages, make sure we ask them
		//whether to allow the message to be broadcast (i.e. return their value).
		return NextMessageMutator.MutatorBroadcastMessage( Sender, Receiver, Msg, bBeep, Type );
	}

	//Else, we'll return true (true will allow the message to be broadcast).
	return true;
} 

/*
*Just another event to use as an update point for our store array (the more
*update events, the more up to date the store array will be).
*/
function ScoreKill(pawn Killer, pawn Other)
{
	super.ScoreKill(Killer, Other);

	if(bStoreStats)	UpdateInfo();
	
}

/*
*Just another event to use as an update point for our store array (the more
*update events, the more up to date the store array will be).
*/
function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, out Vector Momentum, name DamageType)
{
	super.MutatorTakeDamage(ActualDamage,Victim,InstigatedBy,HitLocation,Momentum,DamageType);
	if(bStoreStats)	UpdateInfo();
	
}


function UpdateInfo()
{
	local	int		i,j,k;
	local	string	IP;
	local	Pawn	P;

	//clear the previous name values, so we don't double register any players
	for(k=0; k<32; k++)
	{
		StoreName[k]="";
	}

	for(P=Level.PawnList; P!=none; P=P.nextPawn)
	{
		if( PlayerPawn(P)!=none && P.bIsPlayer && !P.IsA('Spectator') && !P.IsA('Bot')&& P.PlayerReplicationInfo!=none && P.PlayerReplicationInfo.PlayerName!="Player"&& (P.PlayerReplicationInfo.Score!=0 || P.PlayerReplicationInfo.Deaths!=0) )
		{
			IP=PlayerPawn(P).GetPlayerNetworkAddress();
			if( IP!="" )
			{
				j=InStr(IP,":");
				if( j!=-1 )
					IP=Left(IP,j);
			}
			StoreName[i]=P.PlayerReplicationInfo.PlayerName;
			StoreScore[i]=P.PlayerReplicationInfo.Score;
			StoreDeaths[i]=P.PlayerReplicationInfo.Deaths;
			StoreIP[i]=IP;
			if (SCTFGame.GetStats( P ) != none)
			StoreStats[i] = SCTFGame.GetStats( P );
			i++;
		}
	}

} 

/*
 * Gets called once when the Countdown before a Tournament game starts.
 */
function TournamentGameStarted()
{
  // Fix warmup mode bug + Overtime functionality
  ClearStats();
  if( bEnableOvertimeControl )
  {
    if( !bOvertime ) BroadcastLocalizedMessage( class'SmartCTFCoolMsg', 4 );
    else BroadcastLocalizedMessage( class'SmartCTFCoolMsg', 3 );
  }
}

/*
 * Check for covers and seals, and adjust scores.
 */
function bool PreventDeath( Pawn Victim, Pawn Killer, name DamageType, vector HitLocation )
{
  local PlayerReplicationInfo VictimPRI, KillerPRI;
  local bool bPrevent, bVictimTeamHasFlag, bWarmupSkip;
  local Pawn pn;
  local float TimeAwake;
  local SmartCTFPlayerReplicationInfo KillerStats, VictimStats;

  bPrevent = super.PreventDeath( Victim, Killer, DamageType, HitLocation );
  if( bPrevent ) return bPrevent; // Player didn't die, so return.

  // If there is no victim, return.
  if( Victim == None ) return bPrevent;
  VictimPRI = Victim.PlayerReplicationInfo;
  if( VictimPRI == None || !Victim.bIsPlayer || ( VictimPRI.bIsSpectator && !VictimPRI.bWaitingPlayer ) ) return bPrevent;
  VictimStats = SCTFGame.GetStats( Victim );

  if( VictimStats != None )
  {
    VictimStats.FragSpree = 0; // Reset FragSpree for Victim
    VictimStats.SpawnKillSpree = 0;
  }
  // If there is no killer / suicide, return.
  if( Killer == None || Killer == Victim )
  {
    if( bEnhancedMultiKill && EnhancedMultiKillBroadcast > 0 ) VictimStats.MultiLevel = 0;
    return bPrevent;
  }
  KillerPRI = Killer.PlayerReplicationInfo;
  if( KillerPRI == None || !Killer.bIsPlayer || ( KillerPRI.bIsSpectator && !KillerPRI.bWaitingPlayer ) ) return bPrevent;
  KillerStats = SCTFGame.GetStats( Killer );
  // Same Team! We don't count those stats like that in SmartCTF.
  if( VictimPRI.Team == KillerPRI.Team ) return bPrevent;

  // Increase Frags and FragSpree for Killer (Play "Too Easy" at 30)
  if( KillerStats != None )
  {
    KillerStats.Frags++;
    KillerStats.FragSpree++;
  }
  if( bEnhancedMultiKill && EnhancedMultiKillBroadcast > 0 )
  {
    VictimStats.MultiLevel = 0;
    if( Level.TimeSeconds - KillerStats.LastKillTime < 3 )
    {
      KillerStats.MultiLevel++;
      if( KillerStats.MultiLevel + 1 >= EnhancedMultiKillBroadcast ) Level.Game.BroadcastMessage( KillerPRI.PlayerName @ class'SmartCTFEnhancedMultiKillMessage'.static.GetBroadcastString( KillerStats.MultiLevel ) );
    }
    else
    {
      KillerStats.MultiLevel = 0;
    }
    KillerStats.LastKillTime = Level.TimeSeconds;
  }
  bWarmupSkip = DeathMatchPlus( Level.Game ).bTournament && !bTournamentGameStarted;

  if( !bWarmupSkip )
  {

    // For Flag Kill, inc player's FlagKills and total
    if( VictimPRI.HasFlag != None )
    {
      if( KillerStats != None ) KillerStats.FlagKills++;
      KillerPRI.Score += FlagKillBonus;
      // Already logged by UTStats serveractor. Dont want to do it twice.
      //if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_kill", KillerPRI.PlayerID, VictimPRI.PlayerID, VictimPRI.Team );
    } // If Killer has Flag, no cover or seal for him
    else if( KillerPRI.HasFlag == None && FCs[KillerPRI.Team] != None && FCs[KillerPRI.Team].PlayerReplicationInfo.HasFlag != None )
    {
      // COVER FRAG  / SEAL BASE
      // If Killer's Team has had an FC

      // If the FC has Flag Right now
      // Defend kill
      // org: If victim can see the FC or is within 600 unreal units (approx 40 feet) and has a line of sight to fc.
      //if( Victim.canSee( FCs[KillerPRI.Team] ) || ( Victim.lineOfSightTo( FCs[KillerPRI.Team] ) && Distance( Victim.Location, FCs[KillerPRI.Team].Location ) < 600 ) )
      // new: victim within 512 uu of FC
      //      or killer within 512 uu of FC
      //      or victim can see FC and was Victim within 1536 uu of FC
      //      or killer can see FC and Victim victim within 1024 uu of FC
      //      or victim has direct line to FC and was Victim within 768 uu
      if( ( VSize( Victim.Location - FCs[KillerPRI.Team].Location ) < 512 )
       || ( VSize( Killer.Location - FCs[KillerPRI.Team].Location ) < 512 )
       || ( VSize( Victim.Location - FCs[KillerPRI.Team].Location ) < 1536 && Victim.canSee( FCs[KillerPRI.Team] ) )
       || ( VSize( Victim.Location - FCs[KillerPRI.Team].Location ) < 1024 && Killer.canSee( FCs[KillerPRI.Team] ) )
       || ( VSize( Victim.Location - FCs[KillerPRI.Team].Location ) < 768  && Victim.lineOfSightTo( FCs[KillerPRI.Team] ) ) )
      {
        // Killer DEFENDED THE Flag CARRIER
        if( KillerStats != None )
        {
          KillerStats.Covers++;
          KillerStats.CoverSpree++;    // Increment Cover spree
        }
        KillerPRI.Score += CoverBonus;       // Reward points

        // Log cover
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_cover", KillerPRI.PlayerID, VictimPRI.PlayerID, KillerPRI.Team );

        // Cover sprees
        if( KillerStats != None )
        {
          if( KillerStats.CoverSpree == 3 )  // Cover x 3
          {
            if( CoverSpreeMsgType == 1 && PlayerPawn( Killer ) != None ) Killer.ClientMessage( class'SmartCTFMessage'.static.GetString( 4 + 64, KillerPRI, VictimPRI ) );
            else if( CoverSpreeMsgType == 2 ) BroadcastMessage( class'SmartCTFMessage'.static.GetString( 4, KillerPRI, VictimPRI ) );
            else if( CoverSpreeMsgType == 3 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 4, KillerPRI, VictimPRI );
          }
          else if( KillerStats.CoverSpree == 4 ) // Cover x 4
          {
            if( CoverSpreeMsgType == 1 && PlayerPawn( Killer ) != None ) Killer.ClientMessage( class'SmartCTFMessage'.static.GetString( 5 + 64, KillerPRI, VictimPRI ) );
            else if( CoverSpreeMsgType == 2 ) BroadcastMessage( class'SmartCTFMessage'.static.GetString( 5, KillerPRI, VictimPRI ) );
            else if( CoverSpreeMsgType == 3 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 5, KillerPRI, VictimPRI );
          }
          else //  // Covered FC
          {
            if( CoverMsgType == 1 && PlayerPawn( Killer ) != None ) Killer.ClientMessage( class'SmartCTFMessage'.static.GetString( 0 + 64, KillerPRI, VictimPRI ) );
            else if( CoverMsgType == 2 ) BroadcastMessage( class'SmartCTFMessage'.static.GetString( 0, KillerPRI, VictimPRI ) );
            else if( CoverMsgType == 3 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 0, KillerPRI, VictimPRI );
          }
        }
      }

        // Defense kill
        // If the map has player zones
        bVictimTeamHasFlag = True;
        if( FCs[VictimPRI.Team] == None ) bVictimTeamHasFlag = False;
        if( FCs[VictimPRI.Team] != None && FCs[VictimPRI.Team].PlayerReplicationInfo.HasFlag == None ) bVictimTeamHasFlag = False;
        // If Victim's FC has not been set / If Victim's FC doesn't have our Flag
        if( !bVictimTeamHasFlag )
        {
          // If Killer is Red & he and his FC's Location has Red
          if( IsInZone( VictimPRI, KillerPRI.Team ) && IsInZone( FCs[KillerPRI.Team].PlayerReplicationInfo, KillerPRI.Team ) )
          {
            // Killer SEALED THE BASE
            if( KillerStats != None )
            {
              KillerStats.Seals++;
              KillerStats.SealSpree++;
              if(CTFReplicationInfo( Level.Game.GameReplicationInfo ).FlagList[KillerPRI.Team].bHome) // only if flag is at home
                 KillerStats.DefKills++; // seal is also a defkill
            }
            KillerPRI.Score += SealBonus;
            if( SealMsgType != 0 && KillerStats != None && KillerStats.SealSpree == 2 ) // Sealing base
            {
              if( SealMsgType == 1 && PlayerPawn( Killer ) != None ) Killer.ClientMessage( class'SmartCTFMessage'.static.GetString( 1 + 64, KillerPRI, VictimPRI ) );
              else if( SealMsgType == 2 ) BroadcastMessage( class'SmartCTFMessage'.static.GetString( 1, KillerPRI, VictimPRI ) );
              else if( SealMsgType == 3 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 1, KillerPRI, VictimPRI );
            }
            // Log seal
            if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_seal", KillerPRI.PlayerID, VictimPRI.PlayerID, KillerPRI.Team ); // Log to ngLog;
          }
        }
      }
    else // our team don't have a flag
    {
        bVictimTeamHasFlag = True;
        if( FCs[VictimPRI.Team] == None ) bVictimTeamHasFlag = False;
        if( FCs[VictimPRI.Team] != None && FCs[VictimPRI.Team].PlayerReplicationInfo.HasFlag == None ) bVictimTeamHasFlag = False;
        // Defense kill
        // If the map has player zones
        if( VictimPRI.PlayerZone != None )
        {
           if( IsInZone( VictimPRI, KillerPRI.Team ) && !bVictimTeamHasFlag && CTFReplicationInfo( Level.Game.GameReplicationInfo ).FlagList[KillerPRI.Team].bHome)
           {
              if( KillerStats != None )
              {
                KillerStats.DefKills++;
              }
            }
        }
    }
    }
  if( bAfterGodLikeMsg && KillerStats != None && ( KillerStats.FragSpree == 30 || KillerStats.FragSpree == 35 ) )
  {
    for( pn = Level.PawnList; pn != None; pn = pn.NextPawn )
    {
      if( pn.IsA( 'TournamentPlayer' ) )
        pn.ReceiveLocalizedMessage( class'SmartCTFSpreeMsg', KillerStats.FragSpree / 5 - 1, KillerPRI );
    }
  }

  // Uber / Long Range kill if not sniper, HeadShot, trans, deemer, instarifle, or vengeance relic.
  if( bShowLongRangeMsg && TournamentPlayer( Killer ) != None )
  {
    if( DamageType != 'shot' && DamageType != 'decapitated' && DamageType != 'Gibbed' && DamageType != 'RedeemerDeath' && SuperShockRifle( Killer.Weapon ) == None && DamageType != 'Eradicated' )
    {
      if( VSize( Killer.Location - Victim.Location ) > 1536 )
      {
        if( VSize( Killer.Location - Victim.Location ) > 3072 )
        {
          Killer.ReceiveLocalizedMessage( class'SmartCTFCoolMsg', 2, KillerPRI, VictimPRI );
        }
        else
        {
          Killer.ReceiveLocalizedMessage( class'SmartCTFCoolMsg', 1, KillerPRI, VictimPRI );
        }
        // Log special kill.
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "longrangekill", KillerPRI.PlayerID, VictimPRI.PlayerID );
      }
    }
  }

  // HeadShot tracking
  if( DamageType == 'decapitated' && KillerStats != None ) KillerStats.HeadShots++;

  // Spawnkill detection
  if( bSpawnkillDetection && DamageType != 'Gibbed' && VictimStats != None ) // No telefrags
  {
    TimeAwake = Level.TimeSeconds - VictimStats.SpawnTime;
    if( Level.Game.BaseMutator.MutatedDefaultWeapon() != class'Botpack.ImpactHammer' )
    { // Arena mutator used, spawnkilling must be extreme to count
      if( TimeAwake <= SpawnKillTimeArena )
      {
        Killer.ReceiveLocalizedMessage( class'SmartCTFCoolMsg', 5, KillerPRI, VictimPRI );
        KillerPRI.Score -= SpawnKillPenalty;
        if( KillerStats != None ) KillerStats.SpawnKillSpree++;
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "spawnkill", KillerPRI.PlayerID, VictimPRI.PlayerID, SpawnKillPenalty );
        if( bShowSpawnKillerGlobalMsg && KillerStats != None && KillerStats.SpawnKillSpree > 2 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 10, KillerPRI, VictimPRI );
      }
    }
    else // No arena mutator
    {
      if( TimeAwake < SpawnKillTimeNW )
      {
        Killer.ReceiveLocalizedMessage( class'SmartCTFCoolMsg', 5, KillerPRI, VictimPRI );
        KillerPRI.Score -= SpawnKillPenalty;
        if( KillerStats != None ) KillerStats.SpawnKillSpree++;
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "spawnkill", KillerPRI.PlayerID, VictimPRI.PlayerID, SpawnKillPenalty );
        if( bShowSpawnKillerGlobalMsg && KillerStats != None && KillerStats.SpawnKillSpree > 2 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 10, KillerPRI, VictimPRI );
      }
    }
  }
  if(bStoreStats)UpdateInfo();
  return bPrevent;
}

/*
 * ShieldBelt + Damage Amp tracking, spawnkill detection.
 */
function bool HandlePickupQuery( Pawn Other, Inventory Item, out byte bAllowPickup )
{
  local SmartCTFPlayerReplicationInfo OtherStats;

  OtherStats = SCTFGame.GetStats( Other );

  if( Item.IsA( 'UT_ShieldBelt' ) && OtherStats != None ) OtherStats.ShieldBelts++;
  if( Item.IsA( 'UDamage' ) && OtherStats != None ) OtherStats.Amps++;

  // For spawnkill detection
  if( bSpawnkillDetection && OtherStats != None && OtherStats.SpawnTime != 0 )
  {
    if( Item.IsA( 'TournamentWeapon' ) || Item.IsA( 'UT_ShieldBelt' ) || Item.IsA( 'UDamage' ) || Item.IsA( 'HealthPack' ) || Item.IsA( 'UT_Invisibility' ) )
    {
      // This player has picked up a certain item making a kill on him no longer be qualified as a spawnkill.
      OtherStats.SpawnTime = 0;
    }
  }

  return super.HandlePickupQuery( Other, Item, bAllowPickup );
}

/*
 * Proper check if a player is in a location with 'red' or 'blue' in the name.
 */
function bool IsInZone( PlayerReplicationInfo PRI, byte Team )
{
  local string Loc;

  if( PRI.PlayerLocation != None ) Loc = PRI.PlayerLocation.LocationName;
  else if( PRI.PlayerZone != None ) Loc = PRI.PlayerZone.ZoneName;
  else return False;

  if( Team == 0 ) return ( Instr( Caps( Loc ), "RED" ) != -1 );
  else return ( Instr( Caps( Loc ), "BLUE" ) != -1 );
}

/*
 * Add a player to the Red FC/assister list.
 */
function AddRedFlagCarrier( Pawn Aster, float Fct )
{
  local byte i;

  if( Aster == None || !Aster.bIsPlayer || ( Aster.PlayerReplicationInfo.bIsSpectator && !Aster.PlayerReplicationInfo.bWaitingPlayer ) ) return;
  if( RedFCIndex >= 32 ) RedFCIndex = 0;

  // Check if already in list
  for( i = 0; i < 32; i++ )
  {
    if( Aster == RedFlagCarrier[i] )
    {
      RedFlagCarrierTime[i] += Fct;
      return;
    }
  }

  RedFlagCarrier[RedFCIndex] = Aster;
  RedFlagCarrierTime[RedFCIndex] = Fct;
  RedFCIndex++;
}

function AddBlueFlagCarrier( Pawn Aster, float Fct )
{
  local byte i;

  if( Aster == None || !Aster.bIsPlayer || ( Aster.PlayerReplicationInfo.bIsSpectator && !Aster.PlayerReplicationInfo.bWaitingPlayer ) ) return;
  if( BlueFCIndex >= 32 ) BlueFCIndex = 0;

  for( i = 0; i < 32; i++ )
  {
    if( Aster == BlueFlagCarrier[i] )
    {
      BlueFlagCarrierTime[i] += Fct;
      return;
    }
  }

  BlueFlagCarrier[BlueFCIndex] = Aster;
  BlueFlagCarrierTime[BlueFCIndex] = Fct;
  BlueFCIndex++;
}


/*
 * Walk through Red assisters/FC and reward them with points because of a cap.
 */
function RewardRedFlagCarriers( bool bNotPlayedLead )
{
  local byte j;
  local SmartCTFPlayerReplicationInfo AssisterStats;
  local int Bonus;
  local float TotalTime, f;

  Bonus = AssistBonus;

  // Calculate the total flag carrying time
  for( j = 0; j < 32; j++ ) TotalTime += RedFlagCarrierTime[j];

  for( j = 0; j < 32; j++ )
  {
    // If flagcarrier was not the capper
    if( RedFlagCarrier[j] != None && RedFlagCarrier[j] != FCs[0] )
    {
      AssisterStats = SCTFGame.GetStats( RedFlagCarrier[j] );
      if( AssisterStats != None ) AssisterStats.Assists++;

      if( bNewCapAssistScoring )
      {
        if( TotalTime == 0 ) f = 0;
        else f = ( RedFlagCarrierTime[j] / TotalTime ) * ( 7 + CapBonus ); // proportionally score
        Bonus = Max( f, 1 );
      }
      RedFlagCarrier[j].PlayerReplicationInfo.Score += Bonus;

      if( PlayerPawn( RedFlagCarrier[j] ) != None )
      {
        if( bShowAssistConsoleMsg ) PlayerPawn( RedFlagCarrier[j] ).ClientMessage( "You get " $ Bonus $ " bonus pts for the Assist!" @ CarriedString( RedFlagCarrierTime[j], TotalTime ) );
        if( bPlayAssistSound && bNotPlayedLead ) PlayerPawn( RedFlagCarrier[j] ).ReceiveLocalizedMessage( class'SmartCTFAudioMsg', 1 );
      }
      if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "Flag_assist", RedFlagCarrier[j].PlayerReplicationInfo.PlayerID, 0 );
    }
    // Award capper propertionally too. Behave like assist
    else if( RedFlagCarrier[j] == FCs[0] )
    {
      if( bNewCapAssistScoring )
      {
        if( TotalTime == 0 ) f = 0;
        else f = ( RedFlagCarrierTime[j] / TotalTime ) * ( 7 + CapBonus );
        Bonus = Max( f, MinimalCapBonus );
        FCs[0].PlayerReplicationInfo.Score += Bonus - 7; // 7 already awarded by UT
        if( bShowAssistConsoleMsg && PlayerPawn( FCs[0] ) != None ) PlayerPawn( FCs[0] ).ClientMessage( "You get " $ Bonus $ " pts for the Capture!" @ CarriedString( RedFlagCarrierTime[j], TotalTime ) );
      }
      else FCs[0].PlayerReplicationInfo.Score += CapBonus;
    }
  }
  ResetFlagCarriers( 0 );
}

function RewardBlueFlagCarriers( bool bNotPlayedLead )
{
  local byte j;
  local SmartCTFPlayerReplicationInfo AssisterStats;
  local int Bonus;
  local float TotalTime, f;

  Bonus = AssistBonus;

  for( j = 0; j < 32; j++ ) TotalTime += BlueFlagCarrierTime[j];

  for( j = 0; j < 32; j++ )
  {
    if( BlueFlagCarrier[j] != None && BlueFlagCarrier[j] != FCs[1] )
    {
      AssisterStats = SCTFGame.GetStats( BlueFlagCarrier[j] );
      if( AssisterStats != None ) AssisterStats.Assists++;

      if( bNewCapAssistScoring )
      {
        if( TotalTime == 0 ) f = 0;
        else f = ( BlueFlagCarrierTime[j] / TotalTime ) * ( 7 + CapBonus );
        Bonus = Max( f, 1 );
      }
      BlueFlagCarrier[j].PlayerReplicationInfo.Score += Bonus;

      if( PlayerPawn( BlueFlagCarrier[j] ) != None )
      {
        if( bShowAssistConsoleMsg ) PlayerPawn( BlueFlagCarrier[j] ).ClientMessage( "You get " $ Bonus $ " bonus pts for the Assist!" @ CarriedString( BlueFlagCarrierTime[j], TotalTime ) );
        if( bPlayAssistSound && bNotPlayedLead ) PlayerPawn( BlueFlagCarrier[j] ).ReceiveLocalizedMessage( class'SmartCTFAudioMsg', 1 );
      }
      if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "Flag_assist", BlueFlagCarrier[j].PlayerReplicationInfo.PlayerID, 0 );
    }
    else if( BlueFlagCarrier[j] == FCs[1] )
    {
      if( bNewCapAssistScoring )
      {
        if( TotalTime == 0 ) f = 0;
        else f = ( BlueFlagCarrierTime[j] / TotalTime ) * ( 7 + CapBonus );
        Bonus = Max( f, MinimalCapBonus );
        FCs[1].PlayerReplicationInfo.Score += Bonus - 7;
        if( bShowAssistConsoleMsg && PlayerPawn( FCs[1] ) != None ) PlayerPawn( FCs[1] ).ClientMessage( "You get " $ Bonus $ " pts for the Capture!" @ CarriedString( BlueFlagCarrierTime[j], TotalTime ) );
      }
      else FCs[1].PlayerReplicationInfo.Score += CapBonus;
    }
  }
  ResetFlagCarriers( 1 );
}

/*
 * Clear assisters list of Team, because of flag return. Team = 2: clear both teams.
 */
function ResetFlagCarriers( byte Team )
{
  local byte i;

  if( Team != 1 )
  {
    RedFCIndex = 0;
    for( i = 0; i < 32; i++ )
    {
      RedFlagCarrier[i] = None;
      RedFlagCarrierTime[i] = 0;
    }
  }
  if( Team != 0 )
  {
    BlueFCIndex = 0;
    for( i = 0; i < 32; i++ )
    {
      BlueFlagCarrier[i] = None;
      BlueFlagCarrierTime[i] = 0;
    }
  }
}

function string CarriedString( float Time, float TotalTime )
{
  local int Perc;
  local float f;

  //if( !bNewCapAssistScoring ) return "";

  if( TotalTime == 0 ) f = 0;
  else f = ( Time / TotalTime ) * 100;
  Perc = Clamp( f, 0, 100 );
  if( Perc == 100 ) return "(Solocap," @ int( Time ) @ "sec.)";
  else return "(Carried" @ Perc $ "% of the time:" @ int( Time ) @ "sec.)";
}

/*
 * Intercept CTF messages to set FC states and adjust scores.
 */
function bool MutatorBroadcastLocalizedMessage( Actor Sender, Pawn Receiver, out class<LocalMessage> Message, out optional int Switch, out optional PlayerReplicationInfo RelatedPRI_1, out optional PlayerReplicationInfo RelatedPRI_2, out optional Object OptionalObject )
{
  local CTFFlag Flag;
  local byte i, LeadSound;
  local Pawn pn, FirstPawn;
  local SmartCTFPlayerReplicationInfo ReceiverStats;

  // This function gets called each time someone receives a message. Thus for a broadcast, we need to make sure code only
  // gets executed once. We can do that by comparing Receiver with f.e. the FC if applicable, or with the first Pawn
  // in the PawnList (FirstPawn, see below).

  if( Message == class'CTFMessage' )
  {
    if( Sender.IsA( 'CTFGame' ) ) Flag = CTFFlag( OptionalObject );
    else if( Sender.IsA( 'CTFFlag' ) ) Flag = CTFFlag( Sender );
    else return super.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
    if( Flag == None ) return super.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

    // Warmup
    if( DeathMatchPlus( Level.Game ).bTournament && !bTournamentGameStarted ) return super.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

    switch( Switch )
    {
      // CAPTURE
      // Sender: CTFGame, PRI: Scorer.PlayerReplicationInfo, OptObj: TheFlag
      case 0:
        if( Receiver == Pawn( RelatedPRI_1.Owner ) )
        {
          //Flag = CTFFlag( OptionalObject );
          i = 1 - Flag.Team;
          if( i == 1 ) AddBlueFlagCarrier( FCs[i], Level.TimeSeconds - PickupTime[i] );
          else AddRedFlagCarrier( FCs[i], Level.TimeSeconds - PickupTime[i] );

          // Increment Caps for the player and the total
          ReceiverStats = SCTFGame.GetStats( FCs[i] );
          if( ReceiverStats != None ) ReceiverStats.Captures++;

          if( bPlayLeadSound )
          {
            if( ( CTFGame( Level.Game ).Teams[i].Score - 1 ) == CTFGame( Level.Game ).Teams[1 - i].Score ) LeadSound = 1;
            if( CTFGame( Level.Game ).Teams[i].Score == CTFGame( Level.Game ).Teams[1 - i].Score ) LeadSound = 2;

            for( pn = Level.PawnList; pn != None; pn = pn.NextPawn )
            {
              if( PlayerPawn( pn ) != None && pn.bIsPlayer )
              {
                if( LeadSound == 1 && pn.PlayerReplicationInfo.Team == i ) PlayerPawn( pn ).ReceiveLocalizedMessage( class'SmartCTFAudioMsg', 3 );
                else if( LeadSound == 2 && pn.PlayerReplicationInfo.Team == ( 1 - i ) ) PlayerPawn( pn ).ReceiveLocalizedMessage( class'SmartCTFAudioMsg', 4 );
              }
            }
          }

          // Don't play Capture sound if "Got The Lead" sound has played
          if( bPlayCaptureSound && PlayerPawn( FCs[i] ) != None )
          {
            if( !( bPlayLeadSound && ( LeadSound == 1 ) ) ) PlayerPawn( FCs[i] ).ReceiveLocalizedMessage( class'SmartCTFAudioMsg', 0 );
          }

          // Reward points To FC and Assisters and increment Assists count and total
          if( Flag.Team == 0 ) RewardBlueFlagCarriers( !( bPlayLeadSound && ( LeadSound == 1 ) ) );
          else RewardRedFlagCarriers( !( bPlayLeadSound && ( LeadSound == 1 ) ) );
          ResetFlagCarriers( 2 );
          GiveCoverSealBonus( Flag.Team ); // Reward pts to Covers And Sealers

          // Reset FCs And Assister num n index And reset sprees
          FCs[0] = None;
          FCs[1] = None;
          ResetSprees( 2 ); // Means reset all since no Team is equal to 2.
        }
        break;

      // DROP
      // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: CTFGame(Level.Game).Teams[Team]
      case 2:
        if( Receiver == Pawn( RelatedPRI_1.Owner ) )
        {
          i = 1 - Flag.Team;
          if( i == 1 ) AddBlueFlagCarrier( FCs[i], Level.TimeSeconds - PickupTime[i] );
          else AddRedFlagCarrier( FCs[i], Level.TimeSeconds - PickupTime[i] );
        }
        break;

      // PICKUP (after the FC dropped it)
      // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: CTFGame(Level.Game).Teams[Team]
      case 4:
        if( Receiver == Flag.Holder )
        {
          i = 1 - Flag.Team;
          PickupTime[i] = Level.TimeSeconds;
          FCs[i] = Flag.Holder;
        }
        break;

      // GRAB
      // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: CTFGame(Level.Game).Teams[Team]
      case 6:
        if( Receiver == Flag.Holder )
        {
          i = 1 - Flag.Team;
          PickupTime[i] = Level.TimeSeconds;
          FCs[i] = Flag.Holder; // Set the FC
          RelatedPRI_1.Score += GrabBonus;
          // Increment FC's Grabs and total Grabs
          ReceiverStats = SCTFGame.GetStats( FCs[i] );
          if( ReceiverStats != None ) ReceiverStats.Grabs++;
        }
        break;


      // RETURN
      case 1:
      case 3:
      case 5:
        // Get a pawn that receives messages, thus triggers this function ( as Receiver )
        for( FirstPawn = Level.PawnList; FirstPawn != None; FirstPawn = FirstPawn.NextPawn )
        {
          if( FirstPawn.bIsPlayer || FirstPawn.IsA( 'MessagingSpectator' ) ) break;
        }

        if( Receiver == FirstPawn ) // Just get the first one.
        {
          // Switch == 1: it's returned by player, sent by CTFGame.
          //   Sender: CTFGame, PRI: Scorer.PlayerReplicationInfo, ObtObj: TheFlag
          if( Switch == 1 )
          {
            // 8 pts for a close save (with msg), Half a pt for base returns, 2 pts for Mid, 4 pts for enemy base
            if( !bTooCloseForSaves && VSize( Flag.Location - FlagStands[1 - Flag.Team].Location ) < 900 )
            { // CLOSE SAVE
              RelatedPRI_1.Score += CloseSaveReturnBonus;
              if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_return_closesave", RelatedPRI_1.PlayerID, Flag.Team );

              // Only a msg if not a Flag standoff - other flag is home
              if( CTFReplicationInfo( Level.Game.GameReplicationInfo ).FlagList[1 - Flag.Team].bHome )
              {
                if( SavedMsgType == 1 && PlayerPawn( RelatedPRI_1.Owner ) != None ) PlayerPawn( RelatedPRI_1.Owner ).ClientMessage( class'SmartCTFMessage'.static.GetString( 7 + 64, RelatedPRI_1 ) );
                else if( SavedMsgType == 2 ) BroadcastMessage( class'SmartCTFMessage'.static.GetString( 7, RelatedPRI_1 ) );
                else if( SavedMsgType == 3 ) BroadcastLocalizedMessage( class'SmartCTFMessage', 7, RelatedPRI_1 );
                if( bPlaySavedSound && PlayerPawn( RelatedPRI_1.Owner ) != None ) PlayerPawn( RelatedPRI_1.Owner ).ReceiveLocalizedMessage( class'SmartCTFAudioMsg', 2 );
              }
            }
            else if( IsInZone( RelatedPRI_1, 1 - Flag.Team ) )
            {
              RelatedPRI_1.Score += EnemyBaseReturnBonus; // If in enemy base
              if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_return_enemybase", RelatedPRI_1.PlayerID, Flag.Team );
            }
            else if( !IsInZone( RelatedPRI_1, Flag.Team ) ) // Not in enemy base and not on own side = mid
            {
              RelatedPRI_1.Score += MidReturnBonus; // If in Mid
              if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_return_mid", RelatedPRI_1.PlayerID, Flag.Team );
            }
            else
            {
              RelatedPRI_1.Score += BaseReturnBonus;
              if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "flag_return_base", RelatedPRI_1.PlayerID, Flag.Team );
            }

          } // end if switch == 1

          ResetSprees( Flag.Team ); // Reset cover sprees and seal sprees of Other Team
          ResetFlagCarriers( 1 - Flag.Team ); // Reset assist list
        }

        break;
    } // end switch
  if(bStoreStats)	UpdateInfo();
  } // end if msg is CTF msg.
   
  return super.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}

/*
 * Gives all players of Team that covered their FC extra bonus points after the cap.
 */
function GiveCoverSealBonus( int Team )
{
  local PlayerReplicationInfo pnPRI;
  local byte i;
  local SmartCTFPlayerReplicationInfo PawnStats;
  local Pawn pn;

  SCTFGame.RefreshPRI();
  for( i = 0; i < 64; i++ )
  {
    PawnStats = SCTFGame.GetStatNr( i );
    if( PawnStats == None ) break;
    pnPRI = PlayerReplicationInfo( PawnStats.Owner );
    pn = Pawn( pnPRI.Owner );

    if( pnPRI.Team != Team )
    {
      if( PawnStats != None && PawnStats.SealSpree > 0 )
      {
        pnPRI.Score += PawnStats.SealSpree * SealBonus;
        if( bShowSealRewardConsoleMsg && PlayerPawn( pn ) != None ) PlayerPawn( pn ).ClientMessage("You killed " $ PawnStats.SealSpree $ " people sealing off the base. You get " $ PawnStats.SealSpree * SealBonus $ " bonus pts!" );
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "seal_bonus", pnPRI.PlayerID, PawnStats.SealSpree, PawnStats.SealSpree * SealBonus );
      }
      if( PawnStats != None && PawnStats.CoverSpree > 0 )
      {
        pnPRI.Score += PawnStats.CoverSpree * CoverBonus;
        if( bShowCoverRewardConsoleMsg && PlayerPawn( pn ) != None ) PlayerPawn( pn ).ClientMessage("You killed " $ PawnStats.CoverSpree $ " people covering your FC. You get " $ PawnStats.CoverSpree * CoverBonus $ " bonus pts!" );
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "cover_bonus", pnPRI.PlayerID, PawnStats.CoverSpree, PawnStats.CoverSpree * CoverBonus );
      }
    }
  }
  if(bStoreStats)UpdateInfo();
}

/*
 * Reset cover and seal sprees of Team cause of flag return.
 */
function ResetSprees( int Team )
{
  local byte i;
  local SmartCTFPlayerReplicationInfo PawnStats;

  SCTFGame.RefreshPRI();
  for( i = 0; i < 64; i++ )
  {
    PawnStats = SCTFGame.GetStatNr( i );
    if( PawnStats == None ) break;
    if( PlayerReplicationInfo( PawnStats.Owner ).Team != Team )
    {
      PawnStats.CoverSpree = 0;
      PawnStats.SealSpree = 0;
    }
  }
}

/*
 * Clear stats.
 */
function ClearStats()
{
  SCTFGame.ClearStats();
  ResetFlagCarriers( 2 );
  FCs[0] = None;
  FCs[1] = None;
}

/*
 * Give info on 'mutate smartctf' commands.
 */
function Mutate( string MutateString, PlayerPawn Sender )
{
  local int ID;
  local string SoundsString, MsgsString, CMsgsString;
  local SmartCTFPlayerReplicationInfo SenderStats;

  if( Left( MutateString, 8 ) ~= "SmartCTF" )
  {
    ID = Sender.PlayerReplicationInfo.PlayerID;

    if( Mid( MutateString, 9, 9 ) ~= "ShowStats" || Mid( MutateString, 9, 5 ) ~= "Stats" )
    {
      SenderStats = SCTFGame.GetStats( Sender );
      if( SenderStats != None ) SenderStats.ToggleStats();
    }
    else if( Mid( MutateString, 9, 10 ) ~= "ForceStats" )
    {
      SenderStats = SCTFGame.GetStats( Sender );
      if( SenderStats != None ) SenderStats.ShowStats();
    }
    else if( Mid( MutateString, 9, 5 ) ~= "Rules" || Mid( MutateString, 9, 6 ) ~= "Points" || Mid( MutateString, 9, 5 ) ~= "Score" || Mid( MutateString, 9, 5 ) ~= "Bonus" )
    {
      if( bNewCapAssistScoring ) Sender.ClientMessage( "SmartCTF Score Settings: - Cap/Assist:" @ 7 + CapBonus @ "pts divided over all FC's by time" );
      else Sender.ClientMessage( "SmartCTF Score Settings: - Cap:" @ 7 + CapBonus @ "pts, Assist:" @ AssistBonus @ "pts." );
      Sender.ClientMessage( "- Cover (Kills while defending FC) Bonus :" @ CoverBonus @ "pts each. And" @ CoverBonus @ "more pts each if FC caps." );
      Sender.ClientMessage( "- Seal Bonus:" @ SealBonus @ "pts each, and" @ SealBonus @ "more pts each if FC caps." );
      Sender.ClientMessage( "- Seals (Kills while sealing off base) are defined by: 1) Your FC is on your team's side of map. 2) Your flag is not taken. 3) You kill someone on your side of the map." );
      if(bExtraStats)
        Sender.ClientMessage( "- DefKills (Kills while the enemy is in your base area) are defined by: 1) Your flag is not taken. 2) You kill someone on your side of the map." );
      Sender.ClientMessage( "- Flagkills:" @ 5 + FlagKillBonus @ "pts. Flag Returns in base are worth" @ DitchZeros( BaseReturnBonus ) @ "pts, in mid" @ DitchZeros( MidReturnBonus ) @ "pts, enemy base" @ DitchZeros( EnemyBaseReturnBonus ) @ "pts, VERY close to capping" @ DitchZeros( CloseSaveReturnBonus ) @ "pts." );
      Sender.ClientMessage( "- Additional features: See Readme!" );
    }
    else if( Mid( MutateString, 9, 8 ) ~= "ForceEnd" )
    {
      if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
      {
        Sender.ClientMessage( "You need to be logged in as admin to force the game to end." );
      }
      else
      {
        BroadcastMessage( Sender.PlayerReplicationInfo.PlayerName @ "forced the game to end." );
        bForcedEndGame = True;
        CTFGame( Level.Game ).EndGame( "forced" );
      }
    }
    else if( Mid( MutateString, 9, 10 ) ~= "ClearStats" )
    {
      if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
      {
        Sender.ClientMessage( "You need to be logged in as admin to be able to clear the stats." );
      }
      else
      {
        ClearStats();
        Sender.ClientMessage( "Stats cleared." );
      }
    }
    else
    {
      Sender.ClientMessage( "SmartCTF by {PiN}Kev_HH. 4C by {DnF2}SiNiSTeR. 4D by [es]Rush. We run 4D++!");
      Sender.ClientMessage( "- To toggle stats, bind a key or type in console: 'Mutate SmartCTF Stats'" );
      Sender.ClientMessage( "- Type 'Mutate CTFInfo' for SmartCTF settings." );
      Sender.ClientMessage( "- Type 'Mutate SmartCTF Rules' for new point system definition." );
      Sender.ClientMessage( "- Type 'Mutate SmartCTF ForceEnd' to end a game." );
      if( bEnableOvertimeControl ) Sender.ClientMessage( "- Type 'Mutate OverTime <On|Off>' for Overtime Control." );
    }
  }
  else if( Left( MutateString, 7 ) ~= "CTFInfo" )
  {
    SoundsString = "";
    if( bPlayCaptureSound ) SoundsString = SoundsString @ "Capture";
    if( bPlayAssistSound ) SoundsString = SoundsString @ "Assist";
    if( bPlaySavedSound ) SoundsString = SoundsString @ "Saved";
    if( bPlayLeadSound ) SoundsString = SoundsString @ "Lead";
    if( bPlay30SecSound ) SoundsString = SoundsString @ "30SecLeft";
    if( SoundsString == "" ) SoundsString = "All off";
    if( Left( SoundsString, 1 ) == " " ) SoundsString = Mid( SoundsString, 1 );
    MsgsString = "";
    if( CoverMsgType == 1 ) MsgsString = MsgsString @ "Covers<priv.con>";
    if( CoverMsgType == 2 ) MsgsString = MsgsString @ "Covers<pub.con>";
    if( CoverMsgType == 3 ) MsgsString = MsgsString @ "Covers";
    if( CoverSpreeMsgType == 1 ) MsgsString = MsgsString @ "Coversprees<priv.con>";
    if( CoverSpreeMsgType == 2 ) MsgsString = MsgsString @ "Coversprees<pub.con>";
    if( CoverSpreeMsgType == 3 ) MsgsString = MsgsString @ "Coversprees";
    if( SealMsgType == 1 ) MsgsString = MsgsString @ "Seals<priv.con>";
    if( SealMsgType == 2 ) MsgsString = MsgsString @ "Seals<pub.con>";
    if( SealMsgType == 3 ) MsgsString = MsgsString @ "Seals";
    if( SavedMsgType == 1 ) MsgsString = MsgsString @ "Saved<priv.con>";
    if( SavedMsgType == 2 ) MsgsString = MsgsString @ "Saved<pub.con>";
    if( SavedMsgType == 3 ) MsgsString = MsgsString @ "Saved";
    if( MsgsString == "" ) MsgsString = "All off";
    if( Left( MsgsString, 1 ) == " " ) MsgsString = Mid( MsgsString, 1 );
    CMsgsString = "";
    if( bShowAssistConsoleMsg ) CMsgsString = CMsgsString @ "AssistBonus";
    if( bShowSealRewardConsoleMsg ) CMsgsString = CMsgsString @ "SealReward";
    if( bShowCoverRewardConsoleMsg ) CMsgsString = CMsgsString @ "CoverReward";
    if( bShowLongRangeMsg ) CMsgsString = CMsgsString @ "LongRangeKill";
    if( CMsgsString == "" ) CMsgsString = "All off";
    if( Left( CMsgsString, 1 ) == " " ) CMsgsString = Mid( CMsgsString, 1 );
    Sender.ClientMessage( "- bExtraStats:" @ bExtraStats);
    Sender.ClientMessage( "- Sounds:" @ SoundsString );
    Sender.ClientMessage( "- Msgs:" @ MsgsString );
    Sender.ClientMessage( "- Private Msgs:" @ CMsgsString );
    Sender.ClientMessage( "- bFixFlagBug:" @ bFixFlagBug );
    Sender.ClientMessage( "- bEnhancedMultiKill:" @ bEnhancedMultiKill $ ", Broadcast Level:" @ EnhancedMultiKillBroadcast );
    Sender.ClientMessage( "- bShowFCLocation:" @ bShowFCLocation );
    if( bSpawnKillDetection ) Sender.ClientMessage( "- bSpawnKillDetection: True, Global Msg:" @ bShowSpawnKillerGlobalMsg $ ", Penalty:" @ SpawnKillPenalty @ "pts" );
    else Sender.ClientMessage( "- bSpawnKillDetection: False" );
    Sender.ClientMessage( "- Overtime Control:" @ bEnableOvertimeControl @ "( Type 'Mutate OverTime' )" );
    Sender.ClientMessage( "- Scores: ( Type 'Mutate SmartCTF Rules' )");
  }
  else if( Left( MutateString, 8 ) ~= "OverTime" )
  {
    if( !DeathMatchPlus( Level.Game ).bTournament )
    {
      Sender.ClientMessage( "Not in Tournament Mode: Default Sudden Death Overtime behaviour." );
    }
    else if( !bEnableOvertimeControl )
    {
      Sender.ClientMessage( "Overtime Control is not enabled: Default UT Sudden Death functionality." );
      Sender.ClientMessage( "Admins can use: admin set SmartCTF bEnableOvertimeControl True" );
    }
    else
    {
      if( Left( MutateString, 11 ) ~= "OverTime On" )
      {
        if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
        {
          Sender.ClientMessage( "You need to be logged in as admin to change this setting." );
        }
        else
        {
          bOvertime = True;
          SaveConfig();
          BroadcastLocalizedMessage( class'SmartCTFCoolMsg', 3 );
        }
      }
      else if( Left( MutateString, 12 ) ~= "OverTime Off" )
      {
        if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
        {
          Sender.ClientMessage( "You need to be logged in as admin to change this setting." );
        }
        else
        {
          bOvertime = False;
          SaveConfig();
          BroadcastLocalizedMessage( class'SmartCTFCoolMsg', 4 );
        }
      }
      else
      {
        if( Sender.PlayerReplicationInfo.bAdmin || Level.NetMode == NM_StandAlone ) Sender.ClientMessage( "Usage: Mutate OverTime On|Off" );
        if( !bOvertime ) Sender.ClientMessage( "Sudden Death Overtime is DISABLED." );
        else Sender.ClientMessage( "Sudden Death Overtime is ENABLED (default)." );
        Sender.ClientMessage( "Remember 'Disabled' Setting:" @ bRememberOvertimeSetting );
      }
    }
  }

  super.Mutate( MutateString, Sender );
}

/*
 * To stop on a tie if needed.
 */
function bool HandleEndGame()
{
  local TeamInfo Best;
  local byte i, MaxTeams;
  local bool bTied;

  if( CTFGame( Level.Game ).Teams[0].Score == CTFGame( Level.Game ).Teams[1].Score ) bTied = True;

  if( bForcedEndGame || ( bEnableOvertimeControl && !bOvertime && DeathMatchPlus( Level.Game ).bTournament ) )
  {
    bForcedEndGame = False;
    if( bTied )
    {
      SetEndCamsTiedCTFGame();
      //ShowEndGameStats();
      return True;
    }
  }

  if( !bTied )
  {
    CalcSmartCTFEndStats();
    //ShowEndGameStats();
  }
   if(bStoreStats)	UpdateInfo();
  if( NextMutator != None ) return NextMutator.HandleEndGame();
  return False;
}

/*function ShowEndGameStats()
{
  local Pawn pn;
  local SmartCTFPlayerReplicationInfo PlayerStats;

  for( pn = Level.PawnList ; pn != None ; pn = pn.NextPawn )
  {
    if( PlayerPawn( pn ) != None && pn.bIsPlayer )
    {
      PlayerStats = SCTFGame.GetStats( pn );
      if( PlayerStats != None ) PlayerStats.ShowStats();
    }
  }
}*/

/*
 * Position end cameras for a tied game.
 */
function SetEndCamsTiedCTFGame()
{
  local Pawn pn, Best;
  local PlayerPawn Player;
  local CTFGame gg;

  gg = CTFGame( Level.Game );

  // Find Individual Winner
  for( pn = Level.PawnList ; pn != None ; pn = pn.NextPawn )
  {
    if( pn.bIsPlayer && ( ( Best == None ) || ( pn.PlayerReplicationInfo.Score > Best.PlayerReplicationInfo.Score ) ) )
      Best = pn;
  }

  gg.GameReplicationInfo.GameEndedComments = GameTieMessage;
  gg.EndTime = Level.TimeSeconds + 3.0;

  for( pn = Level.PawnList ; pn != None ; pn = pn.NextPawn )
  {
    Player = PlayerPawn( pn );
    if( Player != None )
    {
      Player.bBehindView = True;
      if( Player == Best ) Player.ViewTarget = None;
      else Player.ViewTarget = Best;

      Player.ClientPlaySound( sound'CaptureSound', , true );
      Player.ClientGameEnded();
    }
    pn.GotoState( 'GameEnded' );
  }

  gg.CalcEndStats();
  CalcSmartCTFEndStats();
}

function CalcSmartCTFEndStats()
{
  local SmartCTFPlayerReplicationInfo TopScore, TopFrags, TopCaps, TopCovers, TopFlagkills, TopHeadshots;
  local string BestRecordDate;
  local int ID;
  local float PerHour;
  local SmartCTFPlayerReplicationInfo PawnStats;
  local PlayerReplicationInfo PRI;
  local byte i;
  local SmartCTFEndStats EndStats;

  EndStats = SCTFGame.EndStats;

  SCTFGame.RefreshPRI();
  for( i = 0; i < 64; i++ )
  {
    PawnStats = SCTFGame.GetStatNr( i );
    if( PawnStats == None ) break;

    if( TopScore == None || PlayerReplicationInfo( PawnStats.Owner ).Score > PlayerReplicationInfo( TopScore.Owner ).Score ) TopScore = PawnStats;
    if( TopFrags == None || PawnStats.Frags > TopFrags.Frags ) TopFrags = PawnStats;
    if( TopCaps == None || PawnStats.Captures > TopCaps.Captures ) TopCaps = PawnStats;
    if( TopCovers == None || PawnStats.Covers > TopCovers.Covers ) TopCovers = PawnStats;
    if( TopFlagkills == None || PawnStats.FlagKills > TopFlagkills.FlagKills ) TopFlagkills = PawnStats;
    if( TopHeadshots == None || PawnStats.HeadShots > TopHeadshots.HeadShots ) TopHeadshots = PawnStats;
  }

  PRI = PlayerReplicationInfo( TopScore.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( PRI.Score / PerHour > EndStats.MostPoints.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostPoints.Count = PRI.Score / PerHour;
    EndStats.MostPoints.PlayerName = PRI.PlayerName;
    EndStats.MostPoints.MapName = Level.Title;
    CTFGame( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostPoints.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopFrags.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopFrags.Frags / PerHour > EndStats.MostFrags.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostFrags.Count = TopFrags.Frags / PerHour;
    EndStats.MostFrags.PlayerName = PRI.PlayerName;
    EndStats.MostFrags.MapName = Level.Title;
    CTFGame( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostFrags.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopCaps.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopCaps.Captures / PerHour > EndStats.MostCaps.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostCaps.Count = TopCaps.Captures / PerHour;
    EndStats.MostCaps.PlayerName = PRI.PlayerName;
    EndStats.MostCaps.MapName = Level.Title;
    CTFGame( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostCaps.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopCovers.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopCovers.Covers / PerHour > EndStats.MostCovers.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostCovers.Count = TopCovers.Covers / PerHour;
    EndStats.MostCovers.PlayerName = PRI.PlayerName;
    EndStats.MostCovers.MapName = Level.Title;
    CTFGame( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostCovers.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopFlagkills.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopFlagkills.FlagKills / PerHour > EndStats.MostFlagKills.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostFlagKills.Count = TopFlagkills.FlagKills / PerHour;
    EndStats.MostFlagKills.PlayerName = PRI.PlayerName;
    EndStats.MostFlagKills.MapName = Level.Title;
    CTFGame( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostFlagKills.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopHeadshots.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopHeadshots.HeadShots / PerHour > EndStats.MostHeadShots.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostHeadShots.Count = TopHeadshots.HeadShots / PerHour;
    EndStats.MostHeadShots.PlayerName = PRI.PlayerName;
    EndStats.MostHeadShots.MapName = Level.Title;
    CTFGame( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostHeadShots.RecordDate = BestRecordDate;
  }

  EndStats.SaveConfig();
}

/*
 * Convert a float to a readable string.
 */
function string DitchZeros( float nr )
{
  local string str;

  str = string( nr );
  while( Right( str, 1 ) == "0" )
  {
    str = Left( str , Len( str ) - 1 );
  }
  if( Right( str, 1 ) == "." ) str = Left( str , Len( str ) - 1 );

  return str;
}

//----------------------------------------------------------------------------------------------------------------
//------------------------------------------------ CLIENT FUNCTIONS ----------------------------------------------
//----------------------------------------------------------------------------------------------------------------

/*
 * Render the HUD that is startup logo and FC location.
 * ONLY gets executed on clients.
 */
simulated event PostRender( Canvas C )
{
  local int i, Y;
  local float DummyY, Size, Temp;
  local string TempStr;

  // Get stuff relating to PlayerOwner, if not gotten. Also spawn Font info.
  if( PlayerOwner == None )
  {
    PlayerOwner = C.Viewport.Actor;
    MyHUD = ChallengeHUD( PlayerOwner.MyHUD );

    pTGRI = TournamentGameReplicationInfo( PlayerOwner.GameReplicationInfo );
    pPRI = PlayerOwner.PlayerReplicationInfo;
    MyFonts = MyHUD.MyFonts;
  }

  // Draw the FC Location
  if( SCTFGame.bShowFCLocation )
  {
    for( i = 0; i < 32; i++ )
    {
      if( pTGRI.PRIArray[i] == None ) break;
      if( pTGRI.PRIArray[i].bIsSpectator && !pTGRI.PRIArray[i].bWaitingPlayer ) continue;
      if( pTGRI.PRIArray[i].HasFlag != None && pTGRI.PRIArray[i].Team == pPRI.Team && pTGRI.PRIArray[i].PlayerID != pPRI.PlayerID && !pTGRI.PRIArray[i].HasFlag.IsA( 'GreenFlag' ) )
      {
        if( pTGRI.PRIArray[i].PlayerLocation != None ) TempStr = pTGRI.PRIArray[i].PlayerLocation.LocationName;
        else if( pTGRI.PRIArray[i].PlayerZone != None ) TempStr = pTGRI.PRIArray[i].PlayerZone.ZoneName;
        if( TempStr == "" )
        {
          TempStr = "Nameless Area";
          C.Style = ERenderStyle.STY_Translucent;
        }
        else
        {
          C.Style = ERenderStyle.STY_Normal;
        }

        if( pPRI.Team == 0 ) C.DrawColor = RedTeamColor;
        else C.DrawColor = BlueTeamColor;

        C.Font = MyFonts.GetSmallestFont( C.ClipX );
        C.StrLen( TempStr, Size, DummyY );
        if( MyHUD.bHideAllWeapons ) Y = C.ClipY;
        else if( MyHUD.HudScale * MyHUD.WeaponScale * C.ClipX <= C.ClipX - 256 * MyHUD.Scale) Y = C.ClipY - 64 * MyHUD.Scale;
        else Y = C.ClipY - 128 * MyHUD.Scale;

        C.SetPos( C.ClipX - Size - 6, Y - 4 - 32 + ( 32 - DummyY ) / 2 );
        C.DrawText( TempStr );
        if( C.Style == ERenderStyle.STY_Translucent ) C.DrawColor = Gray;
        else C.DrawColor = White;
        C.SetPos( C.ClipX - Size - 6 - 32 - 4, Y - 4 - 32 );
        if( pPRI.Team == 0 ) C.DrawIcon( texture'blueflag', 1.0 );
        else C.DrawIcon( texture'redflag', 1.0 );

        break;
      }
    }
  }

  // Draw "Powered by.." logo when player joins
  if( DrawLogo != 0 )
  {
    C.Style = ERenderStyle.STY_Translucent;
    if( DrawLogo > 1 )
    {
      C.DrawColor.R = 255 - DrawLogo/2;
      C.DrawColor.G = 255 - DrawLogo/2;
      C.DrawColor.B = 255 - DrawLogo/2;
    }
    else // 1
    {
      C.Style = ERenderStyle.STY_Translucent;
      C.DrawColor = White;
    }
    if(powered == None)
    	powered=texture'powered';
    C.SetPos( C.ClipX - powered.Usize - 16, 40 );
    C.DrawIcon( powered, 1 );
    C.Font = MyFonts.GetSmallFont( C.ClipX );
	//C.Font = Font(DynamicLoadObject("LadderFonts.UTLadder14", class'Font'));
    C.StrLen( "SmartCTF "$Version , Size, DummyY );
    C.SetPos( C.ClipX  - powered.Usize/2 - Size/2 - 16, 40 + 8 + powered.Vsize );
    Temp = DummyY;
    C.DrawText( "SmartCTF "$Version );
  }

  C.Style = ERenderStyle.STY_Normal;

  if( NextHUDMutator != None ) NextHUDMutator.PostRender( C );
}


/*
 * Executed on the client when that player joins the server.
 */
simulated function ClientJoinServer( Pawn Other )
{
  if( PlayerPawn( Other ) == None || !Other.bIsPlayer ) return;

  if(SCTFGame.bDrawLogo)
  DrawLogo = 1;
  
  SetTimer( 0.05 , True);
	  
  // Since this gets called in the HUD it needs to be changed clientside.
  if( SCTFGame.bPlay30SecSound ) class'TimeMessage'.default.TimeSound[5] = sound'Announcer.CD30Sec';
}

/*
 * Clientside settings that need to be set for the first time, checking for welcome message and
 * end of game screen.
 */
simulated function Tick( float delta )
{
  local SmartCTFPlayerReplicationInfo OwnerStats;

  // Execute on client
  if( Level.NetMode != NM_DedicatedServer )
  {
    if( SCTFGame == None )
    {
      ForEach AllActors( class'SmartCTFGameReplicationInfo', SCTFGame ) break;
      if( SCTFGame == None ) return;

      if( !SCTFGame.bServerInfoSetServerSide && SCTFGame.DefaultHUDType != None ) // client side required
      {
        class<ChallengeHUD>( SCTFGame.DefaultHUDType ).default.ServerInfoClass = class'SmartCTFServerInfo';
        Log( "Notified HUD (clientside," @ SCTFGame.DefaultHUDType.name $ ") to use SmartCTF ServerInfo.", 'SmartCTF' );
      }
    }
    if( !SCTFGame.bInitialized ) return;

    if( !bHUDMutator ) RegisterHUDMutator();

    if( PlayerOwner != None )
    {
      if( !bClientJoinPlayer )
      {
        bClientJoinPlayer = True;
        ClientJoinServer( PlayerOwner );
      }

      // If Game is over, bring up F3.
      if( PlayerOwner.GameReplicationInfo.GameEndedComments != "" && !bGameEnded )
      {
        bGameEnded = True;
        OwnerStats = SCTFGame.GetStatsByPRI( pPRI );
        //if( OwnerStats != None ) OwnerStats.ShowStats();
        OwnerStats.bEndStats = True;
        PlayerOwner.ConsoleCommand( "mutate SmartCTF ForceStats" );
      }
    }
  }
}

/*
 * For showing the Logo a Timer is used instead of Ticks so its equal for each tickrate.
 * On the server it keeps track of some replicated data and whether a Tournament game is starting.
 */
simulated function Timer()
{
  local bool bReady;
  local Pawn pn;
  local SmartCTFPlayerReplicationInfo SenderStats;
  local	int		i,j,k;
  local	string	IP;
  local	Pawn	P;
  
  
  super.Timer();

  // Clients - 0.05 second timer. Stops after logo is displayed.
  if( Level.NetMode != NM_DedicatedServer )
  {
    if( DrawLogo != 0 && SCTFGame.bDrawLogo )
    {
      LogoCounter++;
      if( DrawLogo == 510 )
      {
        DrawLogo = 0;
        if( Role != ROLE_Authority ) SetTimer( 0.0, False ); // client timer off
        else SetTimer( 1.0, True ); // standalone game? keep timer running for bit below.
      }
      else if( LogoCounter > 60 )
      {
        DrawLogo += 8;
        if( DrawLogo > 510 ) DrawLogo = 510;
      }
      else if( LogoCounter == 60 )
      {
        DrawLogo = 5;
      }
    }

	if(!bInitSb && bSCTFSbDef){
		if(bGameEnded){ bInitSb=true; return; } // Don't interfere with scoreboard showing on game end
		SbCount++;
		if(SbCount>=SCTFGame.SbDelayC){ // Wait SbDelayC second(s) before calling SmartCTF sb
		SenderStats = SCTFGame.GetStats( PlayerOwner );
        if( SenderStats != None ) SenderStats.ShowStats(true);
		bInitSb=true; 
		if(!SCTFGame.bDrawLogo && Role != ROLE_Authority) SetTimer(0.0,False);
		}
	}
  }

  // Server - 1 second timer. infinite.
  if( Level.NetMode == NM_DedicatedServer || Role == ROLE_Authority )
  {
    if( ++TRCount > 2 )
    {
      SCTFGame.TickRate = int( ConsoleCommand( "get IpDrv.TcpNetDriver NetServerMaxTickRate" ) );
      TRCount = 0;
    }
	
	SbDelayC = SbDelay*20; // Timer is called every 0.05s, so * 20 converts the value in seconds to our count compatible value

    // Update config vars to client / manual replication :E
    // Allows for runtime changing of settings.
    if( SCTFGame.bShowFCLocation != bShowFCLocation ) SCTFGame.bShowFCLocation = bShowFCLocation;
    if( SCTFGame.bStatsDrawFaces != bStatsDrawFaces ) SCTFGame.bStatsDrawFaces = bStatsDrawFaces;
    if( SCTFGame.bDrawLogo != bDrawLogo ) SCTFGame.bDrawLogo = bDrawLogo;
	if( SCTFGame.bShowSpecs != bShowSpecs ) SCTFGame.bShowSpecs = bShowSpecs;
	if( SCTFGame.bDoKeybind != bDoKeybind ) SCTFGame.bDoKeybind = bDoKeybind;
	if( SCTFGame.SbDelayC != SbDelayC ) SCTFGame.SbDelayC = SbDelayC;

    if( !bTournamentGameStarted && DeathMatchPlus( Level.Game ).bTournament )
    {
      if( DeathMatchPlus( Level.Game ).bRequireReady && DeathMatchPlus( Level.Game ).CountDown > 0
       && ( DeathMatchPlus( Level.Game ).NumPlayers == DeathMatchPlus( Level.Game ).MaxPlayers || Level.NetMode == NM_Standalone )
       && DeathMatchPlus( Level.Game ).RemainingBots <= 0 )
      {
        bReady = True;
        for( pn = Level.PawnList; pn != None; pn = pn.NextPawn )
        {
          if( pn.IsA( 'PlayerPawn' ) && !pn.IsA( 'Spectator' ) && !PlayerPawn( pn ).bReadyToPlay )
          {
            bReady = False;
            break;
          }
        }
      }

      if( bReady )
      {
        bTournamentGameStarted = True;
        TournamentGameStarted();
      }
    }
	
	// UT's built-in messaging spectator is excluded from the spectator list based on its starttime.
	// We need to make sure this does not include any players as well.
	// Update: on slow/exotic servers, the starttime could be delayed (not 0). Let's make sure it is.
	if(!bStartTimeCorrected && bShowSpecs)
	{
	for(pn = Level.PawnList; pn != None; pn = pn.NextPawn){
	if(pn.IsA('PlayerPawn') && pn.PlayerReplicationInfo.StartTime==0) pn.PlayerReplicationInfo.StartTime=1;
	if(!pn.bIsPlayer && pn.PlayerReplicationInfo.Playername=="Player") pn.PlayerReplicationInfo.StartTime=0;
	}
	if(Level.TimeSeconds>=5) bStartTimeCorrected=true; // After five seconds, the messaging spectator(s) should be loaded, so we are done.
	}

	// Since PlayerID's are incremented in the order of player joins [and those joined later cannot have an earlier StartTime than preceding players], this can be reliably used to deliver each player the delayed message only once 
	// without having to resort to a large array of PIDs already messaged; we can simply check against the *last* PID messaged instead.
	// Too bad the timer only runs at 1.0. That sorf of defies the purpose of MsgDelay being a float instead of an int. O well... matches nice with SbDelay ;)
	for(pn = Level.PawnList; pn != None; pn = pn.NextPawn)
	if(pn.IsA('PlayerPawn') && pn.bIsPlayer && Level.TimeSeconds - pn.PlayerReplicationInfo.StartTime >= MsgDelay && pn.PlayerReplicationInfo.PlayerID>MsgPID){
	if(!SCTFGame.bDrawLogo)
	pn.ClientMessage( "Running SmartCTF " $ Version $ ". Type 'Mutate SmartCTF' in the console for info." );
	if(bExtraMsg && bDoKeybind && SCTFGame.bDrawLogo)
	pn.ClientMessage("Running SmartCTF " $ Version $ ". Press F3 to toggle between scoreboards.");
	else if(bExtraMsg && bDoKeybind)
	pn.ClientMessage("Press F3 to toggle between scoreboards."); // Shorter msg, since we already announced we are running SmartCTF.
	MsgPID = pn.PlayerReplicationInfo.PlayerID; // Increase to keep track of whom still to message
	}
  }
  
    //Shuffle backup 1 val's into the backup 2 array and clear the backup 1 array.
	//It's enough to clear just the names, as that is what is checked in the for
	//loops above.
	for(k=0; k<32; k++)
	{
		B2Name[k]=B1Name[k];
		B2Score[k]=B1Score[k];
		B2Deaths[k]=B1Deaths[k];
		B2IP[k]=B1IP[k];
		B2Stats[k]=B1Stats[k];

		B1Name[k]="";
	}
	
	for(P=Level.PawnList ; P!=none; P=P.nextPawn)
	{
		if( PlayerPawn(P)!=none && P.bIsPlayer && !P.IsA('Spectator') && !P.IsA('Bot')&& P.PlayerReplicationInfo!=none && P.PlayerReplicationInfo.PlayerName!="Player"&& (P.PlayerReplicationInfo.Score!=0 || P.PlayerReplicationInfo.Deaths!=0) )
		{
			IP=PlayerPawn(P).GetPlayerNetworkAddress();
			if( IP!="" )
			{
				j=InStr(IP,":");
				if( j!=-1 )
					IP=Left(IP,j);
			}
			B1Name[i]=P.PlayerReplicationInfo.PlayerName;
			B1Score[i]=P.PlayerReplicationInfo.Score;
			B1Deaths[i]=P.PlayerReplicationInfo.Deaths;
			if(SCTFGame.GetStats( P ) != none)
			B1Stats[i]=SCTFGame.GetStats( P );
			B1IP[i]=IP;
			i++;
		}
	}
  
}

defaultproperties
{
     Version="4D++"
     GameTieMessage="The game ended in a tie!"
     RedTeamColor=(R=255)
     BlueTeamColor=(G=128,B=255)
     White=(R=255,G=255,B=255)
     Gray=(R=128,G=128,B=128)
     bEnabled=True
     bExtraStats=True
     CountryFlagsPackage="CountryFlags2"
     CapBonus=15
     AssistBonus=7
     FlagKillBonus=3
     CoverBonus=2
     SealBonus=3
     BaseReturnBonus=0.500000
     MidReturnBonus=2.000000
     EnemyBaseReturnBonus=5.000000
     CloseSaveReturnBonus=10.000000
     MinimalCapBonus=5
     bFixFlagBug=True
     bEnhancedMultiKill=True
     EnhancedMultiKillBroadcast=3
     bShowFCLocation=True
     bSmartCTFServerInfo=True
     bNewCapAssistScoring=True
     bSpawnkillDetection=True
     SpawnKillTimeArena=1.000000
     SpawnKillTimeNW=3.500000
     bAfterGodLikeMsg=True
     bStatsDrawFaces=True
     bDrawLogo=True
     bSCTFSbDef=True
     bShowSpecs=True
     bDoKeybind=True
     bExtraMsg=True
     SbDelay=5.500000
     MsgDelay=7.000000
     bStoreStats=True
     CoverMsgType=2
     CoverSpreeMsgType=3
     SealMsgType=3
     SavedMsgType=3
     bShowSpawnKillerGlobalMsg=True
     bShowAssistConsoleMsg=True
     bShowSealRewardConsoleMsg=True
     bShowCoverRewardConsoleMsg=True
     bPlayCaptureSound=True
     bPlayAssistSound=True
     bPlaySavedSound=True
     bPlayLeadSound=True
     bPlay30SecSound=True
     bOverTime=True
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
}
