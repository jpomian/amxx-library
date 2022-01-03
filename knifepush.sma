#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <biohazard>

new CvarPower, CvarHeight

public plugin_init()
{
	register_plugin("ZP Knife Knock Back", "0.0.1", "wbyokomo")
	
	CvarPower = register_cvar("kb_power","300")
	CvarHeight = register_cvar("kb_height","50")
	
	RegisterHam(Ham_TakeDamage, "player", "OnTakeDamagePost", 1)
}

//a forward from CSBot_Init API
public CSBot_Init(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "OnTakeDamagePost", 1)
}

public OnTakeDamagePost(victim, inflictor, attacker/*, Float:damage, dmgtype*/)
{
	if(victim == attacker) return HAM_IGNORED; //self damage
	if(inflictor != attacker) return HAM_IGNORED; //prevent from other damage like bazooka, tripmine we need knife damage only
	if(!is_user_connected(attacker)) return HAM_IGNORED; //non-player damage
	if(get_user_weapon(attacker) != CSW_KNIFE) return HAM_IGNORED; //current weapon is not knife
	

	if(is_user_zombie(victim) && is_user_zombie(attacker))
	{
		if (pev(attacker,pev_button) & IN_ATTACK2)
		{
			static Float:fVelocity[3]
			velocity_by_aim(attacker, get_pcvar_num(CvarPower), fVelocity)
			fVelocity[2] = get_pcvar_float(CvarHeight)
			set_pev(victim, pev_velocity, fVelocity)
		}
	}
	
	return HAM_IGNORED;
}
