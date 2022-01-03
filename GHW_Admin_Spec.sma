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
*  Last Edited: 12-30-07
*
*  ============
*   Changelog:
*  ============
*
*  v2.1
*    -Fixed Bug
*
*  v2.0
*    -Added ML
*    -Optimized Code
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.1"

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

new pcvar

public plugin_init()
{
	register_plugin("Only Admin Spectators",VERSION,"GHW_Chronic")
	pcvar = register_cvar("spec_admin","a")

	register_dictionary("GHW_Admin_Spec.txt")
}

public client_putinserver(id)
{
	set_task(2.0,"check_team",id,"",0,"b")
}

public check_team(id)
{
	static adminflags[32]
	get_pcvar_string(pcvar,adminflags,31)

	if(!is_user_connected(id))
	{
		remove_task(id)
	}
	else if(!(get_user_flags(id) & read_flags(adminflags)) && cs_get_user_team(id)==CS_TEAM_SPECTATOR)
	{
		client_print(id,print_center,"[AMXX] %L",id,"MSG_NOSPEC")
		new num, players[32], Float:ct
		get_players(players,num,"g")
		for(new i=0;i<num;i++)
		{
			if(players[i]!=id && cs_get_user_team(players[i])==CS_TEAM_CT) ct += 1.0
		}
		if(float(num) / 2.0 >= ct) cs_set_user_team(id,CS_TEAM_CT)
		else cs_set_user_team(id,CS_TEAM_T)
	}
}
