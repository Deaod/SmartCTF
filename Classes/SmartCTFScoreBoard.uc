class SmartCTFScoreBoard extends UnrealCTFScoreBoard;

#exec texture IMPORT NAME=faceless File=Textures\faceless.pcx GROUP=SmartCTF
#exec texture IMPORT NAME=shade File=Textures\shade4.bmp GROUP=SmartCTF MIPS=OFF LODSET=2
#exec texture IMPORT NAME=RedHoFicon File=Textures\RedHoFicon.bmp GROUP=SmartCTF MIPS=ON FLAGS=2
#exec texture IMPORT NAME=BlueHoFicon File=Textures\BlueHoFicon.bmp GROUP=SmartCTF MIPS=ON FLAGS=2

var ScoreBoard NormalScoreBoard;
var SmartCTFGameReplicationInfo SCTFGame;
var SmartCTFPlayerReplicationInfo OwnerStats;

var int TryCount;
var PlayerPawn PlayerOwner;

var string PtsText, FragsText, SepText, MoreText, HeaderText;
var int LastSortTime, MaxMeterWidth;
var byte ColorChangeSpeed, RowColState;
var Color White, Gray, DarkGray, Yellow, BlackColor, RedTeamColor, BlueTeamColor, RedHeaderColor, BlueHeaderColor, StatsColor, FooterColor, HeaderColor, TinyInfoColor, HeaderTinyInfoColor;
var float StatsTextWidth, StatHeight, MeterHeight, NameHeight, ColumnHeight, StatBlockHeight;
var float RedStartX, BlueStartX, ColumnWidth, StatWidth, StatsHorSpacing, ShadingSpacingX, HeaderShadingSpacingY, ColumnShadingSpacingY;
var float StartY, StatLineHeight, StatBlockSpacing, StatIndent;
var TournamentGameReplicationInfo pTGRI;
var PlayerReplicationInfo pPRI;
var Font StatFont, CapFont, FooterFont, GameEndedFont, PlayerNameFont, FragsFont, TinyInfoFont;
var Font PtsFont22, PtsFont20, PtsFont18, PtsFont16, PtsFont14, PtsFont12;

var int MaxCaps, MaxAssists, MaxGrabs, MaxCovers, MaxSeals, MaxDefKills, MaxFlagKills, MaxFrags, MaxDeaths;
var int TotShieldBelts, TotAmps;

var bool bSealsOrDefs;
var bool bStarted;
var bool bEndHandled;

struct FlagData {
	var string Prefix;
	var texture Tex;
};
var FlagData FD[32]; // there can be max 32 so max 32 different flags
var int saveindex; // new loaded flags will be saved in FD[index]

function int GetFlagIndex(string Prefix)
{
	local int i;
	for(i=0;i<32;i++)
		if(FD[i].Prefix == Prefix)
			return i;
	FD[saveindex].Prefix=Prefix;
	FD[saveindex].Tex=texture(DynamicLoadObject(SCTFGame.CountryFlagsPackage$"."$Prefix, class'Texture'));
	i=saveindex;
	saveindex = (saveindex+1) % 256;
	return i;
}

function PostBeginPlay()
{
  super.PostBeginPlay();

  PlayerOwner = PlayerPawn( Owner );
  pTGRI = TournamentGameReplicationInfo( PlayerOwner.GameReplicationInfo );
  pPRI = PlayerOwner.PlayerReplicationInfo;
  LastSortTime = -100;

  // Preload
  PtsFont22 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
  PtsFont20 = Font( DynamicLoadObject( "LadderFonts.UTLadder20", class'Font' ) );
  PtsFont18 = Font( DynamicLoadObject( "LadderFonts.UTLadder18", class'Font' ) );
  PtsFont16 = Font( DynamicLoadObject( "LadderFonts.UTLadder16", class'Font' ) );
  PtsFont14 = Font( DynamicLoadObject( "LadderFonts.UTLadder14", class'Font' ) );
  PtsFont12 = Font( DynamicLoadObject( "LadderFonts.UTLadder12", class'Font' ) );

  SpawnNormalScoreBoard();
  if( NormalScoreBoard == None ) SetTimer( 1.0 , True );
  else
  {
      bStarted = True;
      SetTimer( 3.0, true);
  }
}

// Try to spawn a local instance of the original scoreboard class if it doesn't exist already.
function SpawnNormalScoreBoard()
{
  if( SCTFGame == None )
  {
    ForEach AllActors( class'SmartCTFGameReplicationInfo', SCTFGame ) break;
  }
  if( SCTFGame != None ) OwnerStats = SCTFGame.GetStats( PlayerOwner );

  if( SCTFGame != None && SCTFGame.NormalScoreBoardClass == None )
  {
    Log( "Unable to identify original ScoreBoard type. Retrying in 1 second." , 'SmartCTF' );
    return;
  }

  if( SCTFGame != None && SCTFGame.NormalScoreBoardClass == self.Class )
  {
    NormalScoreBoard = Spawn( class'UnrealCTFScoreBoard', PlayerOwner );
    Log( "Cannot use itself. Using the default CTF ScoreBoard instead." , 'SmartCTF' );
    return;
  }

  if( SCTFGame != None && SCTFGame.NormalScoreBoardClass != None )
  {
    NormalScoreBoard = Spawn( SCTFGame.NormalScoreBoardClass, PlayerOwner );
    Log( "Determined and spawned original scoreboard as" @ NormalScoreBoard, 'SmartCTF' );
  }
}

// In the case of the 'normal scoreboard' not being replicated properly, try every second to see if it has.
function Timer()
{
  if(!bStarted)
  {
      if( NormalScoreBoard == None )
      {
        TryCount++;
        SpawnNormalScoreBoard();
      }

      if( NormalScoreBoard != None )
      {
        bStarted = True;
        SetTimer( 3.0, True );
      }
      else if( TryCount > 3 )
      {
        Log( "Given up. Using the default CTF ScoreBoard instead." , 'SmartCTF' );

        if( NormalScoreBoard == None )
        {
          NormalScoreBoard = Spawn( class'UnrealCTFScoreBoard', PlayerOwner );
          Log( "Spawned as" @ NormalScoreBoard, 'SmartCTF' );
        }
        bStarted = True;
        SetTimer( 3.0, True );
      }
    }
    else
    {
        bSealsOrDefs = !bSealsOrDefs;
    }
}

function ShowScores( Canvas C )
{
  if( SCTFGame == None || OwnerStats == None )
  {
    if( NormalScoreBoard != None ) NormalScoreBoard.ShowScores( C );
    else PlayerOwner.bShowScores = False;
    return;
  }

    if(OwnerStats.bEndStats && !bEndHandled)
    {
        bEndHandled = True;
        bSealsOrDefs = True;
        SetTimer(10, true);
    }

  if( OwnerStats.bViewingStats )
    SmartCTFShowScores( C );
  else
  {
    if( NormalScoreBoard == None ) SmartCTFShowScores( C );
    else NormalScoreBoard.ShowScores( C );
  }

  if( OwnerStats.IndicatorVisibility > 0 ) ShowIndicator( C );
}

function ShowIndicator( Canvas C )
{
  local float BlockLen, LineHeight;

  C.DrawColor.R = OwnerStats.IndicatorVisibility;
  C.DrawColor.G = OwnerStats.IndicatorVisibility;
  C.DrawColor.B = OwnerStats.IndicatorVisibility;
  C.Style = ERenderStyle.STY_Translucent;
  C.Font = C.SmallFont;
  C.StrLen( "Scoreboard:", BlockLen, LineHeight );
  C.SetPos( C.ClipX - BlockLen - 16, 16 );
  C.DrawText( "Scoreboard:" );
  C.SetPos( C.ClipX - BlockLen, 16 + LineHeight );
  C.DrawText( "Default" );
  C.SetPos( C.ClipX - BlockLen, 16 + 2 * LineHeight );
  C.DrawText( "SmartCTF" );
  if( OwnerStats.bViewingStats ) C.SetPos( C.ClipX - BlockLen - 16, 16 + 2 * LineHeight );
  else C.SetPos( C.ClipX - BlockLen - 16, 16 + LineHeight );
  C.DrawIcon( texture'UWindow.MenuTick', 1 );
  C.Style = ERenderStyle.STY_Normal;

  if( Level.TimeSeconds - OwnerStats.IndicatorStartShow > 2 ) OwnerStats.IndicatorVisibility = 0;
}

function SmartCTFShowScores( Canvas C )
{
  local int ID, i, j, Time, AvgPing, AvgPL, TotSB, TotAmp;
  local float Eff;
  local int RedY, BlueY, X, Y;
  local float Nil, DummyX, DummyY, SizeX, SizeY, Buffer, Size;
  local byte LabelDrawn[2], Rendered[2];
  local Color TeamColor, TempColor;
  local string TempStr;
  local SmartCTFPlayerReplicationInfo PlayerStats, PlayerStats2;
  local int FlagShift; /* shifting elements to fit a flag */

  if( Level.TimeSeconds - LastSortTime > 0.5 )
  {
    SortScores( 32 );
    RecountNumbers();
    InitStatBoardConstPos( C );
    CompressStatBoard( C );
    LastSortTime = Level.TimeSeconds;
  }

  Y = int( StartY );
  RedY = Y;
  BlueY = Y;

  C.Style = ERenderStyle.STY_Normal;

  // FOR EACH PLAYER DRAW INFO
  for( i = 0; i < 32; i++ )
  {
    if( Ordered[i] == None ) break;
    PlayerStats = SCTFGame.GetStatsByPRI( Ordered[i] );
    if( PlayerStats == None ) continue;

    // Get the ID of the ith player
    ID = Ordered[i].PlayerID;

    // set the pos depending on Team
    if( Ordered[i].Team == 0 )
    {
      X = RedStartX;
      Y = RedY;
      TeamColor = RedTeamColor;
    }
    else
    {
      X = BlueStartX;
      Y = BlueY;
      TeamColor = BlueTeamColor;
    }
    C.DrawColor = TeamColor;

    if( LabelDrawn[Ordered[i].Team] == 0 )
    {
      // DRAW THE Team SCORES with the cool Flag icons (masked because of black borders)

      C.bNoSmooth = False;
      C.Font = PlayerNameFont;
      C.Style = ERenderStyle.STY_Translucent;
      if( Ordered[i].Team == 0 ) C.DrawColor = RedHeaderColor;
      else C.DrawColor = BlueHeaderColor;
      C.StrLen( PtsText, SizeX, SizeY );

      C.Style = ERenderStyle.STY_Translucent;
      C.SetPos( X - ShadingSpacingX, Y - HeaderShadingSpacingY );
      if( Ordered[i].Team == 0 ) C.DrawPattern( texture'JDomN0', ColumnWidth + ( ShadingSpacingX * 2 ) , SizeY + ( HeaderShadingSpacingY * 2 ) , 1 );
      else C.DrawPattern( texture'JDomN0', ColumnWidth + ( ShadingSpacingX * 2 ) , SizeY + ( HeaderShadingSpacingY * 2 ) , 1 );

      //C.DrawColor.R = 20;
      //C.DrawColor.G = 20;
      //C.DrawColor.B = 20;
      C.Style = ERenderStyle.STY_Modulated;
      //C.Style = ERenderStyle.STY_Translucent;
      C.SetPos( X - ShadingSpacingX, Y - HeaderShadingSpacingY );
      C.DrawRect( texture'shade', ColumnWidth + ( ShadingSpacingX * 2 ) , SizeY + ( HeaderShadingSpacingY * 2 ) );

      C.Style = ERenderStyle.STY_Modulated;
      //C.Style = ERenderStyle.STY_Translucent;
      C.SetPos( X - ShadingSpacingX, Y + SizeY + HeaderShadingSpacingY );
      C.DrawRect( texture'shade', ColumnWidth + ( ShadingSpacingX * 2 ) , ColumnHeight + ( ColumnShadingSpacingY * 2 ) );

      C.Style = ERenderStyle.STY_Normal;
      C.DrawColor = TeamColor;
      C.SetPos( X, Y - ( ( 32 - SizeY ) / 2 ) ); // Y - 4
      if( Ordered[i].Team == 0 ) DrawShadowIcon(C, texture'RedHoFicon', 0.5); // * 64.0 / texture'BlueHoFicon'.VSize );
      else DrawShadowIcon(C, texture'BlueHoFicon', 0.5); // * 64.0 / texture'BlueHoFicon'.VSize );

      C.Font = CapFont;
      C.StrLen( int( pTGRI.Teams[Ordered[i].Team].Score ), DummyX, DummyY );
      C.Style = ERenderStyle.STY_Normal;
      C.SetPos( X + StatIndent, Y - ( ( DummyY - SizeY ) / 2 ) );
      DrawShadowText(C, int( pTGRI.Teams[Ordered[i].Team].Score ), true);

      //Draw the Frags/Pts text
      C.Font = PlayerNameFont;
      C.SetPos( X + ColumnWidth - SizeX, Y );
      DrawShadowText(C, PtsText, true );
      C.Font = FragsFont;
      C.StrLen( FragsText $ SepText, Buffer, Nil );
      C.SetPos( X + ColumnWidth - SizeX - Buffer, Y );
      DrawShadowText(C, FragsText $ SepText, true );

      C.DrawColor = HeaderTinyInfoColor;
      C.Font = TinyInfoFont;
      C.StrLen( "TEST", Nil, DummyY );
      C.SetPos( X + StatIndent + DummyX + 2 * StatsHorSpacing, Y + ( SizeY - DummyY * 2 ) / 2 );
      Time = Max( 1, Level.TimeSeconds / 60 );
      AvgPing = 0;
      AvgPL = 0;
      TotSB = 0;
      TotAmp = 0;
      for( j = 0; j < 32; j++ )
      {
        if( Ordered[j] == None ) break;
        if( Ordered[j].Team == Ordered[i].Team )
        {
          PlayerStats2 = SCTFGame.GetStatsByPRI( Ordered[j] );
          if( PlayerStats2 == None ) continue;
          AvgPing += Ordered[j].Ping;
          AvgPL += Ordered[j].PacketLoss;
          TotSB += PlayerStats2.ShieldBelts;
          TotAmp += PlayerStats2.Amps;
        }
      }
      if( pTGRI.Teams[Ordered[i].Team].Size != 0 )
      {
        AvgPing = AvgPing / pTGRI.Teams[Ordered[i].Team].Size;
        AvgPL = AvgPL / pTGRI.Teams[Ordered[i].Team].Size;
      }
      if( TotShieldBelts == 0 ) TotSB = 0;
      else TotSB = Clamp( float( TotSB ) / float( TotShieldBelts ) * 100, 0, 100 );
      if( TotAmps == 0 ) TotAmp = 0;
      else TotAmp = Clamp( float( TotAmp ) / float( TotAmps ) * 100, 0, 100 );
      TempStr = "PING:" $ AvgPing $ " PL:" $ AvgPL $ "%";
      DrawShadowText(C, TempStr, true );
      C.SetPos( X + StatIndent + DummyX + 2 * StatsHorSpacing, Y + ( SizeY - DummyY * 2 ) / 2 + DummyY );
      TempStr = "TM:" $ Time;
      if( TotSB != 0 ) TempStr = TempStr @ "SB:" $ TotSB $ "%";
      if( TotAmp != 0 ) TempStr = TempStr @ "AM:" $ TotAmp $ "%";
      DrawShadowText(C, TempStr, true );

      C.bNoSmooth = True;

      Y += SizeY + HeaderShadingSpacingY + ColumnShadingSpacingY;
      LabelDrawn[Ordered[i].Team] = 1;
    }

    C.Font = FooterFont;
    C.StrLen( "Test", Nil, DummyY );
    if( LabelDrawn[Ordered[i].Team] != 2 && ( Y + NameHeight + StatBlockHeight + StatBlockSpacing > C.ClipY - DummyY * 5 ) )
    {

      C.DrawColor = TeamColor;
      C.StrLen( MoreText , Size, DummyY );
      if( Ordered[i].Team == 1 ) C.SetPos( X + ColumnWidth - Size, C.ClipY - DummyY * 5 );
      else C.SetPos( X, C.ClipY - DummyY * 5 );
      DrawShadowText(C, "[" @ pTGRI.Teams[Ordered[i].Team].Size - Rendered[Ordered[i].Team] @ MoreText @ "]" , true);
      LabelDrawn[Ordered[i].Team] = 2; // "More" label also drawn
    }

    else if( LabelDrawn[Ordered[i].Team] != 2 )
    {

      // Draw the face
      if( Ordered[i].HasFlag == None )
      {
        C.bNoSmooth = False;
        C.DrawColor = White;
        C.Style = ERenderStyle.STY_Normal;
        C.SetPos( X, Y );
        if( SCTFGame.bStatsDrawFaces && Ordered[i].TalkTexture != None ) C.DrawIcon( Ordered[i].TalkTexture, 0.5 * 64.0 / Ordered[i].TalkTexture.VSize );
        else C.DrawIcon( texture'faceless', 0.5 );
        C.SetPos( X, Y );
        C.DrawColor = DarkGray;
        C.DrawIcon( texture'IconSelection', 1 );
        C.Style = ERenderStyle.STY_Normal;
        C.bNoSmooth = True;
      }

      // Draw the player name
      C.SetPos( X + StatIndent, Y );

      C.Font = PlayerNameFont;
      if( Ordered[i].bAdmin ) C.DrawColor = White;
      else if( Ordered[i].PlayerID == pPRI.PlayerID ) C.DrawColor = Yellow;
      else C.DrawColor = TeamColor;
      TempColor = C.DrawColor;
      DrawShadowText(C, Ordered[i].PlayerName, true );
      C.StrLen( Ordered[i].PlayerName, Size, Buffer );

      C.DrawColor = TinyInfoColor;
      C.Font = TinyInfoFont;
      C.StrLen( "TEST", Buffer, DummyY );

      // Draw Time, Eff, HS, SB, Amp
      C.SetPos( X + StatIndent + Size + StatsHorSpacing, Y + ( NameHeight - DummyY * 2 ) / 2 );
      TempStr = "";
      if( PlayerStats.HeadShots != 0 ) TempStr = TempStr $ "HS:" $ PlayerStats.HeadShots;
      if( PlayerStats.ShieldBelts != 0 ) TempStr = TempStr @ "SB:" $ PlayerStats.ShieldBelts;
      if( PlayerStats.Amps != 0 ) TempStr = TempStr @ "AM:" $ PlayerStats.Amps;
      if( Left( TempStr, 1 ) == " " ) TempStr = Mid( TempStr, 1 );
      DrawShadowText(C, TempStr, true );
      Time = Max( 1, ( Level.TimeSeconds + pPRI.StartTime - Ordered[i].StartTime ) / 60 );
      if( PlayerStats.Frags + Ordered[i].Deaths == 0 ) Eff = 0;
      else Eff = ( PlayerStats.Frags / ( PlayerStats.Frags + Ordered[i].Deaths ) ) * 100;
      C.SetPos( X + StatIndent + Size + StatsHorSpacing, Y + ( NameHeight - DummyY * 2 ) / 2 + DummyY );
      DrawShadowText(C, "TM:" $ Time $ " EFF:" $ Clamp( int( Eff ), 0, 100 ) $ "%", true );

      // Draw the country flag
      if(PlayerStats.CountryPrefix != "")
      {
        C.SetPos( X+8, Y + StatIndent);
        C.bNoSmooth = False;
        C.DrawColor = White;
        C.DrawIcon(FD[GetFlagIndex(PlayerStats.CountryPrefix)].Tex, 1.0);
        FlagShift=12;
        C.bNoSmooth = True;
      }
      else
        FlagShift=0;
      // Draw Bot or Ping/PL
      C.SetPos( X, Y + StatIndent + FlagShift);
      if( Ordered[i].bIsABot )
      {
        DrawShadowText(C, "BOT", true );
        if( Ordered[i].Team == pPRI.Team )
        {
          C.SetPos( X, Y + StatIndent + DummyY);
          DrawShadowText(C, Left( string( BotReplicationInfo( Ordered[i] ).RealOrders ) , 3 ), true );
        }
      }
      else
      {
        C.DrawColor = HeaderTinyInfoColor;
        TempStr = "PI:" $ Ordered[i].Ping;
        if( Len( TempStr ) > 5 ) TempStr = "P:" $ Ordered[i].Ping;
        if( Len( TempStr ) > 5 ) TempStr = string( Ordered[i].Ping );
        DrawShadowText(C, TempStr, true );
        C.SetPos( X, Y + StatIndent + DummyY + FlagShift);
        TempStr = "PL:" $ Ordered[i].PacketLoss $ "%";
        if( Len( TempStr ) > 5 ) TempStr = "L:" $ Ordered[i].PacketLoss $ "%";
        if( Len( TempStr ) > 5 ) TempStr = "L:" $ Ordered[i].PacketLoss;
        if( Len( TempStr ) > 5 ) TempStr = Ordered[i].PacketLoss $ "%";
        DrawShadowText(C, TempStr, true );
      }

      // Draw the Flag if he has Flag
      if( Ordered[i].HasFlag != None )
      {
        C.DrawColor = White;
        C.SetPos( X, Y );
        if( Ordered[i].HasFlag.IsA( 'GreenFlag' ) ) C.DrawIcon( texture'GreenFlag', 1 );
        else if( Ordered[i].HasFlag.IsA( 'YellowFlag' ) ) C.DrawIcon( texture'YellowFlag', 1 );
        else if( Ordered[i].Team == 0 ) C.DrawIcon( texture'BlueFlag', 1 );
        else C.DrawIcon( texture'RedFlag', 1 );
      } // End if he has Flag

      C.Font = PlayerNameFont;
      C.DrawColor = TempColor;

      // Draw Frag/Score
      C.StrLen( int( Ordered[i].Score ), Size, DummyY );
      C.SetPos( X + ColumnWidth - Size, Y );
      DrawShadowText(C, int( Ordered[i].Score ), true );

      C.Font = FragsFont;
      C.StrLen( PlayerStats.Frags $ SepText, Buffer, SizeY );
      C.SetPos( X + ColumnWidth - Size - Buffer, Y );
      DrawShadowText(C, PlayerStats.Frags $ SepText, true );

      Y += NameHeight;

      // Set the Font for the stat drawing
      C.Font = StatFont;

      if( RowColState == 1 )
      {
        DrawStatType( C, X, Y, 1, 1, "Caps: ", PlayerStats.Captures, MaxCaps );
        DrawStatType( C, X, Y, 1, 2, "Assists: ", PlayerStats.Assists, MaxAssists );
        DrawStatType( C, X, Y, 1, 3, "Grabs: ", PlayerStats.Grabs, MaxGrabs );
        if(SCTFGame.bExtraStats)
        {
          if( bSealsOrDefs) {
              DrawStatType( C, X, Y, 2, 2, "DefKills: ", PlayerStats.DefKills, MaxDefKills );
              DrawStatType( C, X, Y, 2, 1, "Covers: ", PlayerStats.Covers, MaxCovers );
          }
          else {
              DrawStatType( C, X, Y, 2, 2, "Seals: ", PlayerStats.Seals, MaxSeals );
              DrawStatType( C, X, Y, 2, 1, "Deaths: ", Ordered[i].Deaths, MaxDeaths );
          }
        }
        else
        {
          DrawStatType( C, X, Y, 2, 1, "Covers: ", PlayerStats.Covers, MaxCovers );
          if( MaxSeals > 0 ) DrawStatType( C, X, Y, 2, 2, "Seals: ", PlayerStats.Seals, MaxSeals );
          else DrawStatType( C, X, Y, 2, 2, "Deaths: ", Ordered[i].Deaths, MaxDeaths );
        }
        DrawStatType( C, X, Y, 2, 3, "FlagKls: ", PlayerStats.FlagKills, MaxFlagKills );
      }
      else
      {
        DrawStatType( C, X, Y, 1, 1, "Caps: ", PlayerStats.Captures, MaxCaps );
        DrawStatType( C, X, Y, 2, 1, "Grabs: ", PlayerStats.Grabs, MaxGrabs );

        if(SCTFGame.bExtraStats)
        {
          if( bSealsOrDefs) {
              DrawStatType( C, X, Y, 2, 2, "DefKills: ", PlayerStats.DefKills, MaxDefKills );
              DrawStatType( C, X, Y, 1, 2, "Covers: ", PlayerStats.Covers, MaxCovers );
          }
          else {
              DrawStatType( C, X, Y, 2, 2, "Seals: ", PlayerStats.Seals, MaxSeals );
              DrawStatType( C, X, Y, 1, 2, "Deaths: ", Ordered[i].Deaths, MaxDeaths );
          }
        }
        else
        {
          DrawStatType( C, X, Y, 1, 2, "Covers: ", PlayerStats.Covers, MaxCovers );
          if( MaxSeals > 0 ) DrawStatType( C, X, Y, 2, 2, "Seals: ", PlayerStats.Seals, MaxSeals );
          else DrawStatType( C, X, Y, 2, 2, "Deaths: ", Ordered[i].Deaths, MaxDeaths );
        }
          DrawStatType( C, X, Y, 3, 1, "Assists: ", PlayerStats.Assists, MaxAssists );
          DrawStatType( C, X, Y, 3, 2, "FlagKls: ", PlayerStats.FlagKills, MaxFlagKills );
      }

      Y += StatBlockHeight + StatBlockSpacing;
    }

    // Alter the RedY or BlueY and do next player
    if( Ordered[i].Team == 0 ) RedY = Y;
    else BlueY = Y;
    Rendered[Ordered[i].Team]++;

  } //End of PRI for loop

  DrawHeader( C );
  DrawFooters( C );
}

function InitStatBoardConstPos( Canvas C )
{
  local float Nil, LeftSpacingPercent, MidSpacingPercent, RightSpacingPercent;

  CapFont = Font'LEDFont2'; //Font( DynamicLoadObject( "UWindowFonts.UTFont40", class'Font' ) );
  FooterFont = MyFonts.GetSmallestFont( C.ClipX );
  GameEndedFont = MyFonts.GetHugeFont( C.ClipX );
  PlayerNameFont = MyFonts.GetBigFont( C.ClipX );
  TinyInfoFont = C.SmallFont;

  if( PlayerNameFont == PtsFont22 ) FragsFont = PtsFont18;
  else if( PlayerNameFont == PtsFont20 ) FragsFont = PtsFont18;
  else if( PlayerNameFont == PtsFont18 ) FragsFont = PtsFont14;
  else if( PlayerNameFont == PtsFont16 ) FragsFont = PtsFont12;
  else FragsFont = font'SmallFont';

  C.Font = PlayerNameFont;
  C.StrLen( "Player", Nil, NameHeight );

  StartY = ( 120.0 / 1024.0 ) * C.ClipY;
  ColorChangeSpeed = 100; // Influences how 'fast' the color changes from white to green. Higher = faster.

  LeftSpacingPercent = 0.075;
  MidSpacingPercent = 0.15;
  RightSpacingPercent = 0.075;
  RedStartX = LeftSpacingPercent * C.ClipX;
  ColumnWidth = ( ( 1 - LeftSpacingPercent - MidSpacingPercent - RightSpacingPercent ) / 2 * C.ClipX );
  BlueStartX = RedStartX + ColumnWidth + ( MidSpacingPercent * C.ClipX );
  ShadingSpacingX = ( 10.0 / 1024.0 ) * C.ClipX;
  HeaderShadingSpacingY = ( 32 - NameHeight ) / 2 + ( ( 4.0 / 1024.0 ) * C.ClipX );
  ColumnShadingSpacingY = ( 10.0 / 1024.0 ) * C.ClipX;

  StatsHorSpacing = ( 5.0 / 1024.0 ) * C.ClipX;
  StatIndent = ( 32 + StatsHorSpacing ); // For face + flag icons

  InitStatBoardDynamicPos( C );
}

function InitStatBoardDynamicPos( Canvas C , optional int Rows , optional int Cols , optional Font NewStatFont , optional float LineSpacing , optional float BlockSpacing )
{
  if( Rows == 0 ) Rows = 3;
  if( Cols == 0 ) Cols = 2;
  if( LineSpacing == 0 ) LineSpacing = 0.9;
  if( BlockSpacing == 0 ) BlockSpacing = 1;

  if( Rows == 2 && Cols == 3 ) RowColState = 1;
  else RowColState = 0;

  StatWidth = ( ( ColumnWidth - StatIndent ) / Cols ) - ( StatsHorSpacing * ( Cols - 1 ) );

  if( NewStatFont == None ) StatFont = MyFonts.GetSmallestFont( C.ClipX );
  else StatFont = NewStatFont;
  C.Font = StatFont;
  C.StrLen( "FlagKls: 00", StatsTextWidth, StatHeight );

  MaxMeterWidth = StatWidth - StatsTextWidth - StatsHorSpacing;
  StatLineHeight = StatHeight * LineSpacing;
  MeterHeight = Max( 1, StatLineHeight * 0.3 );
  StatBlockSpacing = StatLineHeight * BlockSpacing;

  StatBlockHeight = Rows * StatLineHeight;

  if( pTGRI.Teams[0].Size > pTGRI.Teams[1].Size )
    ColumnHeight = pTGRI.Teams[0].Size * ( NameHeight + StatBlockHeight + StatBlockSpacing ) - StatBlockSpacing;
  else
    ColumnHeight = pTGRI.Teams[1].Size * ( NameHeight + StatBlockHeight + StatBlockSpacing ) - StatBlockSpacing;
}

function CompressStatBoard( Canvas C , optional int Level )
{
  local float EndY, Nil, DummyY;

  C.Font = FooterFont;
  C.StrLen( "Test", Nil, DummyY );

  EndY = StartY + ColumnHeight + ( ColumnShadingSpacingY * 2 ) + NameHeight + HeaderShadingSpacingY;
  if( EndY > C.ClipY - DummyY * 5 )
  {
    if( Level == 0 )
    {
      InitStatBoardDynamicPos( C, , , , 0.8 );
    }
    else if( Level == 1 )
    {
      InitStatBoardDynamicPos( C, 2, 3 );
    }
    else if( Level == 2 )
    {
      InitStatBoardDynamicPos( C, 2, 3, Font( DynamicLoadObject( "UWindowFonts.Tahoma10", class'Font' ) ) , 1.0 , 1.0 );
    }
    else
    {
      // We did all the compression we can do. Draw 'More' labels later.
      // First find the columnheight for the amount of players that fit on it.
      ColumnHeight = int( ( C.ClipY - ( EndY - ColumnHeight ) - DummyY * 5 + StatBlockSpacing ) / ( NameHeight + StatBlockHeight + StatBlockSpacing ) )
        * ( NameHeight + StatBlockHeight + StatBlockSpacing ) - StatBlockSpacing;
      return;
    }
    // Did some compression, see if we need more.
    CompressStatBoard( C , Level + 1 );
  }
  // No compression at all or no more compression needed.
  return;
}

/*
 * Draw a specific stat
 * X, Y = Upper left corner of stats ( row,col: 1,1)
 */
function DrawStatType( Canvas C, int X, int Y, int Row, int Col, string Label, int Count, int Total )
{
  local float Size, DummyY;
  local int ColorChange, M;

  X += StatIndent + ( ( StatWidth + StatsHorSpacing ) * ( Col - 1 ) );
  Y += ( StatLineHeight * ( Row - 1 ) );

  C.DrawColor = StatsColor;
  C.SetPos( X, Y );
  DrawShadowText(C, Label, true );
  C.StrLen( Count, Size, DummyY );
  C.SetPos( X + StatsTextWidth - Size, Y );
  DrawShadowText(C, Count, true ); //text
  if( Count > 0 )
  {
    ColorChange = ColorChangeSpeed * loge( Count );
    if( ColorChange > 255 ) ColorChange = 255;
    C.DrawColor.R = StatsColor.R - ColorChange;
    C.DrawColor.B = StatsColor.B - ColorChange;
  }
  M = GetMeterLength( Count, Total );
  C.SetPos( X + StatsTextWidth + StatsHorSpacing, Y + ( ( StatHeight - MeterHeight ) / 2 ) );
  DrawShadowRect(C, texture'meter', M, MeterHeight ); //meter
}

function DrawFooters( Canvas C )
{
  local float DummyX, DummyY, Nil, X1, Y1;
  local string TextStr;
  local string TimeStr;
  local int Hours, Minutes, Seconds, i;
  local PlayerReplicationInfo PRI;

  C.bCenter = True;
  C.Font = FooterFont;

  // Display server info in bottom center
  C.DrawColor = FooterColor;
  C.StrLen( "Test", DummyX, DummyY );
  C.SetPos( 0, C.ClipY - DummyY );
  TextStr = "Playing" @ Level.Title @ "on" @ pTGRI.ServerName;
  if( SCTFGame.TickRate > 0 ) TextStr = TextStr @ "(TR:" @ SCTFGame.TickRate $ ")";
  DrawShadowText(C, TextStr, true );

  // Draw Time
  if( bTimeDown || ( PlayerOwner.GameReplicationInfo.RemainingTime > 0 ) )
  {
    bTimeDown = True;
    if( PlayerOwner.GameReplicationInfo.RemainingTime <= 0 )
    {
      TimeStr = RemainingTime $ "00:00";
    }
    else
    {
      Minutes = PlayerOwner.GameReplicationInfo.RemainingTime / 60;
      Seconds = PlayerOwner.GameReplicationInfo.RemainingTime % 60;
      TimeStr = RemainingTime $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
    }
  }
  else
  {
    Seconds = PlayerOwner.GameReplicationInfo.ElapsedTime;
    Minutes = Seconds / 60;
    Hours = Minutes / 60;
    Seconds = Seconds - ( Minutes * 60 );
    Minutes = Minutes - ( Hours * 60 );
    TimeStr = ElapsedTime $ TwoDigitString( Hours ) $ ":" $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
  }

	if(SCTFGame.bShowSpecs){
		for ( i=0; i<32; i++ )
		{
			if (PlayerPawn(Owner).GameReplicationInfo.PRIArray[i] != None)
			{
				PRI = PlayerPawn(Owner).GameReplicationInfo.PRIArray[i];
				if (PRI.bIsSpectator && !PRI.bWaitingPlayer && PRI.StartTime > 0)
				{
					if(HeaderText=="") HeaderText = pri.Playername; else HeaderText = HeaderText$", "$pri.Playername;
				}
			}
		}
		if (HeaderText=="") HeaderText = "there is currently no one spectating this match."; else HeaderText = HeaderText$".";
	}
  
  C.SetPos( 0, C.ClipY - 2 * DummyY );
  DrawShadowText(C, "Current Time:" @ GetTimeStr() @ "|" @ TimeStr, true );

  // Draw Author
  C.StrLen( HeaderText, DummyX, Nil );
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( 0, C.ClipY - 4 * DummyY );
  
  if(SCTFGame.bShowSpecs){
  C.Font = MyFonts.GetSmallestFont(C.ClipX);
  DrawShadowText(C,"Spectators:"@HeaderText, true );
  HeaderText=""; // This is declared as a global var, so we reset it to start with a clean slate.
  }else{
  C.DrawColor = Yellow;
  DrawShadowText(C, HeaderText, true );
  }
   
  C.bCenter = False;
}

function DrawHeader( Canvas C )
{
  local float DummyX, DummyY;

  if( pTGRI.GameEndedComments == "" ) return;

  C.Font = GameEndedFont;
  C.StrLen( pTGRI.GameEndedComments, DummyX, DummyY );

  C.DrawColor = DarkGray;
  C.Style = ERenderStyle.STY_Translucent;
  C.SetPos( C.ClipX / 2 - DummyX / 2 + 2, DummyY + 2 );
  DrawShadowText(C, pTGRI.GameEndedComments, true );

  C.DrawColor = HeaderColor;
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( C.ClipX / 2 - DummyX / 2, DummyY );
  DrawShadowText(C, pTGRI.GameEndedComments, true );
}

/*
 * Returns time and date in a string.
 */
function string GetTimeStr()
{
  local string Mon, Day, Min;

  Min = string( PlayerOwner.Level.Minute );
  if( int( Min ) < 10 ) Min = "0" $ Min;

  switch( PlayerOwner.Level.month )
  {
    case  1: Mon = "Jan"; break;
    case  2: Mon = "Feb"; break;
    case  3: Mon = "Mar"; break;
    case  4: Mon = "Apr"; break;
    case  5: Mon = "May"; break;
    case  6: Mon = "Jun"; break;
    case  7: Mon = "Jul"; break;
    case  8: Mon = "Aug"; break;
    case  9: Mon = "Sep"; break;
    case 10: Mon = "Oct"; break;
    case 11: Mon = "Nov"; break;
    case 12: Mon = "Dec"; break;
  }

  switch( PlayerOwner.Level.dayOfWeek )
  {
    case 0: Day = "Sunday";    break;
    case 1: Day = "Monday";    break;
    case 2: Day = "Tuesday";   break;
    case 3: Day = "Wednesday"; break;
    case 4: Day = "Thursday";  break;
    case 5: Day = "Friday";    break;
    case 6: Day = "Saturday";  break;
  }

  return Day @ PlayerOwner.Level.Day @ Mon @ PlayerOwner.Level.Year $ "," @ PlayerOwner.Level.Hour $ ":" $ Min;
}

/*
 * Length of a meter drawing for a given number A out of B total.
 */
function int GetMeterLength( int A, int B )
{
  local int Result;

  if( B == 0 ) return 0;
  Result = ( A * MaxMeterWidth ) / B;

  if( Result > MaxMeterWidth ) return MaxMeterWidth;
  else return Result;
}

/*
 * Sort PlayerReplicationInfo's on score.
 */
function SortScores( int N )
{
  local byte i, j;
  local bool bSorted;
  local SmartCTFPlayerReplicationInfo PlayerStats1, PlayerStats2;

  // Copy PRI array except for spectators.
  j = 0;
  for( i = 0; i < N; i++ )
  {
    if( pTGRI.priArray[i] == None ) break;
    if( pTGRI.priArray[i].bIsSpectator && !pTGRI.priArray[i].bWaitingPlayer ) continue;
    Ordered[j] = pTGRI.priArray[i];
    j++;
  }
  // Clear the remaining entries.
  for( i = j; i < N; i++ )
  {
    Ordered[i] = None;
  }

  for( i = 0; i < N; i++)
  {
    bSorted = True;
    for( j = 0; j < N - 1; j++)
    {
      if( Ordered[j] == None || Ordered[j+1] == None ) break;

      if( Ordered[j].Score < Ordered[j+1].Score )
      {
        SwapOrdered( j, j + 1 );
        bSorted = False;
      }
      else if( Ordered[j].Score == Ordered[j+1].Score )
      {
        PlayerStats1 = SCTFGame.GetStatsByPRI( Ordered[j] );
        PlayerStats2 = SCTFGame.GetStatsByPRI( Ordered[j+1] );
        if( PlayerStats1 != None && PlayerStats2 != None )
        {
          if( PlayerStats1.Frags < PlayerStats2.Frags )
          {
            SwapOrdered( j, j + 1 );
            bSorted = False;
          }
          else if( PlayerStats1.Frags == PlayerStats2.Frags )
          {
            if( Ordered[j].Deaths > Ordered[j+1].Deaths )
            {
              SwapOrdered( j, j + 1 );
              bSorted = False;
            }
          }
        }
      }
    }
    if( bSorted ) break;
  }
}

/*
 * Used for sorting.
 */
function SwapOrdered( byte A, byte B )
{
  local PlayerReplicationInfo Temp;
  Temp = Ordered[A];
  Ordered[A] = Ordered[B];
  Ordered[B] = Temp;
}

/*
 * Recalculate the totals for displaying meters on the scoreboards.
 * This way it doesn't get calculated every tick.
 */
function RecountNumbers()
{
  local byte ID, i;
  local SmartCTFPlayerReplicationInfo PlayerStats;

  MaxCaps = 0;
  MaxAssists = 0;
  MaxGrabs = 0;
  MaxCovers = 0;
  MaxSeals = 0;
  MaxDefKills = 0;
  MaxFlagKills = 0;
  MaxFrags = 0;
  MaxDeaths = 0;
  TotShieldBelts = 0;
  TotAmps = 0;

  for( i = 0; i < 32; i++ )
  {
    if( Ordered[i] == None ) break;
    if( Ordered[i].bIsSpectator && !Ordered[i].bWaitingPlayer ) continue;

    ID = Ordered[i].PlayerID;

    PlayerStats = SCTFGame.GetStatsByPRI( Ordered[i] );
    if( PlayerStats != None )
    {
      if( PlayerStats.Captures > MaxCaps ) MaxCaps = PlayerStats.Captures;
      if( PlayerStats.Assists > MaxAssists ) MaxAssists = PlayerStats.Assists;
      if( PlayerStats.Grabs > MaxGrabs ) MaxGrabs = PlayerStats.Grabs;
      if( PlayerStats.Covers > MaxCovers ) MaxCovers = PlayerStats.Covers;
      if( PlayerStats.Seals > MaxSeals ) MaxSeals = PlayerStats.Seals;
      if( PlayerStats.DefKills > MaxDefKills ) MaxDefKills = PlayerStats.DefKills;
      if( PlayerStats.FlagKills > MaxFlagKills ) MaxFlagKills = PlayerStats.FlagKills;
      if( PlayerStats.Frags > MaxFrags ) MaxFrags = PlayerStats.Frags;
      TotShieldBelts += PlayerStats.ShieldBelts;
      TotAmps += PlayerStats.Amps;
    }
    if( Ordered[i].Deaths > MaxDeaths ) MaxDeaths = Ordered[i].Deaths;
  }
}

function DrawShadowText (Canvas C, coerce string Text, optional bool Param,optional bool bSmall, optional bool bGrayShadow)
{

	local Color OldColor;
	local float XL,YL;
	local float X, Y;

	OldColor = C.DrawColor;

	if (bGrayShadow)
	{

		C.DrawColor.R = 127;
		C.DrawColor.G = 127;
		C.DrawColor.B = 127;

	}

	else
	{

		C.DrawColor.R = 0;
		C.DrawColor.G = 0;
		C.DrawColor.B = 0;

	}

	if (bSmall)
	{

		XL = 0;
		YL = 0;

	}

	else
	{

		XL = 1;
		YL = 1;

	}

	X=C.CurX;
	Y=C.CurY;
	C.SetPos(X+XL,Y+YL);
	C.DrawText(Text, Param);
	C.DrawColor = OldColor;
	C.SetPos(X,Y);
	C.DrawText(Text, Param);
}

function DrawShadowIcon ( Canvas C, Texture Tex, float Scale )
{

	local float X, Y;
	local color OldColor;

	X = C.CurX;
	Y = C.CurY;
	C.CurX += 1;
	C.CurY += 1;
	OldColor = C.DrawColor;
	C.DrawColor = BlackColor;
	C.DrawIcon(Tex, Scale );
	C.SetPos(X, Y);
	C.DrawColor = OldColor;
	C.DrawIcon(Tex, Scale);

}

function DrawShadowRect ( Canvas C, Texture Tex, float RectX, float RectY )
{

	local float X, Y;
	local color OldColor;

	X = C.CurX;
	Y = C.CurY;
	C.CurX += 1;
	C.CurY += 1;
	OldColor = C.DrawColor;
	C.DrawColor = BlackColor;
	C.DrawRect(Tex, RectX, RectY );
	C.SetPos(X, Y);
	C.DrawColor = OldColor;
	C.DrawRect(Tex, RectX, RectY );

}

defaultproperties
{
     PtsText="Pts"
     FragsText="Frags"
     SepText=" / "
     MoreText="More..."
     HeaderText="[ SmartCTF 4F_002 {HoF} Edition! ]"
     White=(R=255,G=255,B=255)
     Gray=(R=128,G=128,B=128)
     DarkGray=(R=32,G=32,B=32)
     Yellow=(R=255,G=255)
     RedTeamColor=(R=255)
     BlueTeamColor=(G=128,B=255)
     RedHeaderColor=(R=64)
     BlueHeaderColor=(G=32,B=64)
     StatsColor=(R=255,G=255,B=255)
     FooterColor=(R=255,G=255,B=255)
     HeaderColor=(R=255,G=255)
     TinyInfoColor=(R=128,G=128,B=128)
     HeaderTinyInfoColor=(R=192,G=192,B=192)
}
