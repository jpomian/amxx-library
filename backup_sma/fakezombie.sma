#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define VERSION "1.0"

new const name_bot[] = "Witamy na serwerze!";
new const name_bot2[] = "Autentyczny Biohazard";
new bool:bot_on, bot_id;
new bool:bot_on2, bot_id2;

public plugin_init() 
{
    register_plugin("Spectator Bots", VERSION, "Elle Avant Tous");
    
    bot_on=false;
    bot_on2=false;
    bot_id=0;
    bot_id2=0;
    set_task(1.4,"fake_make");
    set_task(1.4,"fake_make2");
    return PLUGIN_CONTINUE
}

public fake_make()
{    
    new rj[128];
    if((!bot_on)&&(!bot_id))
    {
        bot_id=engfunc(EngFunc_CreateFakeClient,name_bot);
        if(bot_id > 0)
        {
            engfunc(EngFunc_FreeEntPrivateData,bot_id);
            dllfunc(DLLFunc_ClientConnect,bot_id,name_bot,"20.05.45.45.2",rj);
            if(is_user_connected(bot_id))
            {
                dllfunc(DLLFunc_ClientPutInServer, bot_id);
                set_pev(bot_id,pev_spawnflags,pev(bot_id,pev_spawnflags)|FL_FAKECLIENT);
                set_pev(bot_id,pev_flags,pev(bot_id,pev_flags)|FL_FAKECLIENT);
                cs_set_user_team(bot_id, CS_TEAM_SPECTATOR);
                bot_on = true;
            }        
        }        
    }
    
    return PLUGIN_CONTINUE;    
}  

public fake_make2()
{    
    new rj[128];
    if((!bot_on2)&&(!bot_id2))
    {
        bot_id2=engfunc(EngFunc_CreateFakeClient,name_bot2);
        if(bot_id2 > 0)
        {
            engfunc(EngFunc_FreeEntPrivateData,bot_id2);
            dllfunc(DLLFunc_ClientConnect,bot_id2,name_bot2,"20.05.45.45.2",rj);
            if(is_user_connected(bot_id2))
            {
                dllfunc(DLLFunc_ClientPutInServer, bot_id2);
                set_pev(bot_id2,pev_spawnflags,pev(bot_id2,pev_spawnflags)|FL_FAKECLIENT);
                set_pev(bot_id2,pev_flags,pev(bot_id2,pev_flags)|FL_FAKECLIENT);
                cs_set_user_team(bot_id2, CS_TEAM_SPECTATOR);
                bot_on2 = true;
            }        
        }        
    }
    
    return PLUGIN_CONTINUE;    
}  