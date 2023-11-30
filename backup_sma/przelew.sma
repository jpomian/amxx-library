#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN "Money Donate"
#define VERSION "1.0"
#define AUTOR "iceeedR"


new const Prefix[] = "[$$$]"
new DonateTarget[32 +1]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTOR);
    register_clcmd("say /daj", "DonateCmd")
    register_clcmd("say /przelej", "DonateCmd")
    register_clcmd("plugin_donate", "DonateHandler")
}
 
public client_disconnected(id)
{
    DonateTarget[id] = 0 // just for secure
}

public DonateCmd(id)
{
    new iMenu = menu_create(fmt("\yPrzelej Kase"), "donate_handler")

    new iPlayers[32], iNum
    get_players_ex(iPlayers, iNum, GetPlayers_MatchTeam, (cs_get_user_team(id) == CS_TEAM_T) ? "TERRORIST" : "CT")
    for(new i, szTempid[10], iPlayer;i < iNum;i++)
    {
        iPlayer = iPlayers[i]

        if(iPlayer != id)
        {
            num_to_str(iPlayer, szTempid, charsmax(szTempid))

            menu_additem(iMenu, fmt("%n", iPlayer), szTempid)
        }
    }
    
    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

public donate_handler(id, iMenu, iItem)
{
    if(iItem == MENU_EXIT)
    {
        menu_destroy(iMenu)
        return PLUGIN_HANDLED
    }
    new iData[6], szItemName[32 * 2], iAccess, iCallback
    menu_item_getinfo(iMenu, iItem, iAccess, iData, charsmax(iData), szItemName, charsmax(szItemName), iCallback)
    
    DonateTarget[id] = str_to_num(iData)
    
    if(!DonateTarget[id])
    {
        client_print_color(id, print_team_default, "%s Ten gracz nie istnieje.", Prefix)
        menu_display(id, iMenu)
        DonateTarget[id] = 0
        return PLUGIN_HANDLED
    }
    
    client_cmd(id, "messagemode plugin_donate")
            
    client_print_color(id, print_team_default, "%s Ile kasy chcesz przekazac?", Prefix)
    client_print_color(id, print_team_default, "%s UWAGA! Tylko polowa przeslanych pieniedzy trafi do odbiorcy.", Prefix)
    return PLUGIN_HANDLED
}

public DonateHandler(id)
{
    new iValue = read_argv_int(1)

    new iReducedValue = iValue/2
        
    new iPlayerMoney = cs_get_user_money(id)
    
    if( iPlayerMoney < iValue || iValue <= 0)
    {
        client_print_color(id, print_team_default, "%s Nie masz wystarczajacej ilosci pieniedzy.", Prefix)
        return PLUGIN_CONTINUE
    }
    
    cs_set_user_money( DonateTarget[id], cs_get_user_money(DonateTarget[id]) + iReducedValue)
    cs_set_user_money( id, cs_get_user_money(id) - iValue)
    
    new szNameGiver[32]
    get_user_name( id, szNameGiver, charsmax( szNameGiver))
    
    new szNameReceiver[32]
    get_user_name(DonateTarget[id], szNameReceiver, charsmax(szNameReceiver))
    
    new iPlayers[32], iNum
    get_players_ex(iPlayers, iNum, GetPlayers_MatchTeam, (cs_get_user_team(id) == CS_TEAM_T) ? "TERRORIST" : "CT")
    for(new i;i < iNum;i++)
    {
        client_print_color(iPlayers[i], print_team_default, "%s^x04 %s^x01 wyslal^x04 $%i^x01 dla^x04 %s.", Prefix, szNameGiver, iReducedValue, szNameReceiver)
    }
    client_cmd(DonateTarget[id], "spk ^"items/9mmclip1.wav^"")
    
    DonateTarget[id] = 0
    return PLUGIN_HANDLED
} 