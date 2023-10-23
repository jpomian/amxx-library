#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <xs>
#tryinclude <biohazard>

#define HP_PER_ZM 10
#define ForPlayers(%1) for(new %1 = 1; %1 <= 32; %1++)

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

enum(+= 124)
{
	TASKID_CHECK,
	TASKID_RADAR
}

new cvar_radar, g_maxplayers
static const SoundPath[] = "bhz_custom/bowser_laugh.wav";
new bool:items_given[33];

public plugin_init()
{
	register_plugin("zombie radar", "0.3", "cheap_suit")
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_init2()
{
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("Damage", "event_damage", "b")
	RegisterHam(Ham_Spawn, "player", "player_spawned", true);

	cvar_radar = register_cvar("bh_zombie_radar", "1")
	g_maxplayers = get_maxplayers()
}

public plugin_precache()
{
        precache_sound(SoundPath);
}

public player_spawned(index)
{
        if(!is_user_alive(index))
        {
                return;
        }
 
        items_given[index] = false;
}

public event_newround() 
{
	remove_task(TASKID_CHECK)
	remove_task(TASKID_RADAR)
}

public client_disconnected(id)
{
	remove_task(TASKID_CHECK)
	set_task(1.0, "task_check", TASKID_CHECK)
}

public event_damage(id)
{
	if(get_user_health(id) < 1 && !is_user_zombie(id))
	{
		remove_task(TASKID_CHECK)
		set_task(1.0, "task_check", TASKID_CHECK)
	}
}

public event_infect(victim, attacker)
{
	if(get_pcvar_num(cvar_radar))
	{
		remove_task(TASKID_CHECK)
		set_task(1.0, "task_check", TASKID_CHECK)
	}
}

public task_check()
{
	static survivor; survivor = last_survivor()

	if(survivor) 
	{
		static params[1]; params[0] = survivor

		set_task(1.0, "task_radar", TASKID_RADAR, params, 1)
	}
}

public task_radar(params[])
{
	static id; id = params[0]
	new alive_zms = get_alive(0)
	new alive_cts = get_alive(1)
	new surv_name[32], surv_hp

	if(alive_cts > 1)
	{
		static msg_bombpickup
		if(!msg_bombpickup) msg_bombpickup = get_user_msgid("BombPickup")
		
		message_begin(MSG_ALL, msg_bombpickup)
		message_end()
		
		return
	}

	get_user_name(id, surv_name, charsmax(surv_name))
	surv_hp = get_user_health(id)
	set_dhudmessage(30, 36, 208, -1.0, 0.16, 0, 6.0, 0.5);
	show_dhudmessage(0, "%s (%i HP) VS %i ZOMBIE", surv_name, surv_hp, alive_zms);

	if(!items_given[id])
    {
		set_user_health(id, surv_hp + HP_PER_ZM*alive_zms);
		if(!user_has_weapon(id, CSW_SMOKEGRENADE))
			give_item(id, "weapon_smokegrenade")
		items_given[id] = true;
    }

	if(!is_user_alive(id))
	{
		static msg_bombpickup
		if(!msg_bombpickup) msg_bombpickup = get_user_msgid("BombPickup")
		
		message_begin(MSG_ALL, msg_bombpickup)
		message_end()
		
		return
	}

	static origin[3]
	get_user_origin(id, origin)
	
	static msg_bombdrop
	if(!msg_bombdrop) msg_bombdrop = get_user_msgid("BombDrop")
	
	message_begin(MSG_ALL, msg_bombdrop)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_byte(0)
	message_end()
	
	set_task(0.5, "task_radar", TASKID_RADAR, params, 1)
}

stock last_survivor()
{
	static id, count, survivor[33]; count = 0
	for(id = 1; id <= g_maxplayers; id++) if(is_user_alive(id) && !is_user_zombie(id)) survivor[count++] = id
	return count == 1 ? survivor[0] : 0
}
 
stock get_alive(type, bool:skip_bots = false)
{
	new alive;

	if(type == 0)
		{
			ForPlayers(i)
        	{
                if(!is_user_alive(i) || (skip_bots && is_user_bot(i)) || !is_user_zombie(i))
                {
                        continue;
                }
 
                alive++;
        	}
		}
	if(type == 1)
		{
			ForPlayers(i)
        	{
                if(!is_user_alive(i) || (skip_bots && is_user_bot(i)) || get_user_team(i) != 2)
                {
                        continue;
                }
 
                alive++;
        	}
		}
 
	return alive;
}