
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>

new const PLUGIN[] = "New Plug-In";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Author";

new const g_steamidfile[] = "blacklist.ini";
new Array: g_steamid;
new g_iSteamIdCount;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    iniGetData();


}

public client_putinserver(id)
{
    new authid[MAX_AUTHID_LENGTH];

    get_user_authid(id, authid, charsmax(authid));

    if( ArrayFindString(g_steamid, authid) )
    {
        server_print("Threat entered the server. Punish him.");
    }

}


iniGetData()
{
    new szConfigsDir[64], szFile[96];

    get_configsdir(szConfigsDir, charsmax(szConfigsDir));
    formatex(szFile, charsmax(szFile), "%s/%s", szConfigsDir, g_steamidfile);

    new hFile = fopen(szFile, "rt");

    if (!hFile)
        return;

    new szLine[35];

    while (!feof(hFile) && g_iSteamIdCount < MAX_PLAYERS)
    {
        fgets(hFile, szLine, charsmax(szLine));
        trim(szLine);

        if (!szLine[0] || szLine[0] == ';' || (szLine[0] == '/' && szLine[2] == '/'))
            continue;

        g_iSteamIdCount++;
        ArrayPushString(g_steamid, szLine);
    }

    fclose(hFile);
}  