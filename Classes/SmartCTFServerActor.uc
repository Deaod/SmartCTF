class SmartCTFServerActor expands Actor;

function PostBeginPlay()
{
  if( CTFGame( Level.Game ) != None )
  {
    Log( "ServerActor, Spawning and adding Mutator...", 'SmartCTF' );
    Level.Game.BaseMutator.AddMutator( Level.Game.Spawn( class'SmartCTF' ) );
  }
  Destroy();
}

defaultproperties
{
     bHidden=True
}
