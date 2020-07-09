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
     bAlwaysRelevant=True
}
