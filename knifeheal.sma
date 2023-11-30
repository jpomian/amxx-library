#include <amxmodx>
#include <amxmisc>
#include <biohazard>
#include <fun> 

#define PLUGIN_NAME "Knife Healing"  
#define PLUGIN_VERSION "1.0"  
#define PLUGIN_AUTHOR "VEN"  

#define MAX_HEALTH 100
#define TASK_INTERVAL 2.0

new CVAR_HEALTH_ADD[] = "amx_knifeheal_addhealth"    
new CVAR_HEALTH_MAX[] = "amx_knifeheal_maxhealth"  


public plugin_init() {  
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)  
	register_event("CurWeapon", "event_cur_weapon_knife", "be", "1=1", "2=29")  
	register_event("CurWeapon", "event_cur_weapon_not_knife", "b", "1=0")  
	register_cvar(CVAR_HEALTH_ADD, "8")  
	register_cvar(CVAR_HEALTH_MAX, "100")
}  

public plugin_precache() {
	precache_sound("items/medshot5.wav")
	return PLUGIN_CONTINUE
}

public task_healing(id)
{ 

    if(is_user_zombie(id))
        return
    
    new addhealth = get_cvar_num(CVAR_HEALTH_ADD)  
    if (!addhealth) // if plugin disabled  
		return  
	
    new maxhealth = get_cvar_num(CVAR_HEALTH_MAX)
    if (maxhealth > MAX_HEALTH) { 
		set_cvar_num(CVAR_HEALTH_MAX, MAX_HEALTH)  
		maxhealth = MAX_HEALTH 	
    }  
	
    new health = get_user_health(id)   
	
    if (is_user_alive(id) && (health < maxhealth)) { 
		set_user_health(id, health + addhealth)
		// set_hudmessage(0, 255, 0, -1.0, 0.65, 0, 1.0, 2.0, 0.1, 0.1, 4)
		// show_hudmessage(id,"%L", LANG_PLAYER,"KH_HUDMESSAGE")
		emit_sound(id,CHAN_VOICE,"items/medshot5.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
		write_short(1<<8)
		write_short(1<<10)
		write_short(0x0000)
		write_byte(0)
		write_byte(120)
		write_byte(0)
		write_byte(75)
		message_end()
    } else
		remove_task(id)
	
	
}  

public event_cur_weapon_knife(id) {
	new Speech[192]
	read_args(Speech,192)
	remove_quotes(Speech)
	if (is_user_alive(id)){
		set_task(TASK_INTERVAL,"task_healing",id,_,_,"b") 
	}
}

public event_cur_weapon_not_knife(id) {  
	if(task_exists(id)) remove_task(id)  
}  

public client_disconnected(id) {  
	if(task_exists(id)) remove_task(id)  
}    
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
