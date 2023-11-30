#include <amxmodx>
#include <amxmisc>
#include <celltrie>

#define TASK_FREQ 1.0
#define TASKID_CHECK 747
#define MAX_FPS 120
#define OVERRIDE_STATE 0

new Trie:g_tSteamIDs;
new Trie:g_tCvars;
new g_szFile[ 200 ];

new const CFG_FILE_NAME[] = "blacklist.ini" 


public plugin_init() 
{
    register_plugin("Limit FPS from Blacklist", "1.0a", "Bugsy ft. Mixtaz");

    new szConfig[164], szData[ 35 ], szFpsMax[ 3 ], szFpsOverride[ 1 ];
    
    g_tSteamIDs = TrieCreate();
    g_tCvars = TrieCreate();
    
    get_configsdir( szConfig, charsmax(szConfig) )
    formatex( g_szFile, charsmax( g_szFile ), "%s/%s", szConfig, CFG_FILE_NAME);
    
    new f = fopen( g_szFile , "rt" );
    
    while( !feof( f ) )
    {
        fgets( f , szData , charsmax( szData ) );
     
        trim( szData );
        
        if( !szData[0] || szData[0] == ';' || szData[0] == '/' && szData[1] == '/' ) 
            continue;
            
        TrieSetCell( g_tSteamIDs , szData , 1 );
    }

    log_amx("[FPSLimiter] Blacklist loaded from file: %s", g_szFile)
    
    fclose( f );

    num_to_str( MAX_FPS, szFpsMax, charsmax( szFpsMax ) );
    num_to_str( OVERRIDE_STATE, szFpsOverride, charsmax( szFpsOverride ) );
    
    TrieSetString( g_tCvars, "fps_max", szFpsMax );
    TrieSetString( g_tCvars, "fps_override", szFpsOverride );
    
    register_concmd( "amx_addbl" , "AddID" , ADMIN_BAN , "<SteamID> - Add SteamID to blacklist" );
}

public plugin_end( )
{
    TrieDestroy( g_tCvars );
    TrieDestroy( g_tSteamIDs );
}

public client_putinserver( id )
{
    if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id))
        return;

    new szName[ 33 ] , szSteamID[ 35 ];
    
    get_user_name( id , szName , charsmax( szName ) );
    get_user_authid( id , szSteamID , charsmax( szSteamID ) );

    if ( TrieKeyExists( g_tSteamIDs , szSteamID ) )
    {
        server_print("[FPSLimiter] Threat user entered the server. Deploying listener.");

        set_task( TASK_FREQ, "listenOn", TASKID_CHECK+id, _, _, "b" )
    }
}

public client_disconnected(id) remove_task(TASKID_CHECK+id);

public listenOn(id)
{
    id-=TASKID_CHECK

    if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id))
        return;

    query_client_cvar( id, "fps_max", "PlayerPunish" );
    query_client_cvar( id, "fps_override", "PlayerPunish" );
}

public PlayerPunish( id, const szCvar[ ], const szValue[ ] )
{ 
    new szValueCheck[ 4 ], szReason[ 128 ];
    new userid = get_user_userid(id);
    TrieGetString( g_tCvars, szCvar, szValueCheck, charsmax( szValueCheck ) );
    
    new iValue = str_to_num( szValue );
    
    if( equal( szCvar, "fps_max" ) )
    {    
        if( iValue > MAX_FPS )
        {
            formatex( szReason, charsmax( szReason ), "Ustaw komende fps_max na %i!", MAX_FPS );
            
            server_cmd("kick #%d ^"%s^"", userid, szReason);
        }
    }
    
    else if( equal( szCvar, "fps_override" ) )
    {
        if( iValue != OVERRIDE_STATE )
        {
            formatex( szReason, charsmax( szReason ), "Ustaw komende fps_override na %i!", OVERRIDE_STATE );
            
            server_cmd("kick #%d ^"%s^"", userid, szReason);
        }
    }
    return PLUGIN_CONTINUE;
}

public AddID( id , level , cid )
{
    if ( !cmd_access( id , level , cid , 2 ) )
        return PLUGIN_HANDLED;
        
    new szSteamID[ 35 ];

    if ( read_argv( 1 , szSteamID , charsmax( szSteamID ) ) )
    {
        if ( !TrieKeyExists( g_tSteamIDs , szSteamID ) )
        {
            TrieSetCell( g_tSteamIDs , szSteamID , 1 );
            write_file( g_szFile , szSteamID );
            console_print( id , "* Added SteamID ^"%s^" to blacklist." , szSteamID );
        }
        else
        {
            console_print( id , "* SteamID ^"%s^" already exists in blacklist." , szSteamID );
        }
    }
    
    return PLUGIN_HANDLED;
}