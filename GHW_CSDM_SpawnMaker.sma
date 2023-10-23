/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 07-09-09
*
*  ============
*   Changelog:
*  ============
*
*  v2.0
*    -Changed how you test for bad spawns
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.0b"

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <GHW_spawnlist_gen>
#include <amxmisc>

new bool:waiting_on_response
new configfile[200]
new g_method

new Float:last_spawn[33][3]
new current_spawn[33]
new const TestMenu[64] = "CSDM Bad Spawn Finder^n^n1. Working^n2. Broken^n^n0. Cancel"

public plugin_init()
{
	register_plugin("GHW's CSDM Spawn Maker",VERSION,"GHW_Chronic")

	register_concmd("amx_make_csdm_spawns","cmd_makespawns",ADMIN_BAN," Creates Random CSDM Spawn Locations on current map. [Method 1=Normal 2=Extensive 3=Exhaustive]")
	register_concmd("amx_test_csdm_spawns","cmd_test",ADMIN_BAN," Teleports you to all of the spawnpoints 1 by 1 and asks if they are bad")
	register_clcmd("Y","typed_confirmed")
	register_clcmd("N","typed_negative")

	register_menu("SpawnFixMenu",(1<<0)|(1<<1)|(1<<9),"Menu_Pressed")

	new mapname[32]
	get_mapname(mapname,31)

	get_configsdir(configfile,199)
	format(configfile,199,"%s/csdm/%s.spawns.cfg",configfile,mapname)
}

public cmd_test(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}

	current_spawn[id] = -1

	Menu_Pressed(id,0)

	console_print(id,"[AMXX] Test started.")

	return PLUGIN_HANDLED
}

public Menu_Pressed(id,key)
{
	switch(key)
	{
		//Yes
		case 0:
		{
			//
		}
		//No
		case 1:
		{
			new string[32]
			format(string,31,"%d %d %d",floatround(last_spawn[id][0]),floatround(last_spawn[id][1]),floatround(last_spawn[id][2]))

			new read[64], trash
			new Fsize = file_size(configfile)
			for(new i=0;i<Fsize;i++)
			{
				read_file(configfile,i,read,63,trash)
				if(contain(read,string)==0)
				{
					write_file(configfile,"",i)
					break;
				}
			}
		}
		//Cancel
		case 9:
		{
			client_print(id,print_chat,"[AMXX] Test Cancelled.")
			return PLUGIN_HANDLED
		}
	}

	if(current_spawn[id]<file_size(configfile,1) - 1)
	{
		current_spawn[id]++

		new readString[128], trash
		read_file(configfile,current_spawn[id],readString,127,trash)
		if(strlen(readString)<6)
		{
			Menu_Pressed(id,0)
			return PLUGIN_HANDLED
		}

		new left[32]
		strbreak(readString,left,31,readString,127)
		last_spawn[id][0] = str_to_float(left)
		strbreak(readString,left,31,readString,127)
		last_spawn[id][1] = str_to_float(left)
		strbreak(readString,left,31,readString,127)
		last_spawn[id][2] = str_to_float(left)

		set_pev(id,pev_origin,last_spawn[id])

		show_menu(id,(1<<0)|(1<<1)|(1<<9),TestMenu,-1,"SpawnFixMenu")
	}
	else
	{
		client_print(id,print_chat,"[AMXX] Test Complete.")
	}


	return PLUGIN_HANDLED
}

public cmd_makespawns(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if(starttime)
	{
		console_print(id,"[AMXX] Plugin Currently Making Spawns - Please Wait. (%d Seconds till Timeout)",floatround(timelimit - get_gametime()))
		return PLUGIN_HANDLED
	}

	g_method = 1
	if(read_argc()>1)
	{
		new arg[8]
		read_argv(1,arg,31)
		g_method = str_to_num(arg)
	}

	waiting_on_response = false
	if(file_exists(configfile))
	{
		console_print(id,"[AMXX] This map already has Spawn Points. Replace them with new ones?")
		console_print(id,"[AMXX] Y/N")
		waiting_on_response = true
		return PLUGIN_HANDLED
	}

	start_search(id)

	return PLUGIN_HANDLED
}

public typed_confirmed(id)
{
	if(!waiting_on_response || !(get_user_flags(id) & ADMIN_BAN))
	{
		return PLUGIN_HANDLED
	}

	waiting_on_response = false
	start_search(id)

	return PLUGIN_HANDLED
}

public typed_negative(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
	{
		return PLUGIN_HANDLED
	}

	waiting_on_response = false

	return PLUGIN_HANDLED
}

public start_search(id)
{
	new Float:timeoutamount
	switch(g_method)
	{
		case 2: timeoutamount = TIMEOUT_EXTENSIVE
		case 3: timeoutamount = TIMEOUT_EXHAUSTIVE
		default: timeoutamount = TIMEOUT, g_method = 1
	}

	set_task(timeoutamount,"Save_Locations",id)

	console_print(id,"[AMXX] Finding Spawn Locations. This process will take %d seconds.",floatround(timeoutamount))
	genspawnlist(g_method,MAX_ORIGINS)
}

public Save_Locations(id)
{
	if(file_exists(configfile)) delete_file(configfile)

	new configdir[200]
	get_configsdir(configdir,199)
	format(configdir,199,"%s/csdm",configdir)
	if(!dir_exists(configdir)) mkdir(configdir)

	new string[64], randnum
	for(new i=0;i<num_origins;i++)
	{
		randnum = random_num(-180,180)

		format(string,63,"%d %d %d 0 %d 0 0 0 %d 0",
		floatround(origins[i][0]),
		floatround(origins[i][1]),
		floatround(origins[i][2]),
		randnum,
		randnum)

		write_file(configfile,string,-1)
	}

	console_print(id,"[AMXX] Spawn Locations Successfully Created & Saved.")
	client_print(id,print_chat,"[AMXX] Spawn Locations Successfully Created & Saved.")

	if(is_plugin_loaded("CSDM Mod"))
	{
		//Reload Spawn Points
		if(callfunc_begin("read_cfg","csdm_spawn_preset.amxx")==1)
		{
			callfunc_push_int(1)
			callfunc_push_str("")
			callfunc_push_str("")
			callfunc_end()
		}
	}
}
