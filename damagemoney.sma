#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <biohazard>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"
#define DAMAGE 500
#define MONEY 15

#define VIP ADMIN_LEVEL_H
#define VIP_PLUS ADMIN_LEVEL_G

new Float:damage_given[33];

public plugin_init()
{
	register_plugin("x", "v0.1", AUTHOR);

	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", true);
}

public TakeDamage(victim, idinflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(attacker) || !is_user_connected(victim) || !damage)
	{
		return;
	}

	new required = DAMAGE;

	damage_given[attacker] += damage;

	if(get_user_team(attacker) != get_user_team(victim) && is_user_zombie(victim) && !is_user_zombie(attacker))
	{
	while(damage_given[attacker] >= required)
	{
		damage_given[attacker] -= required;

		new money = cs_get_user_money( attacker )
		new rewardedMoney = MONEY
			
		if(get_user_flags( attacker ) & VIP)
			rewardedMoney *= 2
		
		cs_set_user_money( attacker, min(money + rewardedMoney, 20000 ), 1 )
	}
	}
}