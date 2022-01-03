#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <achs>
#include <csx>
#include <biohazard>

#define TASK 666
#define VIP ADMIN_LEVEL_H

#define TASK_REFRESHRATE 0.5

native get_user_infections(id);
native get_user_kills(id);

new ranga[33] = 0
new sync

new const nazwa[][]={ "Bot","Szeregowy","Starszy Szeregowy","Kapral","Starszy Kapral","Plutonowy","Sierzant",
"Starszy Sierzant","Chorazy","Sztabowy","Podporucznik","Porucznik","Kapitan", "Major", "Podpulkownik", "Pulkownik", "General Brygady", "General Dywizji", "General Broni", "Marszalek Zombie" }

new const wymagania[]={ 10,25,50,100,250,450,700,1000,1500,2000,2500,3200,4500,6000,7750,10000,12500,15000,20000,-999 }

new const hpDiv = 10

public plugin_init(){
	
	register_plugin("Rangi Zombie", "1.1a", "Mixtaz");
	
	register_event("StatusValue", "pokazStatus", "be", "1=2", "2!0")
	register_event("StatusValue", "ukryjStatus", "be", "1=1", "2=0")
	
}

public client_authorized(id)
{
	set_task(TASK_REFRESHRATE,"rank",TASK+id,_,_,"b")
	ranga[id] = 0;
}

public client_disconnected(id) {
	if(task_exists(TASK+id)) remove_task(TASK+id)
	ranga[id] = 0;
}

public ukryjStatus(id)
{
	ClearSyncHud(id, sync)
}
public pokazStatus(id)
{
	if(!is_user_bot(id) && is_user_connected(id)) 
	{
		new nickname[32], pid = read_data(2)
		get_user_name(pid, nickname, sizeof nickname - 1)
		
		new druzyna1 = is_user_zombie(id)
		new druzyna2 = is_user_zombie(pid)
		new druzyna3 = !is_user_zombie(pid)
		new druzyna4 = !is_user_zombie(pid)
		
		new stats[8], body[8]
		get_user_stats(pid, stats, body)
		
		new kolor1 = 0, kolor2 = 0
		
		new clip, ammo, wpnid = get_user_weapon(pid, clip, ammo)
		new wpnname[32]
		if(wpnid)
		{
			xmod_get_wpnname(wpnid, wpnname, 31)
		}
		
		if (druzyna1 || druzyna2)
		{
			kolor1 = 255 //red
		}
		else
		{
			kolor2 = 255 //blue
		}
		
		if (druzyna1 == druzyna2 || druzyna3 == druzyna4)
		{
			if(is_user_zombie(pid))
			{
				set_hudmessage(kolor1, 50, kolor2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(id, sync, "%s^n (%i HP)", nickname, get_user_health(pid))
			} else {
				set_hudmessage(kolor1, 50, kolor2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(id, sync, "%s (%i HP)^nRanga: %s", nickname, get_user_health(pid), nazwa[ranga[pid]])
			}
		}
		if(druzyna1 == druzyna4 || druzyna3 == druzyna2)
		{
			set_hudmessage(kolor1, 50, kolor2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01)
			ShowSyncHudMsg(id, sync, "%s", nickname)
		}
	}
}

public rank(id) {
	
	new stats[8], body[8],name[33],target
	
	id-=TASK
	
	ranga[id] = 0;
	
	if(!is_user_alive(id) && id)
	{
		target= pev(id, pev_iuser2);
		get_user_stats(target, stats, body)
		get_user_name(target,name,32)
	}
	else
	{
		get_user_stats(id, stats, body)
		get_user_name(id,name,32)
	}
	
	while(get_user_kills(id)>wymagania[ranga[id]] && wymagania[ranga[id]]!=-999)
		ranga[id]++
	
	sync = CreateHudSyncObj()
	
	if(is_user_alive(id)) {
		if(is_user_zombie(id)){
			set_hudmessage(250, 100, 0, 0.03, 0.93, _, TASK_REFRESHRATE+0.1, TASK_REFRESHRATE+0.1)
			ShowSyncHudMsg(id, sync, "Zycie: %i Infekcji: %i (+%i HP)", get_user_health(id), get_user_infections(id), (get_user_infections(id)/hpDiv));
		}
		else {
			set_hudmessage(250 , 100 ,0, 0.03, 0.93, _, TASK_REFRESHRATE+0.1, TASK_REFRESHRATE+0.1)
			ShowSyncHudMsg(id, sync, "Zabojstw: %d/%d^tRanga: %s", get_user_kills(id), wymagania[ranga[id]], nazwa[ranga[id]]);
		}
	}
	else if(target) {
		set_hudmessage(162, 101, 31, 0.65, -1.0, _, TASK_REFRESHRATE+0.1, TASK_REFRESHRATE+0.1)
		ShowSyncHudMsg(id, sync, "Nick: %s^nZabojstwa: %d/%d (%s)^nInfekcje: %i (+%i HP)^nOsiagniecia: %i/%i", name, get_user_kills(target), wymagania[ranga[target]], nazwa[ranga[target]], get_user_infections(target), (get_user_infections(target)/hpDiv), ach_get_playerachs(target), ach_get_max());
	}
	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
