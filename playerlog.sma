#include <amxmodx>
#include <nvault>

new const g_szFileName[] = "NewPlayers.txt"    //FileName for the log

new const g_szSpecialKey[] = "somerandomkey123"
new const TASK_ID = 23763

new g_iNewPlayers
new gVault
new timestamp

public plugin_init()
{
    register_plugin("New Players Count", "1.0", "Flicker")
    set_task(1200.0, "taskCountMinutes", TASK_ID, _, _, "b")
    
    gVault = nvault_open("ConnectedPlayers")
    
    getPlayers()
}

public taskCountMinutes()
{
    new szHours[16];
    get_time("%H", szHours, charsmax(szHours))
    
    if(str_to_num(szHours) == 23)
    {
        logPlayers()
        client_print(0, print_chat, "End of the day! New player for today: %d", g_iNewPlayers)
        
        nvault_remove(gVault, g_szSpecialKey)
        g_iNewPlayers = 0
    }
}

public client_putinserver(id)
{
    new szAuthID[36], szNumber[2]
    get_user_authid(id, szAuthID, charsmax(szAuthID))
    
    if(!nvault_lookup(gVault, szAuthID, szNumber, charsmax(szNumber), timestamp))
    {
        g_iNewPlayers++
        savePlayers()
        setPlayerEntered(szAuthID)
    }
}


stock savePlayers()
{
    new szPlayers[32]
    num_to_str(g_iNewPlayers, szPlayers, charsmax(szPlayers))
    nvault_set(gVault, g_szSpecialKey, szPlayers)
}

stock getPlayers()
{
    new szPlayers[32]
    nvault_get(gVault, g_szSpecialKey, szPlayers, charsmax(szPlayers))
    g_iNewPlayers = str_to_num(szPlayers)
}

stock setPlayerEntered(const szAuthID[])
{
    nvault_set(gVault, szAuthID, "1")
}

stock logPlayers()
{
    new szDate[32]
    get_time("%Y/%m/%d", szDate, charsmax(szDate))
    log_to_file(g_szFileName, "%s - %d new players", szDate, g_iNewPlayers)
} 