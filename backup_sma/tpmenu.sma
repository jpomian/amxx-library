#include <amxmodx>
#include <fakemeta>
#include <engine>

native is_user_zombie(id)

#define PLUGIN "Menu teleportacji"
#define VERSION "0.1a"
#define AUTHOR "Mixtaz"

new Array:g_aSpawnPoints
new g_iTotalSpawns

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    g_aSpawnPoints = ArrayCreate(5)
    
    new iEnt = -1
    
    while((iEnt = find_ent_by_class(iEnt, "info_player_deathmatch")))
    {
        ArrayPushCell(g_aSpawnPoints, iEnt)
        g_iTotalSpawns++
    }

    register_clcmd("amx_teleport", "TeleportMenu", ADMIN_BAN)
    register_clcmd("say /tp", "TeleportMenu", ADMIN_BAN)

}
public TeleportMenu(id)
{
    new iMenu = menu_create(fmt("\yTeleportuj"), "TeleMenuHandler")

    new maxplayers = get_maxplayers(); // ile osob moze byc maksymalnie na serwerze
    new name[64] // zmienna przechowujaca nick gracza
    new data[6] // to bedzie ID gracza, ktore wysylamy w info :)
    new itembuffer[64]

    for(new i=1; i<=maxplayers; i++)  // pętla od 1 DO MAKSYMALNEJ LICZBY GRACZY
	{
        if(!is_user_alive(i))
			continue;      // jezeli gracz o danym ID (i) nie jest polaczony to go pomijamy uzwajać "continue"
	 
        if(is_user_hltv(i))
			continue;    // jezeli dane ID to HLTV/BOT - pomijamy!

        num_to_str(i, data, 5);
        get_user_name(i, name, 31);  // pobieramy nick
        formatex(itembuffer, charsmax(itembuffer), "%s \y[%s]", name, is_user_zombie(i) ? "Zombie" : "CT");
        menu_additem(iMenu, itembuffer, data);  // dodajemy do iMenu gracza.
	}
    menu_setprop(iMenu, MPROP_BACKNAME, "Poprzednia strona");
    menu_setprop(iMenu, MPROP_NEXTNAME, "Nastepna strona");
    menu_setprop(iMenu, MPROP_EXITNAME, "Wyjdz");
    menu_display(id, iMenu, 0);
    return PLUGIN_HANDLED
}
public TeleMenuHandler(id, menu, item)
{
    new access, info[8], name[63], callback;
    menu_item_getinfo(menu, item, access, info, 7, name, 63, callback);
    menu_destroy(menu);
    new kogo = str_to_num(info);
    new admname[32], trgname[32];
    get_user_name(id, admname, 31);
    get_user_name(kogo, trgname, 31);

    if(item != MENU_EXIT && item != MENU_BACK && item != MENU_MORE)
    {
        if(is_user_alive(kogo))
            TeleportToSpawn(kogo)
                
        log_amx("Admin %s teleportowal %s", admname, trgname)

        TeleportMenu(id);
    }
}
public GetRandomSpawn(Float:fOrigin[3])
{
    new iEnt = ArrayGetCell(g_aSpawnPoints, random(g_iTotalSpawns))
    pev(iEnt, pev_origin, fOrigin)
}

public TeleportToSpawn(id)
{
    new Float:fOrigin[3]
    GetRandomSpawn(fOrigin)
    set_pev(id, pev_origin, fOrigin)
} 