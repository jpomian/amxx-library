#include <amxmodx>
#include <biohazard>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define MAX 32
#define DMG 35
#define CHANCE 5

#define nazwa "Plonace Naboje"
#define opis "Masz 1/LW szans jak strzelisz do gracza to go podpalisz."

new sprite_fire,
	sprite_smoke,
	gmsgStatusIcon;

new bHasFire[MAX+1], palenie_gracza[MAX+1];

public plugin_init() 
{
	register_plugin(nazwa, "1.0", "Cypis")
	register_event("Damage", "Damage", "b", "2!=0");

	register_event("HLTV", "eventRoundInit", "a", "1=0", "2=0");
	gmsgStatusIcon = get_user_msgid("StatusIcon");
}

public plugin_precache()
{
	sprite_fire = precache_model("sprites/fire.spr")
	sprite_smoke = precache_model("sprites/steam1.spr")
}

public plugin_natives()
{
	register_native("give_user_fireammo", "native_give_fireammo", 1)
}

public eventRoundInit()
{
	for(new i = 1; i <= get_maxplayers(); i++) { 
		if(is_user_alive(i))
		{
			if(bHasFire[i])
			{
				bHasFire[ i ] = !bHasFire[ i ];
				show_icon(i, 0)
			}
		}
	}
}

public Damage(id)
{
	new attacker = get_user_attacker(id);

	if(!is_user_alive(attacker))
		return PLUGIN_CONTINUE;
	
	if(is_user_zombie(attacker))
		return PLUGIN_CONTINUE;
	
	if(bHasFire[attacker] && random_num(1, CHANCE) == 1)
	{
		if(task_exists(id+2936))
			remove_task(id+2936);
		palenie_gracza[id] = 15;
		new data[2]
		data[0] = id
		data[1] = attacker
		set_task(0.2, "burning_flame", id+2936, data, 2, "b");
	}
	return PLUGIN_CONTINUE;
}

public burning_flame(data[2])
{
	new id = data[0]
	
	if(!is_user_alive(id))
	{
		palenie_gracza[id] = 0
		remove_task(id+2936);
		return PLUGIN_CONTINUE;
	}
	
	new origin[3], flags = pev(id, pev_flags)
	get_user_origin(id, origin)
	
	if(flags & FL_INWATER || palenie_gracza[id] < 1 || !get_user_health(id))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-50)
		write_short(sprite_smoke)
		write_byte(random_num(15,20))
		write_byte(random_num(10,20))
		message_end()
		
		remove_task(id+2936);
		return PLUGIN_CONTINUE;
	}
	
	if(flags & FL_ONGROUND)
	{
		static Float:velocity[3]
		pev(id, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, 0.8, velocity)
		set_pev(id, pev_velocity, velocity)
	}

	new health = get_user_health(id)
	if(health - DMG > 0)
		set_pev(id, pev_health, float(health - DMG))
	else {
		ExecuteHamB(Ham_Killed, id, data[1], 0)
		
		// Smoke sprite
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
		write_byte(TE_SMOKE) // TE id
		engfunc(EngFunc_WriteCoord, origin[0]) // x
		engfunc(EngFunc_WriteCoord, origin[1]) // y
		engfunc(EngFunc_WriteCoord, origin[2]-50.0) // z
		write_short(sprite_smoke) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		return PLUGIN_CONTINUE;
	}
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE)
	write_coord(origin[0]+random_num(-5,5))
	write_coord(origin[1]+random_num(-5,5))
	write_coord(origin[2]+random_num(-10,10))
	write_short(sprite_fire)
	write_byte(random_num(5,10))
	write_byte(200)
	message_end()
	
	palenie_gracza[id]--
	return PLUGIN_CONTINUE;
}

stock show_icon(id, status)
{
	message_begin(MSG_ONE,gmsgStatusIcon,_,id);
	write_byte(status); // status (0=hide, 1=show, 2=flash)
	write_string("dmg_shock"); // sprite name
	write_byte(246); // red
	write_byte(100); // green
	write_byte(100); // blue
	message_end();
}

public native_give_fireammo(id)
{
	static status;
	bHasFire[ id ] = !bHasFire[ id ];
	status = bHasFire[ id ] ? 1 : 0;
	show_icon(id, status)
}