// SnowyScoreboard original from CTT. Thanks to Defrost!
// Brought to SmartCTF by Sp0ngeb0b
// spongebobut@yahoo.com
class SmartCTFSnowyScoreboard extends SmartCTFScoreBoard;

#exec texture import name=snowFlake1 file="Textures\SnowFlake1.pcx" mips=off flags=2
#exec texture import name=snowFlake2 file="Textures\SnowFlake2.pcx" mips=off flags=2
#exec texture import name=snowFlake3 file="Textures\SnowFlake3.pcx" mips=off flags=2
#exec texture import name=snowFlake4 file="Textures\SnowFlake4.pcx" mips=off flags=2
#exec texture import name=snowFlake5 file="Textures\SnowFlake5.pcx" mips=off flags=2
#exec texture import name=snowFlake6 file="Textures\SnowFlake6.pcx" mips=off flags=2
#exec texture import name=snowFlake7 file="Textures\SnowFlake7.pcx" mips=off flags=2
#exec texture import name=snowFlake8 file="Textures\SnowFlake8.pcx" mips=off flags=2
#exec texture import name=snowFlake9 file="Textures\SnowFlake9.pcx" mips=off flags=2
#exec texture import name=snowFlake10 file="Textures\SnowFlake10.pcx" mips=off flags=2
#exec texture import name=snowFlake11 file="Textures\SnowFlake11.pcx" mips=off flags=2
#exec texture import name=snowFlake12 file="Textures\SnowFlake12.pcx" mips=off flags=2
#exec texture import name=snowFlake13 file="Textures\SnowFlake13.pcx" mips=off flags=2
#exec texture import name=snowFlake14 file="Textures\SnowFlake14.pcx" mips=off flags=2
#exec texture import name=snowFlake15 file="Textures\SnowFlake15.pcx" mips=off flags=2
#exec texture import name=snowFlake16 file="Textures\SnowFlake16.pcx" mips=off flags=2
//#exec texture import name=lights file="Textures\Lights2.pcx" mips=off flags=2
#exec texture import name=santa file="Textures\santa2.pcx" mips=off flags=2
#exec texture import name=present file="Textures\presents.pcx" mips=off flags=2

struct ParticleInfo {                   // Snow particle description struct.
	var int spriteNum;                  // The snow flake sprite to use.
	var float cx;                       // Horizontal offset.
	var float cy;                       // Vertical offset.
	var float ct;                       // Time offset.
	var float waveFreq;                 // Particle wave frequency.
	var float waveAmplitude;            // Amplitude of the wave.
	var float dy;                       // Vertical base velocity.
	var float dx;                       // Horizontal base velocity.
	var color col;                      // Color of the particle.
};

var color baseColor;                    // Base color of the snow flakes.
var bool bSnowInitialized;              // Whether the particles have been initialized.
var Texture sprites[16];                // Snow flake sprites.
var ParticleInfo particles[100];        // Current particles displayed.
var float lastUpdateTime;               // Last time the particles were rendered.

var float minDX;                        // Minimum horizontal base velocity.
var float maxDX;                        // Maximum horizontal base velocity.
var float minDY;                        // Minimum vertical base velocity.
var float maxDY;                        // Maximum vertical base velocity.
var float minWaveAmplitude;             // Minimum wave amplitude.
var float maxWaveAmplitude;             // Maximum wave amplitude.

// Non scaled constants.
const minWaveFreq = 0.25;               // Minimum wave frequency.
const maxWaveFreq = 1.0;                // Maximum wave frequency.
const minGlow = 0.40;                   // Minimum snow flake sprite glow.
const maxGlow = 1.00;                   // Maximum snow flake sprite glow.

// Scaled constants (set for a resolution of 1280x1024 px).
const scaleMinDX = -20.0;
const scaleMaxDX = 20.0;
const scaleMinDY = 100.0;
const scaleMaxDY = 300.0;
const scaleMinWaveAmplitude = 8;
const scaleMaxWaveAmplitude = 22;
const scaleWidth = 1280;
const scaleHeight = 1024;

// Texture constante
// const lightsTextureWidth = 32;           // Width of the lights texture.
// const lightsTextureHeight = 256;        // Height of the lights texture.

const santaTextureWidth = 128;             // Width of the santa texture.
const santaTextureHeight = 128;           // Height of the santa texture.

const presentTextureWidth = 128;           // Width of the present texture.
const presentTextureHeight = 128;         // Height of the present texture.



/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the scoreboard.
 *  $PARAM        c  The canvas on which the rendering should be performed.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function showScores(Canvas c) {
	super.showScores(c);
	renderSnow(c);
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the scoreboard in small scale?
 *  $PARAM        c  The canvas on which the rendering should be performed.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function showMiniScores(Canvas c) {
	super.showMiniScores(c);
	renderSnow(c);
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the snow particles. Also adds the XmasImages.
 *  $PARAM        c  The canvas on which the rendering should be performed.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function renderSnow(Canvas c) {
	local int baseX, baseY;
	local int index;
	local Texture sprite;
	local float cx, cy;

	// Update position of each particle.
	updateSnow(c);

	// Draw each particle.
	c.style = ERenderStyle.STY_Translucent;
	for (index = 0; index < arrayCount(particles); index++) {
		// Set position.
		cx = particles[index].cx;
		cy = particles[index].cy;
		cx += sin(particles[index].ct * particles[index].waveFreq * 2 * pi) * particles[index].waveAmplitude;
		c.setPos(cx, cy);

		// Draw particle sprite.
		c.drawColor = particles[index].col;
		sprite = sprites[particles[index].spriteNum];
		c.drawTile(sprite, sprite.uSize, sprite.vSize, 0, 0, sprite.uSize, sprite.vSize);
	}
	/* Draw Lights (Looked stupid, removed)
	baseX = 0;
	baseY = c.clipY / 2;
	
	c.style = ERenderStyle.STY_Normal;
	c.drawColor = BaseColor;

	c.setPos(baseX, baseY);
	c.drawTile(Texture'lights', lightsTextureWidth, lightsTextureHeight, 0.0, 0.0, lightsTextureWidth, lightsTextureHeight);*/
	
	if (SCTFGame.bXmasImages) // whether to display the Sexy Xmas images! :D
	{
    // Draw Santa
	  baseX = c.clipX - santaTextureWidth - 16;
	  baseY = c.clipY - santaTextureHeight - 16;
	
    c.style = ERenderStyle.STY_Normal;
    c.drawColor = BaseColor;
  
	  c.setPos(baseX, baseY);
    c.drawTile(Texture'santa', santaTextureWidth, santaTextureHeight, 0.0, 0.0, santaTextureWidth, santaTextureHeight);
  
    // Draw presents
	  baseX = 16;
	  baseY = c.clipY - presentTextureHeight - 16;
	
	  c.style = ERenderStyle.STY_Normal;
    c.drawColor = BaseColor;
  
	  c.setPos(baseX, baseY);
	  c.drawTile(Texture'present', presentTextureWidth, presentTextureHeight, 0.0, 0.0, presentTextureWidth, presentTextureHeight);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Updates the positions of the snow particles.
 *  $PARAM        c  The canvas on which the rendering should be performed.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function updateSnow(Canvas c) {
	local float deltaTime;
	local int index;

	// Prepare for update.
	setupScalars(c);
	if (!bSnowInitialized) {
		initializeSnow(c);
	}
	deltaTime = fMin(0.5, level.timeSeconds - lastUpdateTime);

	// Move each particle.
	for (index = 0; index < arrayCount(particles); index++) {
		particles[index].cx += particles[index].dx * deltaTime;
		particles[index].cy += particles[index].dy * deltaTime;
		particles[index].ct += deltaTime / level.timeDilation;

		// Check if particle has left the screen.
		if (particles[index].cy > c.clipY) {
			// It has, reset particle.
			initializeParticle(index, c, true);
		}
	}
	lastUpdateTime = level.timeSeconds;
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes all snow particles.
 *  $PARAM        c  The canvas on which the rendering should be performed.
 *  $REQUIRE      c != none
 *  $ENSURE       bSnowInitialized
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function initializeSnow(Canvas c) {
	local int index;
	bSnowInitialized = true;

	// Initialize each particle.
	for (index = 0; index < arrayCount(particles); index++) {
		initializeParticle(index, c);
	}
	lastUpdateTime = level.timeSeconds;
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the specified particle.
 *  $PARAM        index   The particle that is to be initialized.
 *  $PARAM        c       The canvas on which the rendering should be performed.
 *  $PARAM        bReset  Reset particle to the top of the screen.
 *  $REQUIRE      0 <= index && index <= arrayCount(particles) && c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function initializeParticle(int index, Canvas c, optional bool bReset) {
	particles[index].spriteNum = rand(arrayCount(sprites));
	particles[index].cx = fRand() * c.clipX;
	if (bReset) {
		particles[index].cy = -sprites[particles[index].spriteNum].vSize;
	} else {
		particles[index].cy = fRand() * c.clipY;
	}
	particles[index].ct = 0.0;
	particles[index].dx = fRand() * (maxDX - minDX) + minDX;
	particles[index].dy = fRand() * (maxDY - minDY) + minDY;
	particles[index].waveFreq = fRand() * (maxWaveFreq - minWaveFreq) + minWaveFreq;
	particles[index].waveAmplitude = fRand() * (maxWaveAmplitude - minWaveAmplitude) + minWaveAmplitude;
	particles[index].waveFreq *= particles[index].dy / maxDY;
	particles[index].waveAmplitude *= particles[index].dy / maxDY;

	if (level.month == 12 && level.day == 24 || level.month == 12 && level.day == 25 || level.month == 12 && level.day == 31 || level.month == 1 && level.day == 1) {
		particles[index].col.r = rand(256);
		particles[index].col.g = rand(256);
		particles[index].col.b = rand(256);
	} else {
		particles[index].col = baseColor * (fRand() * (maxGlow - minGlow) + minGlow);
	}
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Computes the absolute values of the scaled settings.
 *  $PARAM        c  The canvas on which the rendering should be performed.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function setupScalars(Canvas c) {
	minDX = scaleMinDX / scaleWidth * c.clipX;
	maxDX = scaleMaxDX / scaleWidth * c.clipX;
	minDY = scaleMinDY / scaleHeight * c.clipY;
	maxDY = scaleMaxDY / scaleHeight * c.clipY;
	minWaveAmplitude = scaleMinWaveAmplitude / scaleWidth * c.clipX;
	maxWaveAmplitude = scaleMaxWaveAmplitude / scaleWidth * c.clipX;
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     BaseColor=(R=255,G=255,B=255)
     sprites(0)=Texture'SmartCTF_4E.snowFlake1'
     sprites(1)=Texture'SmartCTF_4E.snowFlake2'
     sprites(2)=Texture'SmartCTF_4E.snowFlake3'
     sprites(3)=Texture'SmartCTF_4E.snowFlake4'
     sprites(4)=Texture'SmartCTF_4E.snowFlake5'
     sprites(5)=Texture'SmartCTF_4E.snowFlake6'
     sprites(6)=Texture'SmartCTF_4E.snowFlake7'
     sprites(7)=Texture'SmartCTF_4E.snowFlake8'
     sprites(8)=Texture'SmartCTF_4E.snowFlake9'
     sprites(9)=Texture'SmartCTF_4E.snowFlake10'
     sprites(10)=Texture'SmartCTF_4E.snowFlake11'
     sprites(11)=Texture'SmartCTF_4E.snowFlake12'
     sprites(12)=Texture'SmartCTF_4E.snowFlake13'
     sprites(13)=Texture'SmartCTF_4E.snowFlake14'
     sprites(14)=Texture'SmartCTF_4E.snowFlake15'
     sprites(15)=Texture'SmartCTF_4E.snowFlake16'
}
