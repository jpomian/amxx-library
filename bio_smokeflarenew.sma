#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <csx>
#include <fun>

#define VERSION			"0.1.0d"

#define FBitSet(%0,%1)		( %0 |= ( 1 << ( %1 & 31 ) ) )
#define FBitClear(%0,%1)	( %0 &= ~( 1 << ( %1 & 31 ) ) )
#define FBitGet(%0,%1)		( %0 & ( 1 << ( %1 & 31 ) ) )

#define XO_WEAPON		4
#define m_flNextPrimaryAttack	46
#define m_flNextSecondaryAttack	47
#define m_fGrenadeInfo		96
#define m_usEvent		114

#define pev_flare pev_iuser4
#define flare_id 1337
#define is_ent_flare(%1) (pev(%1, pev_flare) == flare_id) ? 1 : 0

#define EVENT_SMOKE		26

#define CGINFO_HE		( 1 << 0 )
#define CGINFO_SMOKE		( 1 << 1 )

new const g_szSndFlare[] = "flareon.wav";

enum _:Sprites
{
	SPRITE_SMOKE,
	SPRITE_CYLINDER,
	SPRITE_FLARE,
	SPRITE_BEAM3
}

new g_iSprites[ Sprites ];

new const g_iColours[][ 3 ] = 
{
	{ 255, 0, 0 },
	{ 0, 0, 255 },
	{ 0, 255, 0 },
	{ 255, 255,0 },
	{ 255, 0, 255 },
	{ 0, 255, 128 },
	{ 255, 128, 0 },
	{ 255, 255, 255 }
}

new _pfnEmitSound;

new g_pFlareRadius;

public plugin_precache()
{
	precache_sound( g_szSndFlare );
	
	
	g_iSprites[ SPRITE_SMOKE ] = precache_model( "sprites/black_smoke4.spr" );
	g_iSprites[ SPRITE_CYLINDER ] = precache_model( "sprites/white.spr" );
	g_iSprites[ SPRITE_FLARE ] = precache_model( "sprites/3dmflaora.spr" );
	g_iSprites[ SPRITE_BEAM3 ] = precache_model( "sprites/_flare_1.spr" );
}

public plugin_init()
{
	register_plugin( "Grenade Effects", VERSION, "hornet" );
	
	g_pFlareRadius		= register_cvar( "ge_flare_radius", "35" );
	
	register_touch( "worldspawn", "grenade", "CGrenade_Touch" );

	register_forward(FM_Think, "fwd_think")
}

public CGrenade_Touch( iTouched, iEnt )
{
	if( !get_pdata_int( iEnt, m_usEvent, XO_WEAPON ) )
	{
		if( pev( iEnt, pev_flags ) & FL_ONGROUND && !pev( iEnt, pev_iuser2 ) )
		{
			set_pev( iEnt, pev_iuser2 );
			
			new iColour[ 3 ];
			GetColourRGB( pev( iEnt, pev_iuser1 ), iColour );
			
			set_rendering( iEnt, kRenderFxGlowShell, iColour[ 0 ], iColour[ 1 ], iColour[ 2 ], kRenderNormal, 16 );
			
			FlareExplode( iEnt );
			Unregister( iEnt, CSW_FLASHBANG );
		}
	}
}

public FlareExplode( iEnt )
{
	if( pev_valid( iEnt ) )	set_task( 5.0, "FlareExplode", iEnt );
	else 	return;
			
	new iColour[ 3 ];
	GetColourRGB( pev( iEnt, pev_iuser1 ), iColour );
		
	UTIL_DLight( iEnt, 25, iColour[ 0 ], iColour[ 1 ], iColour[ 2 ], 51, 0 );
}

	/*---------------------------------|
	|	Engine Forwards		   |
	|---------------------------------*/

public grenade_throw( id, iEnt, iWeapon )
{
	switch( iWeapon )
	{	
		case CSW_FLASHBANG:
		{	
			emit_sound( iEnt, CHAN_AUTO, g_szSndFlare, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			
			new iRand = random_num( 0, sizeof g_iColours - 1 );
			UTIL_BeamFollow( iEnt, g_iSprites[ SPRITE_BEAM3 ], get_pcvar_num( g_pFlareRadius ), 10, g_iColours[ iRand ][ 0 ], g_iColours[ iRand ][ 1 ], g_iColours[ iRand ][ 2 ], 255 );
			
			set_pev( iEnt, pev_iuser1, GetColourTrue( g_iColours[ iRand ] ) );
				
			set_pev( iEnt, pev_dmgtime, 9999.0 );

			static classname[32]; pev(iEnt, pev_classname, classname, 31)
			if(equal(classname, "grenade"))
			{
				set_pev(iEnt, pev_flare,   flare_id)
				set_pev(iEnt, pev_nextthink, get_gametime() + 90.0)
			}
		}
	}
}
public fwd_think(ent)
{
	if(!pev_valid(ent))
		return PLUGIN_HANDLED;

	if(pev_valid(ent) && is_ent_flare(ent))
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}

	return PLUGIN_CONTINUE;

}
public pfnEmitSound( iEnt, iChannel, szSound[] )
{
	if( equal( szSound, "weapons/debris1.wav" ) || equal( szSound, "weapons/debris2.wav" ) || equal( szSound, "weapons/debris3.wav" ) )
	{
	
		new Float:vOrigin[ 3 ];
		pev( iEnt, pev_origin, vOrigin );
			
		vOrigin[ 2 ] -= 32.0;
		set_pev( iEnt, pev_origin, vOrigin );
			
		UTIL_Smoke( iEnt, g_iSprites[ SPRITE_SMOKE ], 30, 30 );
		UTIL_Smoke( iEnt, g_iSprites[ SPRITE_SMOKE ], 15, 25 );
			
		UTIL_DLight( iEnt, 80, 255, 128, 0, 50, 40 );
		UTIL_BeamCylinder( iEnt, g_iSprites[ SPRITE_CYLINDER ], 0, 6, 20, 255, 255, 128, 0, 255, 0 );
		UTIL_SpriteTrail( iEnt, g_iSprites[ SPRITE_FLARE ], 15, 3, 3, 50, 0 );
		
		Unregister( iEnt, CSW_HEGRENADE );
	}
	
	return FMRES_IGNORED;
}

	/*---------------------------------|
	|		Stocks		   |
	|---------------------------------*/

GetColourRGB( iColour, iOut[ 3 ] )
{
	iOut[ 0 ] = ( iColour >> 16 ) & 0xFF;
	iOut[ 1 ] = ( iColour >> 8 ) & 0xFF;
	iOut[ 2 ] = iColour & 0xFF;
}

GetColourTrue( RGB[ 3 ] )
{
	new iColour;
	
	iColour = RGB[ 0 ];
	iColour = ( iColour << 8 ) + RGB[ 1 ];
	iColour = ( iColour << 8 ) + RGB[ 2 ];
	
	return iColour;
}
Unregister( iEnt, iWeapon )
{
	new jEnt;

	while( ( jEnt = find_ent_by_class( jEnt, "grenade" ) ) )
	{
		if( jEnt == iEnt )
			continue;
		
		//Bits = get_pdata_int( m_usEvent, jEnt, XO_WEAPON );

	}
	
	if( !iEnt )
	{
		unregister_forward( FM_EmitSound, _pfnEmitSound );
		_pfnEmitSound = 0;
	}
}
	
UTIL_BeamCylinder( iEnt, iSprite, iFramerate, iLife, iWidth, iAmplitude, iRed, iGreen, iBlue, iBright, iSpeed )
{
	new Float:vOrigin[ 3 ];
	pev( iEnt, pev_origin, vOrigin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMCYLINDER );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 10 );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] + 400 );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 400 );
	write_short( iSprite );
	write_byte( 0 );
	write_byte( iFramerate );
	write_byte( iLife );
	write_byte( iWidth );
	write_byte( iAmplitude );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( iBright );
	write_byte( iSpeed );
	message_end();
}
	
UTIL_BeamFollow( iEnt, iSprite, iLife, iWidth, iRed, iGreen, iBlue, iBright )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( iEnt );
	write_short( iSprite );
	write_byte( iLife );
	write_byte( iWidth );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( iBright );
	message_end();
}

UTIL_DLight( iEnt, iRadius, iRed, iGreen, iBlue, iLife, iDecay )
{
	new Float:vOrigin[ 3 ];
	pev( iEnt, pev_origin, vOrigin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_DLIGHT );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
	write_byte( iRadius );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( iLife );
	write_byte( iDecay );
	message_end();
}

UTIL_SpriteTrail( iEnt, iSprite, iCount, iLife, iScale, iVelocity, iVary )
{
	new Float:vOrigin[ 3 ];
	pev( iEnt, pev_origin, vOrigin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SPRITETRAIL );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 100 );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] + random_float( -200.0, 200.0 ) );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] + random_float( -200.0, 200.0 ) );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
	write_short( iSprite );
	write_byte( iCount );
	write_byte( iLife );
	write_byte( iScale );
	write_byte( iVelocity );
	write_byte( iVary );
	message_end();
}

UTIL_Smoke( iEnt, iSprite, iScale, iFramerate )
{
	new Float:vOrigin[ 3 ];
	pev( iEnt, pev_origin, vOrigin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SMOKE );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
	write_short( iSprite );
	write_byte( iScale );
	write_byte( iFramerate );
	message_end();
}