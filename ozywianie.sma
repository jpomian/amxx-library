#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta> 


#define PLUGIN "Ozywianie graczy"
#define VERSION "1.0"
#define AUTHOR "Kanter Strajk"


public plugin_init() {
        register_plugin(PLUGIN, VERSION, AUTHOR)
        register_clcmd("amx_ozyw", "pokaz_menu");
}
public pokaz_menu(id)
{
		if(!is_user_connected(id) || !(get_user_flags(id) & ADMIN_IMMUNITY))
		{
		return PLUGIN_HANDLED;
		}
		new players[32], plnum, admin_name[32], sid [32];
		get_user_name(id,admin_name,31);
		get_user_authid(id, sid, 31);
		get_players(players, plnum, "bch");
		new key[128], info[8], team[16], name[64];
		new menu = menu_create("Wybierz gracza do ozywienia", "menu_click")
		for(new i = 0; i < plnum; i++)
		{
		new id=players[i]
		get_user_name(players[i], name, 63);
		switch(get_user_team(id))
		{
                        case 1:
                        {
                                formatex(info, 7, "%d", id);
                                team="TT";
                                formatex(key, 127, "\w%s\y\R%s", name, team);
                                menu_additem(menu, key, info);
                        }
                        case 2:
                        {
                                formatex(info, 7, "%d", id);
                                team="CT";
                                formatex(key, 127, "\w%s\y\R%s", name, team);
                                menu_additem(menu, key, info);
                        }
		}
		log_amx("ADMIN %s <%s> ozywil %s.",admin_name,sid,name);
		}
		menu_setprop(menu, MPROP_BACKNAME, "Poprzednia strona");
		menu_setprop(menu, MPROP_NEXTNAME, "Nastepna strona");
		menu_setprop(menu, MPROP_EXITNAME, "Wyjdz");
		menu_display(id, menu);
		return PLUGIN_HANDLED;
}
public menu_click(id, menu, item)
{
        new access, info[8], name[63], callback;
        menu_item_getinfo(menu, item, access, info, 7, name, 63, callback);
        menu_destroy(menu);
        new kogo = str_to_num(info);
        if(item != MENU_EXIT && item != MENU_BACK && item != MENU_MORE)
        {
                if(!is_user_alive(kogo))
                {
                        set_pev(kogo, pev_deadflag, DEAD_RESPAWNABLE);
                        dllfunc(DLLFunc_Think, kogo);
                        dllfunc(DLLFunc_Spawn, kogo);
                        strip_user_weapons(kogo);
                        give_item(kogo, "weapon_knife");
                }
                pokaz_menu(id);
        }
}