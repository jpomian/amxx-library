#include <amxmodx>
#include <cstrike>
#include <achs>

new g_achsArray[40];

public plugin_init() {
            register_plugin("achy", "1.0", "Fili:P")
            //pluginy
            g_achsArray[0] = ach_add("Staly bywalec", "Polacz sie z serwerem 1000 razy", 1000);
            g_achsArray[1] = ach_add( "Dobry start", "Wygraj 10 rund", 10 );
            g_achsArray[2] = ach_add( "Weteran", "Wygraj 250 rund", 250 );
            g_achsArray[3] = ach_add( "Sztuka wojny", "Zrob spreja 100 razy", 100 );

            //eventy
            register_event( "SendAudio", "EventSendAudio", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin" );
}

public client_putinserver(id)
{
			ach_add_status(id, g_achsArray[0], 1);
}

public EventSendAudio( )
{
	if( get_playersnum( ) < 4 ) return;
	
	new iPlayers[ 32 ], iNum, id;
	read_data( 2, iPlayers, 8 );
	
	new CsTeams:iWinner = iPlayers[ 7 ] == 't' ? CS_TEAM_T : CS_TEAM_CT;
	
	get_players( iPlayers, iNum, "c" );
	
	for( new i; i < iNum; i++ )
	{
		id = iPlayers[ i ];
		
		if( is_user_alive( id ) && cs_get_user_team( id ) == iWinner )
		{
			ach_add_status(id, g_achsArray[1], 1);
			ach_add_status(id, g_achsArray[2], 1);
			
			/*if( g_flGrenade[ id ] >= 3000.0 )
			{
				AchievementProgress( id, ACH_3000HEDMG );
			}*/
		}
	}
}