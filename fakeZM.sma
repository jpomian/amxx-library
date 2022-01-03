#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <map_manager>
#include <map_manager_scheduler>

#define VERSION "1.0"
//#define DEBUG

#define ForArray(%1,%2) for(new %1 = 0; %1 < sizeof %2; %1++)

enum _:BotDataEnumerator (+= 1)
{
    BOT_NAME,
    BOT_ADDRESS
};

static const BotsData[][] = 
{
    { "Status Mapy", "20.05.45.45.2" }
};

static const HLTVNewName[] = { "[HLTV] Biohazard" };

new bot[sizeof(BotsData)],
    bot_name[sizeof(BotsData)][32],
    pCvarTL,
    pCvarNM;

public plugin_init() 
{
    register_plugin("Spectator Bots", VERSION, "Mixtaz + aSior");

    pCvarTL = get_cvar_pointer("mp_timelimit");
    pCvarNM = get_cvar_pointer("amx_nextmap");
    
    set_task(2.0, "delayed_create_bot");
    
}
public client_putinserver( id )
{
	if(is_user_hltv(id))
        set_task( 5.0, "verify", id );
    
	return PLUGIN_CONTINUE;
}
public verify( id )
{
    new name[ 32 ];
    get_user_name( id, name, charsmax(name) );

    if(!equali(name, HLTVNewName))
        server_cmd("amx_nick ^"%s^"  ^"%s^"", name, HLTVNewName);
	
    return PLUGIN_CONTINUE;
}
public delayed_create_bot()
{
    ForArray(i, BotsData)
    {
        bot[i] = create_bot(i, BotsData[i][BOT_NAME], BotsData[i][BOT_ADDRESS]);

        set_task(1.0, "update_bot", i, .flags = "b");

    }

}

public update_bot(iter)
{
    new id = bot[iter],
        old_name[32],
        tl = get_timeleft(),
        m = tl / 60,
        s = tl % 60,
        new_bot_name[64],
        nextmap[32];
    
    copy(old_name, charsmax(old_name), bot_name[iter]);

    // Prepare new name based on time left.
    if(get_pcvar_num(pCvarTL))
        formatex(new_bot_name, charsmax(new_bot_name), "%s (%d:%02d)", old_name, m, s);
    else
    {
        if(is_vote_will_in_next_round())
            formatex(new_bot_name, charsmax(new_bot_name), "%s (Głosowanie)", old_name);
        else
        {
            if(pCvarNM)
            {
                get_pcvar_string(pCvarNM, nextmap, charsmax(nextmap));
                formatex(new_bot_name, charsmax(new_bot_name), "Zmiana (%s)", nextmap);
            } else
            {
                formatex(new_bot_name, charsmax(new_bot_name), "Zmiana (W nastepnej rundzie)");
            }
        }
    }

    // Set new name.
    set_pev(id, pev_netname, new_bot_name);
    set_user_info(id, "name", new_bot_name);
}

create_bot(inner_id, const name[], const address[])
{
    new id = engfunc(EngFunc_CreateFakeClient, name);
    
    // Could not create bot.
    if(!id)
    {
        #if defined DEBUG
        log_amx("Could not create bot ^"%s^" (%i).", name, id);
        #endif

        return 0;
    }

    new reject_reason[100];

    engfunc(EngFunc_FreeEntPrivateData, id);
    dllfunc(DLLFunc_ClientConnect, id, name, address, reject_reason);

    copy(bot_name[inner_id], charsmax(bot_name[]), name);

    if(!is_user_connected(id))
    {
        #if defined DEBUG
        log_amx("Bot (%i) registered as not connected. (Reason: %s)", id, reject_reason);
        #endif

        return 0;
    }

    // Emulate client_putinserver forward.
    dllfunc(DLLFunc_ClientPutInServer, id);
    
    // Do not spawn the bot.
    set_pev(id, pev_spawnflags, pev(id, pev_spawnflags) | FL_FAKECLIENT);
    
    // Mark as fake player.
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
    
    // Put him in the spectators.
    cs_set_user_team(id, CS_TEAM_SPECTATOR);

    return id;
}