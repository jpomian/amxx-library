#include < amxmodx >
#include < fakemeta >
#include < colorchat >
#include < hamsandwich >
#include < biohazard >

#define VERSION "0.1.0"
#define PLUGIN "Respawn on First Join"

#define TASKID_RESPAWN 256
#define ForPlayers(%1) for(new %1 = 1; %1 <= 32; %1++)
#define ConditionNotMet (get_alive() < 2 || get_roundtime_left() <= 30)

native respawn_zombie(id);

const m_iJoiningState = 121;
const m_iMenu = 205;
const MENU_CHOOSEAPPEARANCE = 3;
const JOIN_CHOOSEAPPEARANCE = 4;

new Float:g_round_start = -1.0;
new Float:g_round_time;
new mp_roundtime, g_maxplayers;

new Float:g_rCountDecimal[33];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "ConnorMcLeod");

    register_clcmd("menuselect", "ClCmd_MenuSelect_JoinClass"); // old style menu
    register_clcmd("joinclass", "ClCmd_MenuSelect_JoinClass"); // VGUI menu

    register_logevent("EventRoundStart", 2, "1=Round_Start");
    register_logevent("EventRoundEnd", 2, "1=Round_End");
    register_event("TextMsg", "EventRoundRestart", "a", "2&#Game_C", "2&#Game_w");
    
    mp_roundtime = get_cvar_pointer("mp_roundtime");
    g_maxplayers = get_maxplayers()
}

public EventRoundStart()
{
    g_round_start = get_gametime();
    g_round_time = get_pcvar_float(mp_roundtime) * 60.0;
}

public EventRoundEnd()
{
    g_round_start = -1.0;

    for(new i = 1; i <= g_maxplayers; i++) { 
		if(!is_user_alive(i))
			remove_task(TASKID_RESPAWN + i)
	}
}

public EventRoundRestart()
{
    g_round_start = -1.0;
}

public ClCmd_MenuSelect_JoinClass(id)
{
    if( get_pdata_int(id, m_iMenu) == MENU_CHOOSEAPPEARANCE && get_pdata_int(id, m_iJoiningState) == JOIN_CHOOSEAPPEARANCE )
    {
        new command[11], arg1[32];
        read_argv(0, command, charsmax(command));
        read_argv(1, arg1, charsmax(arg1));
        engclient_cmd(id, command, arg1);
        ExecuteHam(Ham_Player_PreThink, id);
        if( !is_user_alive(id) )
        {
            redirect(id);
        }
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public redirect(id)
{
    if(!ConditionNotMet)
        respawnMenu(id);
}

public respawnMenu(id)
{
    new Temp[101], name[33];
    get_user_name(id, name, sizeof(name) - 1);
    
    formatex(Temp, 100, "\wWitaj na serwerze \yBiohazard\w, \r%s\w.^nCzy chcesz odrodzic sie jako Zombie?^n^n", name);
    
    new menuresp = menu_create(Temp, "handler_playerRespawn");
    
    menu_additem(menuresp, "Tak")

    menu_additem(menuresp, "Nie")
        
    menu_setprop(menuresp , MPROP_EXIT , MEXIT_NEVER); //Dont allow Menu to exit
    menu_display(id, menuresp, 0);

    return PLUGIN_HANDLED;
}

public handler_playerRespawn(id, menu, item)
{
    if( item == MENU_EXIT )
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    if( is_user_alive(id) )
    {
        return PLUGIN_HANDLED;
    }

    switch(item)
    {
        case 0: {
            if(!ConditionNotMet)
            {
                g_rCountDecimal[id] = 5.0;
                set_task(5.0, "player_ressurect", TASKID_RESPAWN+id)
                set_task(0.1, "resp_countdown", id, _, _, "a", 50 )
            }
            else
                Generate_Message(id);
        }
        case 1: Generate_Message(id);
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
    
}

public resp_countdown(id)
{
    g_rCountDecimal[id] -= 0.1
    if(g_rCountDecimal[id] >= 0.0)
    	client_print(id, print_center, "Dolaczysz do gry za: %.1f", g_rCountDecimal[id])
}

public player_ressurect(taskid)
{
    static id
    id = taskid - TASKID_RESPAWN

    new name[33];
    get_user_name(id, name, sizeof(name) - 1);

    respawn_zombie(id); 
    ColorChat(id, GREEN, "[Biohazard] ^x01Witamy ponownie, %s.", name);
}

stock get_alive(bool:skip_bots = false)
{
	new alive;
		
        ForPlayers(i)
        {
            if(!is_user_alive(i) || (skip_bots && is_user_bot(i)) || !is_user_zombie(i))
            {
                    continue;
            }
 
            alive++;
        }
 
	return alive;
}

stock get_pnum(bool:skip_bots = false)
{
	new player;
		
        ForPlayers(i)
        {
            if(!is_user_connected(i))
            {
                    continue;
            }
 
            player++;
        }
 
	return player;
}

Generate_Message( id )
{
    ColorChat(id, GREEN, "[Biohazard]^x01 Wejdziesz do gry po zakonczeniu biezacej rundy.")
}

Float:get_roundtime_left()
{
    return (g_round_start == -1.0) ? 0.0 : ((g_round_start + g_round_time) - get_gametime());
}