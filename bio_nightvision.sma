/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <biohazard>

#define PLUGIN "bio_nightvision"
#define VERSION "1.0"
#define AUTHOR "fresh"

#define task_nvg 333

new bool:has_nvg[33],bool:nvg_work[33]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("nightvision" , "nvg_sprawdz")
	register_event("DeathMsg", "DeathMsg", "a")
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
}
public client_disconnected(id)
{
	remove_task(id+task_nvg)
	has_nvg[id]=false
	nvg_work[id]=false
}
public DeathMsg()
{
	new vid = read_data(2)	// ofiara
	
	remove_task(vid+task_nvg)
	has_nvg[vid]=false
	nvg_work[vid]=false
}
public player_spawn(id)
{
	remove_task(id+task_nvg)
	nvg_work[id]=false
	get_user_flags(id) & ADMIN_LEVEL_H ? has_nvg[id] : !has_nvg[id]
}
public event_infect(vic,att)
{
	has_nvg[vic]=false
}
public nvg_sprawdz(id)
{
	if(cs_get_user_nvg(id)) 
	{
		cs_set_user_nvg(id,0)
		has_nvg[id]=true
	}
	if(has_nvg[id] || !is_user_alive(id) || is_user_zombie(id))
	{
		if(nvg_work[id])
		{
			remove_task(id+task_nvg)
			nvg_work[id]=false
		}
		else
		{
			set_task(0.1,"nvg_aura",id+task_nvg,_,_,"b")
			nvg_work[id]=true
		}
	}
}
public nvg_aura(id)
{
	new i=id-task_nvg
	
	if(!is_user_alive(i))
	{
		nvg_spec(i)
		return PLUGIN_CONTINUE
	}
	else
	{
		nvg_human(i)
		return PLUGIN_CONTINUE
	}

}
/*public nvg_zombie(id)
{
	new Origin[3]
	get_user_origin(id, Origin)
	message_begin(MSG_ONE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_DLIGHT)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_byte(75)
	write_byte(20)
	write_byte(0)
	write_byte(0)
	write_byte(2)
	write_byte(0)
	message_end()
}*/
public nvg_human(id)
{
	new Origin[3]
	get_user_origin(id, Origin)
	message_begin(MSG_ONE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_DLIGHT)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_byte(150)
	write_byte(0)
	write_byte(20)
	write_byte(0)
	write_byte(2)
	write_byte(0)
	message_end()
}
public nvg_spec(id)
{
	new Origin[3]
	get_user_origin(id, Origin)
	message_begin(MSG_ONE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_DLIGHT)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_byte(200)
	write_byte(20)
	write_byte(20)
	write_byte(20)
	write_byte(2)
	write_byte(0)
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
