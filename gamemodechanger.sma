#include <amxmodx>
#include <fakemeta>

#define AUTHOR "Wicked - amxx.pl/user/60210-wicked/"

#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)

new current_name_id[24];
new g_map[32];

public plugin_init()
{
    register_plugin("x", "v0.1", AUTHOR);


    register_forward(FM_GetGameDescription, "update_game_name");

    get_mapname(g_map, charsmax(g_map));

    if(equali(g_map, "zm", 2))
	{
		formatex(current_name_id, charsmax(current_name_id), "Tryb: Biohazard")
	}
	else if(equali(g_map, "ze", 2))
	{
		formatex(current_name_id, charsmax(current_name_id), "Tryb: Escape")
	}
	else
	{
		formatex(current_name_id, charsmax(current_name_id), "Tryb: Deathmatch")
	}


}

public update_game_name()
{
    forward_return(FMV_STRING, current_name_id);

    return FMRES_SUPERCEDE;
} 