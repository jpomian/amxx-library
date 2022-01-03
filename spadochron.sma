#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

native is_user_zombie(id)

#define _PLUGIN         "[Bio] Parachute"
#define _VERSION             "1.6"
#define _AUTHOR           "H.RED.ZONE + mixtaz"

#define PARACHUTE_MODEL_CT "models/biohazard/umbrellaparachute.mdl"
#define PARACHUTE_MODEL_ZOMBIE "models/biohazard/skrzydla.mdl"

#define MAX_PLAYERS    32

#define MarkUserHasParachute(%0)	g_bitHasParachute |= (1<<(%0&31))
#define ClearUserHasParachute(%0)	g_bitHasParachute &= ~(1<<(%0&31))
#define HasUserParachute(%0)		g_bitHasParachute & (1<<(%0&31))

new g_bitHasParachute 

new g_iUserParachute[MAX_PLAYERS+1]

new Float:g_flEntityFrame[MAX_PLAYERS+1]

new g_iModelIndexCT,
	g_iModelIndexZM;
new g_pCvarFallSpeed

new const PARACHUTE_CLASS[] = "parachute"

enum {
	deploy,
	idle,
	detach
}

public plugin_init() {
	register_plugin(_PLUGIN, _VERSION, _AUTHOR)

	g_pCvarFallSpeed = register_cvar("parachute_fallspeed", "100")

	register_forward( FM_CmdStart, "fw_Start" )
	
	RegisterHam(Ham_Spawn, "player", "Ham_CBasePlayer_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "Ham_CBasePlayer_Killed_Post", 1)
}

public plugin_precache() {
	g_iModelIndexCT = precache_model(PARACHUTE_MODEL_CT)
	g_iModelIndexZM = precache_model(PARACHUTE_MODEL_ZOMBIE)
}

public client_putinserver(id) {
	if( HasUserParachute(id) ) {
		new iEnt = g_iUserParachute[id]
		if( iEnt ) {
			RemoveUserParachute(id, iEnt)
		}
		ClearUserHasParachute(id)
	}
}

public client_disconnected(id) {
	if( HasUserParachute(id) ) {
		new iEnt = g_iUserParachute[id]
		if( iEnt ) {
			RemoveUserParachute(id, iEnt)
		}
		ClearUserHasParachute(id)
	}
}

public Ham_CBasePlayer_Killed_Post( id ) {
	if( HasUserParachute(id) ) {
		new iEnt = g_iUserParachute[id]
		if( iEnt ) {
			RemoveUserParachute(id, iEnt)
		}
		ClearUserHasParachute(id)
	}
}

public Ham_CBasePlayer_Spawn_Post(id) {
	if( is_user_alive(id) ) {
		if( HasUserParachute(id) ) {
			new iEnt = g_iUserParachute[id]
			if( iEnt ) {
				RemoveUserParachute(id, iEnt)
			}
		}
		MarkUserHasParachute(id)
	}
}

RemoveUserParachute(id, iEnt) {
	engfunc(EngFunc_RemoveEntity, iEnt)
	g_iUserParachute[id] = 0
}

CreateParachute(id) {
	static iszInfoTarget
	if( !iszInfoTarget ) {
		iszInfoTarget = engfunc(EngFunc_AllocString, "info_target")
	}

	new iEnt = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget)
	if( iEnt > 0) {
		static iszClass = 0
		if( !iszClass ) {
			iszClass = engfunc(EngFunc_AllocString, PARACHUTE_CLASS)
		}
		set_pev_string(iEnt, pev_classname, iszClass)
		set_pev(iEnt, pev_aiment, id)
		set_pev(iEnt, pev_owner, id)
		set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)

		static iszModel = 0
		if( !iszModel ) {
			iszModel = engfunc(EngFunc_AllocString, is_user_zombie(id) ? PARACHUTE_MODEL_ZOMBIE : PARACHUTE_MODEL_CT)
		}
		set_pev_string(iEnt, pev_model, iszModel)
		set_pev(iEnt, pev_modelindex, is_user_zombie(id) ? g_iModelIndexZM : g_iModelIndexCT)

		set_pev(iEnt, pev_sequence, deploy)
		set_pev(iEnt, pev_gaitsequence, 1)
		set_pev(iEnt, pev_frame, 0.0)
		
		/*set_pev(iEnt, pev_rendermode, pev(id, pev_rendermode));
		set_pev(iEnt, pev_renderfx, pev(id, pev_renderfx));
		new Float:f_renderamt;
		pev(id, pev_renderamt, f_renderamt);
		set_pev(iEnt, pev_renderamt, f_renderamt);*/
		
		g_flEntityFrame[id] = 0.0
		g_iUserParachute[id] = iEnt
		MarkUserHasParachute(id)
		new Float:fVecOrigin[3]
		pev(id, pev_origin, fVecOrigin)
		
		return iEnt
	}
	return 0
}

public fw_Start(id) {
	if( ~HasUserParachute(id) || !is_user_alive(id) ) {
		return
	}

	new Float:flFrame
	new iEnt = g_iUserParachute[id]

	if(iEnt > 0 && pev(id, pev_flags) & FL_ONGROUND) {

		if( pev(iEnt, pev_sequence) != detach ) {
			set_pev(iEnt, pev_sequence, detach)
			set_pev(iEnt, pev_gaitsequence, 1)
			set_pev(iEnt, pev_frame, 0.0)
			g_flEntityFrame[id] = 0.0
			set_pev(iEnt, pev_animtime, 0.0)
			set_pev(iEnt, pev_framerate, 0.0)
			return
		}

		pev(iEnt, pev_frame, flFrame)
		if( flFrame > 252.0 ) {
			RemoveUserParachute(id, iEnt)
			return
		}

		flFrame += 2.0

		g_flEntityFrame[id] = flFrame
		set_pev(iEnt, pev_frame, flFrame)

		return
	}

	if( pev(id, pev_button) & IN_USE ) {
		new Float:fVecVelocity[3], Float:fVelocity_z
		pev(id, pev_velocity, fVecVelocity)
		fVelocity_z = fVecVelocity[2]

		if( fVelocity_z < 0.0 ) {
			if(iEnt <= 0) {
				iEnt = CreateParachute(id)
			}

			fVelocity_z = floatmin(fVelocity_z + 15.0, -get_pcvar_float(g_pCvarFallSpeed))
			fVecVelocity[2] = fVelocity_z
			set_pev(id, pev_velocity, fVecVelocity)

			if( pev(iEnt, pev_sequence) == deploy ) {
				flFrame = g_flEntityFrame[id]++

				if( flFrame > 100.0 ) {
					set_pev(iEnt, pev_animtime, 0.0)
					set_pev(iEnt, pev_framerate, 0.4)
					set_pev(iEnt, pev_sequence, idle)
					set_pev(iEnt, pev_gaitsequence, 1)
					set_pev(iEnt, pev_frame, 0.0)
					g_flEntityFrame[id] = 0.0
				}
				else {
					set_pev(iEnt, pev_frame, flFrame)
				}
			}
		}
		else if(iEnt > 0) {
			RemoveUserParachute(id, iEnt)
		}
	}
	else if( iEnt > 0 && pev(id, pev_oldbuttons) & IN_USE ) {
		RemoveUserParachute(id, iEnt)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
