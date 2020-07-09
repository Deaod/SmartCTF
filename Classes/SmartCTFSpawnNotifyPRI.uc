class SmartCTFSpawnNotifyPRI expands SpawnNotify;

simulated event Actor SpawnNotification( Actor A )
{
  if( A.Owner == None ) return A;
  if( !A.Owner.IsA( 'PlayerPawn' ) && !A.Owner.IsA( 'Bot' ) ) return A;
  if( !Pawn( A.Owner ).bIsPlayer ) return A;

  // Spawn SmartCTF PRI for this pawn on the server
  Spawn( class'SmartCTFPlayerReplicationInfo', A );

  return A;
}

defaultproperties
{
     ActorClass=Class'Engine.PlayerReplicationInfo'
}
