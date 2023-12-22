#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <engine>

#define VERSION "1.0"

#define write_coord_f(%1) engfunc(EngFunc_WriteCoord,%1)
#define IsPlayer(%1) (1 <= %1 <= g_iMaxPlayers)

new const g_szSmokeClassName[] = "deathsmoke_effect"
new const g_szSmokeSound[] = "weapons/sg_explode.wav"

new g_iMaxPlayers, g_iTeam, 
	g_szSmokeSprites[ 3 ], g_iSmokeEntity[ 33 ], 
	Float:g_flDeathGametime[ 33 ]

 //Cvars
new g_pCvar_Enabled, 
	g_pCvar_Size, g_iSpriteSize,
	g_pCvar_Sound, g_iSpriteSound,
	g_pCvar_Color, g_iSpriteColor,
	g_pCvar_Team, g_iSpriteTeam,
	g_pCvar_Admins, g_iSpriteAdmins,
	g_pCvar_RemoveSmoke, Float:g_iSpriteRemoveSpeed

public plugin_precache ()
{
	g_szSmokeSprites[ 0 ] = precache_model( "sprites/steam1.spr" )
	g_szSmokeSprites[ 1 ] = precache_model( "sprites/gas_puff_01r.spr" )
	g_szSmokeSprites[ 2 ] = precache_model( "sprites/gas_puff_01b.spr" )
	
	precache_sound( g_szSmokeSound )
}

public plugin_init() {
	register_plugin( "Smoke Death", VERSION, "Pastout" )
	
	register_cvar( "Smoke_Death", VERSION, FCVAR_SERVER | FCVAR_SPONLY )
	set_cvar_string( "Smoke_Death", VERSION )
	
	register_event( "DeathMsg", "Event_PlayerKilled", "a" )
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0" )
	
	g_pCvar_Enabled = register_cvar("deathsmoke_enable", "1")// 1 = on || 0 = off
	if ( !get_pcvar_num( g_pCvar_Enabled ) )
		return;
		
	g_pCvar_Size = register_cvar("deathsmoke_size", "80") //Sprite Size
	g_pCvar_Sound = register_cvar("deathsmoke_sound", "0") //Sound 1 = on || 0 = off
	g_pCvar_Color = register_cvar("deathsmoke_color", "2") //Color 0 = Grey || 1 = TeamColor || 2 = Red || 3 = Blue || 4 = random Color || 5 - Killers Color
	g_pCvar_Team = register_cvar("deathsmoke_team", "1") //Teams 0 = Nobody || 1 = T's only || 2 = CT's only || 3 = Everyone
	g_pCvar_Admins = register_cvar("deathsmoke_adminsonly", "0") //Everyone 0 = All || 1 = Admins Only
	g_pCvar_RemoveSmoke = register_cvar("deathsmoke_time", "8.0") //How long the smoke stays before it goes away! ( 1=FAST || 15 = SLOW )
	
	register_think( g_szSmokeClassName, "FwdSmokeThink" )
	g_iMaxPlayers = get_maxplayers()
}

/* Thanks To Exolent i understand deathmsg event alot better! */
public Event_PlayerKilled ()
{
	new killer = read_data( 1 )
	new victim = read_data( 2 )
	
	if( !IsPlayer( killer ) )
	{
		return PLUGIN_HANDLED
	}
	
	new CsTeams:Team, CsTeams:Teamkiller
	
	Team = cs_get_user_team( victim )
	Teamkiller = cs_get_user_team( killer )
	
	if( g_iSpriteColor == 1 )
	{
		switch( Team )
		{
			case CS_TEAM_CT:	g_iTeam = 2
			case CS_TEAM_T:		g_iTeam = 1
			case CS_TEAM_SPECTATOR:	g_iTeam = 0
		}
	}
	if( g_iSpriteColor == 5 )
	{
		switch( Teamkiller )
		{
			case CS_TEAM_CT:	g_iTeam = 2
			case CS_TEAM_T:		g_iTeam = 1
			case CS_TEAM_SPECTATOR:	g_iTeam = 0
		}
	}
	if( !is_user_admin( victim ) && g_iSpriteAdmins == 1 )
	{
		return PLUGIN_HANDLED
	}	
	if( ~g_iSpriteTeam & _:Team ) 
	{ 
		return PLUGIN_HANDLED
	} 	
	
	//Initialize Variables
	static Float:vf_Origin[ 3 ]
	
	//Create Smoke Effect
	new i_SmokeEffect = g_iSmokeEntity[victim] = create_entity( "info_target" ) 
	g_flDeathGametime[victim] = get_gametime() + g_iSpriteRemoveSpeed 
	
	if( !is_valid_ent( i_SmokeEffect ) )
		return PLUGIN_HANDLED
		
	entity_set_string( i_SmokeEffect, EV_SZ_classname, g_szSmokeClassName )	//Set the class name to deathsmoke_effect
	pev( read_data( 2 ), pev_origin,  vf_Origin )				//Get the victim's index. / Retrieve the current victim's origin
	set_pev ( i_SmokeEffect, pev_origin, vf_Origin )				//Set the entity to the current player's origin and spawn it!
	entity_set_float( i_SmokeEffect, EV_FL_nextthink, get_gametime( ) + 0.5 )//Set the think time

	if( g_iSpriteSound > 0 )	//Sound 1 = On 0 = Off
	{
		//Add Sound Yea
		emit_sound( i_SmokeEffect, CHAN_STATIC, g_szSmokeSound, 1.0, ATTN_NORM, 0, PITCH_NORM )
	}

	return PLUGIN_HANDLED
}

GetSmokeOwner( i_SmokeEffect ) 
{ 
	for(new id = 1; id<=g_iMaxPlayers; id++) 
	{ 
		if( g_iSmokeEntity[id] == i_SmokeEffect ) 
		{ 
			return id 
		} 
	} 
	return 0 
}

public FwdSmokeThink( i_SmokeEffect ) 
{ 
	if( !is_valid_ent( i_SmokeEffect ) )
		return
	new id = GetSmokeOwner( i_SmokeEffect ) 
	if( !id ) 
	{ 
		remove_entity( i_SmokeEffect ) 
		return 
	} 

	new Float:flGameTime = get_gametime() 
	if( flGameTime > g_flDeathGametime[ id ] ) 
	{ 
		remove_entity( i_SmokeEffect ) 
		g_iSmokeEntity[id] = 0 
		return 
	} 
	
	UTIL_Smoke( i_SmokeEffect ) 
	
	entity_set_float( i_SmokeEffect, EV_FL_nextthink, flGameTime + 0.4 ) 
	return
}  


UTIL_Smoke( const i_SmokeEffect )
{
	new Float:vf_Origin[ 3 ]	
	entity_get_vector( i_SmokeEffect, EV_VEC_origin, vf_Origin )
	
	switch( g_iSpriteColor )
	{
		case 0: 
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_SMOKE );
			write_coord_f( vf_Origin[ 0 ] )
			write_coord_f( vf_Origin[ 1 ] )
			write_coord_f( vf_Origin[ 2 ] )
			write_short( g_szSmokeSprites[ 0 ] )
			write_byte( g_iSpriteSize )
			write_byte( 10 )
			message_end( )
		}
		case 1:
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_FIREFIELD )
			write_coord_f( vf_Origin[ 0 ] )
			write_coord_f( vf_Origin[ 1 ] )
			write_coord_f( vf_Origin[ 2 ] )
			write_short( g_iSpriteSize )
			write_short( g_szSmokeSprites[ g_iTeam ] )
			write_byte( 5 )
			write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT )
			write_byte( g_iSpriteSize )
			message_end( )
		}
		case 2:
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_FIREFIELD )
			write_coord_f( vf_Origin[ 0 ] )
			write_coord_f( vf_Origin[ 1 ] )
			write_coord_f( vf_Origin[ 2 ] )
			write_short( g_iSpriteSize )
			write_short( g_szSmokeSprites[ 1 ] )
			write_byte( 5 )
			write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT )
			write_byte( g_iSpriteSize )
			message_end( )
		}
		case 3:
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_FIREFIELD )
			write_coord_f( vf_Origin[ 0 ] )
			write_coord_f( vf_Origin[ 1 ] )
			write_coord_f( vf_Origin[ 2 ] )
			write_short( g_iSpriteSize )
			write_short( g_szSmokeSprites[ 2 ] )
			write_byte( 5 )
			write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT )
			write_byte( g_iSpriteSize )
			message_end( )
		}
		case 4:
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_FIREFIELD )
			write_coord_f( vf_Origin[ 0 ] )
			write_coord_f( vf_Origin[ 1 ] )
			write_coord_f( vf_Origin[ 2 ] )
			write_short( g_iSpriteSize )
			write_short( g_szSmokeSprites[ random_num( 0, 2 ) ] )
			write_byte( 5 )
			write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT )
			write_byte( g_iSpriteSize )
			message_end( )
		}
		case 5:
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_FIREFIELD )
			write_coord_f( vf_Origin[ 0 ] )
			write_coord_f( vf_Origin[ 1 ] )
			write_coord_f( vf_Origin[ 2 ] )
			write_short( g_iSpriteSize )
			write_short( g_szSmokeSprites[ g_iTeam ] )
			write_byte( 5 )
			write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT )
			write_byte( g_iSpriteSize )
			message_end( )
		}
	}
	
}

public Event_NewRound() {
	//The Cvar wont take affect intill round start...
	g_iSpriteSize = get_pcvar_num(g_pCvar_Size)
	g_iSpriteSound = get_pcvar_num(g_pCvar_Sound)
	g_iSpriteColor = get_pcvar_num(g_pCvar_Color)
	g_iSpriteTeam = get_pcvar_num(g_pCvar_Team)
	g_iSpriteAdmins = get_pcvar_num(g_pCvar_Admins)
	g_iSpriteRemoveSpeed = get_pcvar_float(g_pCvar_RemoveSmoke)
	
	//Remove all Smoke Effect Entities at round End
	remove_entity_name(g_szSmokeClassName)
}
