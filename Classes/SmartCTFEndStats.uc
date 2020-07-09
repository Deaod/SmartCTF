class SmartCTFEndStats expands EndStats config( user );

replication
{
  reliable if( Role == ROLE_Authority )
    MostPoints, MostFrags, MostCaps, MostFlagKills, MostCovers, MostHeadShots;
}

struct BestSomething {
   var int Count;
   var string PlayerName;
   var string MapName;
   var string RecordDate;
};

var globalconfig BestSomething MostPoints;
var globalconfig BestSomething MostFrags;
var globalconfig BestSomething MostCaps;
var globalconfig BestSomething MostFlagKills;
var globalconfig BestSomething MostCovers;
var globalconfig BestSomething MostHeadShots;

defaultproperties
{
     MostPoints=(Count=2970,PlayerName="The_Cowboy",MapName="Pure Action",RecordDate="06/03/2009 15:58:14")
     MostFrags=(Count=406,PlayerName="Aryss",MapName="Pure Action",RecordDate="06/03/2009 21:31:44")
     MostCaps=(Count=105,PlayerName="Archon",MapName="Liandri Docks",RecordDate="05/29/2009 14:09:35")
     MostFlagKills=(Count=189,PlayerName="The_Cowboy",MapName="Pure Action",RecordDate="06/03/2009 15:58:14")
     MostCovers=(Count=61,PlayerName="Aryss",MapName="Pure Action",RecordDate="06/03/2009 21:31:44")
     MostHeadShots=(Count=64,PlayerName="{-_-}",MapName="Facing Worlds",RecordDate="05/14/2009 23:05:14")
     bAlwaysRelevant=True
}
