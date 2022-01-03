#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <colorchat>

#define DMG_HEGRENADE (1<<24)

public plugin_init()
{
	register_plugin("x", "1.0", "");

	RegisterHam(Ham_TakeDamage, "func_breakable", "TakeDamage");
}

public TakeDamage(this, attacker, inflictor, Float: damage, damagegibs)
{
    new Float:health;
    new name[33]
    pev(this, pev_health, health);
    get_user_name(attacker, name, sizeof(name))

    //if(damagegibs & DMG_HEGRENADE)
      //return HAM_IGNORED;

    if (health - damage <= 0.0 && attacker != 0 && is_user_alive(attacker))
    {
		  ColorChat(0, GREEN, "[ZM]^x03 %s^x01 zniszczyl kladke", name)
    }
}