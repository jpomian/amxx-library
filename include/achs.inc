#if defined _achievements_included
        #endinput
#endif

#define _achievements_included

#pragma library "achs"

#define SAVE_IN_DISCONNECT 1
#define SAVE_IN_DEATH 2

native ach_get_index(const name[]); 
native ach_get_stance(id, ach_id);
native ach_get_status(id, ach_id);
native ach_get_name(ach_id, var[], len);
native ach_get_desc(ach_id, var[], len);
native ach_get_target(ach_id);
native ach_get_max();
native ach_set_stance(id, ach_id, value);
native ach_set_status(id, ach_id, value);
native ach_add(const ach_name[], const ach_desc[], ach_target); 
native ach_reset_status(id, ach_id); 
native ach_add_status(id, ach_id, value);
native ach_get_playerachs(id);

forward ach_give_reward(pid, aid);
forward ach_load_post( id );
forward ach_save_pre( id, savein );
forward ach_save_post( id, savein );
forward ach_info_display( id, ach_id, data[ 2 ] );
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
