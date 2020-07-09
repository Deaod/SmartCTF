class SmartCTFFlagCheckerInventory expands TournamentPickup;

// This inventory item gets added to every player by default.
// Now, each time this inventory item gets destroyed it means either the player left the game or died.
// If he simply died, then the original code already made sure the flag is dropped, before we get here,
// and nothing special happens.
// When we're here, we will check if he was actually carrying the flag. If he still has a flag, it means
// the player left the server and we drop the flag manually.
// All this happens before the code that would send the flag home.
// Quite ingenious if I may say so :p (c) {DnF2}SiNiSTeR imo xD

var string DroppedMessage;

function Destroyed()
{
	local CTFFlag flag;

	// Use Other.Class==Class'ClassName' if you want a specific Actor type 
	if( Owner != none && Owner.IsA('Pawn') ) {
		if( Pawn( Owner ).bIsPlayer ) { // Pawn is a player
			flag = CTFFlag( Pawn( Owner ).PlayerReplicationInfo.HasFlag );

			if( flag != None ) { // Should handle casting failure
				flag.Drop( 0.5 * Pawn( Owner ).Velocity );
				BroadcastMessage( Pawn( Owner ).PlayerReplicationInfo.PlayerName @ DroppedMessage );
			}
		}
	}

	super.Destroyed(); // Call Destroyed() on super class TournamentPickup
}

defaultproperties
{
     DroppedMessage="had the flag but disconnected. Flag is dropped!"
     bHeldItem=True
     bHidden=True
}
