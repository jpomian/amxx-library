#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <biohazard>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#define VIP ADMIN_LEVEL_H
#define VIP_PLUS ADMIN_LEVEL_G

new Float:damage_given[33],
	damage_required_cvar;

new const g_moneyDiv = 50;

public plugin_init()
{
	register_plugin("x", "v0.1", AUTHOR);

	RegisterHam(Ham_TakeDamage, "player", "TakeDamage", true);

	damage_required_cvar = register_cvar("damage_required_cvar", "500");
}

public TakeDamage(victim, idinflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(attacker) || !is_user_connected(victim) || !damage)
	{
		return;
	}

	new required = get_pcvar_num(damage_required_cvar);

	damage_given[attacker] += damage;

	if(get_user_team(attacker) != get_user_team(victim) && is_user_zombie(victim))
	{
	while(damage_given[attacker] >= required)
	{
		damage_given[attacker] -= required;

		new money = cs_get_user_money( attacker )
		new rewardedMoney = get_pcvar_num(damage_required_cvar) / g_moneyDiv
			
		if(get_user_flags( attacker ) & VIP)
			rewardedMoney *= 2
		if(get_user_flags( attacker ) & VIP_PLUS)
			rewardedMoney *= 4
		if(get_user_flags( attacker ) & VIP && get_user_flags(attacker) & VIP_PLUS)
		{
			rewardedMoney = get_pcvar_num(damage_required_cvar) / g_moneyDiv
			rewardedMoney *= 5
		}
			
		cs_set_user_money( attacker, min(money + rewardedMoney, 16000 ), 1 )
	}
	}
}