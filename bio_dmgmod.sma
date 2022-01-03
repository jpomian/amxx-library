#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <biohazard>



#define PLUGIN "More knife"

#define VERSION "1.0"

#define AUTHOR "peku33"

#define DMG_HEGRENADE (1<<24)

public plugin_init()

{

	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage")

}



public TakeDamage(victim, entity, attacker, Float:damage, damagebits)

{
	if(!is_user_connected(attacker) || !is_user_connected(victim))

		return HAM_IGNORED;



	if(get_user_team(attacker) == 2)

	{
		if(get_user_weapon(attacker) == CSW_KNIFE && pev(attacker,pev_button) & IN_ATTACK2) {

		SetHamParamFloat(4, 400.0);


		return HAM_HANDLED;

		}

		if(damagebits & DMG_HEGRENADE) {
			damage*=6.0;
		}
		
	}

        return HAM_IGNORED;

}