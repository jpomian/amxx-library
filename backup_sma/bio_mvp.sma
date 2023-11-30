#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <biohazard>
#include <colorchat>

#define PLUGIN "Biohazard stats"
#define VERSION "1.0"
#define AUTHOR "Sn!ff3r"

enum {
	kills = 0,
	infects,
	damage
}

new stats[33][3] // 0 - zabojstwa, 1 - infekcje, 2 - damage
new g_maxplayers

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "cl_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "hamTakeDamage")
	register_event("DeathMsg", "DeathMsg", "a")
	
	register_logevent("round_end", 2, "1=Round_End")
	
	g_maxplayers = get_maxplayers()
}

public cl_spawn(id)
{
	stats[id][0] = stats[id][1] = stats[id][2] = 0
}
public hamTakeDamage(victim, inflictor, attacker, Float:damage, DamageBits)
{
    if( 1 <= attacker <= 32)
    {
        if(get_user_team(victim) != get_user_team(attacker))
            stats[attacker][damage] += floatround(damage)
        else
            stats[attacker][damage] -= floatround(damage)
    }
}

public DeathMsg()
{
	new attacker = read_data(1)	// zabojca
	new victim = read_data(2)	// ofiara
	
	if(attacker != victim)
		stats[attacker][kills]++;
}

public event_infect(victim, attacker)
{
	stats[attacker][infects] ++
}

public round_end()
{
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(!is_user_connected(id))
			continue
		
		ColorChat(id, GREEN, "[Twoje statystyki]^1 W tej rundzie zrobiles: zabojstw - ^3%d^1, infekcji - ^3%d^1, obrazen - ^3%d^1.", stats[id][kills],stats[id][infects], stats[id][damage])          
	}    
}