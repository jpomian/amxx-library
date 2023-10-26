#include < amxmodx >

#define PLUGIN_VERSION "1.1"

#define TASK_FREQ 2.0 

#define isThreat(%1) equal(%1, g_szThreatActorSID)

new Trie:g_tCvars;

const g_iFpsMax = 100;
const g_iFpsOverride = 0;

new const g_szThreatActorSID[] = "STEAM_0:1:122354662";
new g_szAuthID[ 32 ]

public plugin_cfg( )
{
    g_tCvars = TrieCreate( );

    new szFpsMax[ 3 ], szFpsOverride[ 1 ];
    num_to_str( g_iFpsMax, szFpsMax, charsmax( szFpsMax ) );
    num_to_str( g_iFpsOverride, szFpsOverride, charsmax( szFpsOverride ) );
    
    TrieSetString( g_tCvars, "fps_max", szFpsMax );
    TrieSetString( g_tCvars, "fps_override", szFpsOverride );
    
    set_task( TASK_FREQ, "OnTaskCheckCvars", _, _, _, "b" );
}

public plugin_init( )
{
    register_plugin( "Fps Limit", PLUGIN_VERSION, "DoNii x Mixtaz" );
    register_cvar( "fps_limit_cvar", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
}

public plugin_end( )
TrieDestroy( g_tCvars );

public client_authorized( id )
{
	get_user_authid(id, g_szAuthID, charsmax(g_szAuthID))

	if(isThreat(g_szAuthID))
		client_print( id, print_console, "Ustaw komendy fps_max 100 i fps_override 0!" );
}

public OnTaskCheckCvars( )
{
    new szPlayers[ 32 ], iNum;
    get_players( szPlayers, iNum, "c" );
    static iTempID;

    for( new i; i < iNum; i++ )
    {
        iTempID = szPlayers[ i ];

        if(isThreat(g_szAuthID))
		{
        	query_client_cvar( iTempID, "fps_max", "OnCvarResult" );
        	query_client_cvar( iTempID, "fps_override", "OnCvarResult" );
		}
    }
}

public OnCvarResult( id, const szCvar[ ], const szValue[ ] )
{ 
    new szValueCheck[ 4 ], szReason[ 128 ];
    TrieGetString( g_tCvars, szCvar, szValueCheck, charsmax( szValueCheck ) );
    
    new iValue = str_to_num( szValue );
    
    if( equal( szCvar, "fps_max" ) )
    {    
        if( iValue > g_iFpsMax )
        {
            formatex( szReason, charsmax( szReason ), "^n***************************^n** Ustaw komendy fps_max 100 i fps_override 0! ^n***************************", g_iFpsMax );
            
            server_cmd( "kick #%d", get_user_userid( id ));
            client_print( id, print_console, szReason );
        }
    }
    
    else if( equal( szCvar, "fps_override" ) )
    {
        if( iValue != g_iFpsOverride )
        {
            formatex( szReason, charsmax( szReason ), "^n***************************^n** Ustaw komendy fps_max 100 i fps_override 0! <- **^n***************************", g_iFpsOverride );
            
            server_cmd( "kick #%d", get_user_userid( id ));
            client_print( id, print_console, szReason );
        }
    }
    return PLUGIN_CONTINUE;
}  