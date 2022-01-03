#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <biohazard>

native give_user_knockbackimmunity(id, Float:time)

// Default sounds
new const sound_zombie_madness[] = "zombie/zombie_szalony.wav"

#define TASK_MADNESS 100
#define TASK_AURA 200
#define ID_MADNESS (taskid - TASK_MADNESS)
#define ID_AURA (taskid - TASK_AURA)

#define DMG_GRENADE    (1 << 24)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MadnessBlockDamage
new cvar_zombie_madness_time

public plugin_init()
{
	register_plugin("[ZP] Item: Zombie Madness", "0.1", "ZP Dev Team")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	
	cvar_zombie_madness_time = register_cvar("zp_zombie_madness_time", "5.0")
}
public plugin_precache()
{
	precache_sound(sound_zombie_madness);
}

public plugin_natives()
{
	register_native("get_user_zombiemadness", "SzalonyPost", 1)
}
public SzalonyPre(id)
{
	// Zombie madness only available to zombies
	if (!is_user_zombie(id))
		return PLUGIN_CONTINUE

	// Player already has madness
	if (flag_get(g_MadnessBlockDamage, id))
		return PLUGIN_CONTINUE
	

	return PLUGIN_CONTINUE;
}

public SzalonyPost(id)
{
	// Do not take damage
	flag_set(g_MadnessBlockDamage, id)
	
	//set_user_godmode(id, 1);

	// Madness aura
	set_task(0.1, "madness_aura", id+TASK_AURA, _, _, "b")
	
	// Madness sound
	emit_sound(id, CHAN_VOICE, sound_zombie_madness, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Set task to remove it
	set_task(get_pcvar_float(cvar_zombie_madness_time), "remove_zombie_madness", id+TASK_MADNESS)

	give_user_knockbackimmunity(id, get_pcvar_float(cvar_zombie_madness_time))
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove zombie madness from a previous round
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, id)
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when victim has zombie madness
	if(flag_get(g_MadnessBlockDamage, victim) && damagebits & ~DMG_GRENADE)
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when victim has zombie madness
	if (flag_get(g_MadnessBlockDamage, victim))
	{
		if(damagebits & ~DMG_GRENADE)
			return HAM_SUPERCEDE;
			
		if(damagebits & DMG_GRENADE)
			SetHamParamFloat(4, 1.0)
	}
	
	return HAM_IGNORED;
}
// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Remove zombie madness task
	remove_task(victim+TASK_MADNESS)
	remove_task(victim+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, victim)
}

// Remove Spawn Protection Task
public remove_zombie_madness(taskid)
{
	// Remove aura
	remove_task(ID_MADNESS+TASK_AURA)
	
	// Remove zombie madness
	flag_unset(g_MadnessBlockDamage, ID_MADNESS)

	//set_user_godmode(ID_MADNESS, 0)


	new origin[3]
	get_user_origin(ID_MADNESS, origin)

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_PARTICLEBURST) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_short(50) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()
}

public client_disconnected(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_MADNESS)
	remove_task(id+TASK_AURA)
	flag_unset(g_MadnessBlockDamage, id)
}

// Madness aura task
public madness_aura(taskid)
{
	if(is_user_alive(ID_AURA) && is_user_connected(ID_AURA)){
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(15) // radius
	write_byte(150) // r
	write_byte(0) // g
	write_byte(0) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
	}
}
