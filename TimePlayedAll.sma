#include <amxmodx>
#include <nvault>
#include <sqlx>
#include <unixtime>
#include <fakemeta>
#include <cromchat>

new const Version[ ] = "1.1.2";

#if !defined client_disconnected
	#define client_disconnected client_disconnect
#endif

#if !defined MAX_PLAYERS
	const MAX_PLAYERS = 32
#endif

#if !defined MAX_NAME_LENGTH
	const MAX_NAME_LENGTH = 32
#endif

#if !defined MAX_AUTHID_LENGTH
	const MAX_AUTHID_LENGTH = 64
#endif

#if !defined MAX_IP_LENGTH
	const MAX_IP_LENGTH = 16
#endif

#if !defined MAX_FMT_LENGTH
	const MAX_FMT_LENGTH = 192
#endif

const MAX_QUERY_LENGTH = 256;
const MAX_TIME_LENGTH = 22;
const TASK_TIME_PLAYED = 969969;

new const SQL_HOST[ ] = "sql.pukawka.pl"
new const SQL_USER[ ] = "898035"
new const SQL_PASS[ ] = "zmKOLOSEUM"
new const SQL_DATABASE[ ] = "898035_czasy"
new const SQL_TABLE[ ] = "TimePlayed"
new const NVAULT_DATABASE[ ] = "TimePlayed"

enum DataTypes
{
	SAVE,
	LOAD,
	RESET,
	UPDATE
}

enum _:SaveTypes
{
	NICKNAME,
	IP,
	STEAMID
}

enum _:SaveMethods
{
	Nvault,
	MySQL,
	SQLite
}

enum PlayerData
{ 
	AuthInfo[ MAX_AUTHID_LENGTH ],
	NickInfo[ MAX_NAME_LENGTH ],
	IpInfo[ MAX_IP_LENGTH ],
	Time_Played,
	First_Seen,
	Last_Seen,
	bool:BotOrHLTV
}

new g_iPlayer[ MAX_PLAYERS + 1 ][ PlayerData ],
	g_iVault,
	g_cSaveMethod,
	g_iFUserNameChanged,
	Handle:g_SQLTuple,
	g_szSQLError[ MAX_QUERY_LENGTH ];

public plugin_init( ) 
{
	register_plugin( "Time Played", Version, "Supremache" )
	register_cvar( "TimePlayed", Version, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED )
	CC_SetPrefix( "^4[Konkurs]" );
	
	g_cSaveMethod = register_cvar( "tp_save_method", "1" ) // How to save player's preferences: 0 = nVault | 1 = MySQL | 2 = SQLite
	// g_cSaveType = register_cvar( "tp_save_type", "2" ) // ; Savve player's data:  0 = Name | 1= IP | 2 = SteamID
	
	register_event( "SayText", "OnSayText", "a", "2=#Cstrike_Name_Change" )
	
	switch( get_pcvar_num( g_cSaveMethod ) )
	{
		case Nvault:
		{
			if ( ( g_iVault = nvault_open( NVAULT_DATABASE ) ) == INVALID_HANDLE )
				set_fail_state("Time Played: Failed to open the vault.");
		}
		case MySQL, SQLite: 
		{
			if( get_pcvar_num( g_cSaveMethod ) == SQLite )
				SQL_SetAffinity( "sqlite" );
				
			g_SQLTuple = SQL_MakeDbTuple( SQL_HOST, SQL_USER, SQL_PASS, SQL_DATABASE );
			    
			new szQuery[ MAX_QUERY_LENGTH ], Handle:SQLConnection, iErrorCode;
			SQLConnection = SQL_Connect( g_SQLTuple, iErrorCode, g_szSQLError, charsmax( g_szSQLError ) );
			    
			if( SQLConnection == Empty_Handle )
				set_fail_state( g_szSQLError );
	
			formatex( szQuery, charsmax( szQuery ), "CREATE TABLE IF NOT EXISTS `%s` (\
			`Auth` VARCHAR(%i) NOT NULL,\
			`Nick` VARCHAR(%i) NOT NULL,\
			`IP` VARCHAR(%i) NOT NULL,\
			`Time Played` INT(%i) NOT NULL,\
			`First Seen` INT(%i) NOT NULL,\
			`Last Seen` INT(%i) NOT NULL,\
			PRIMARY KEY (Auth));",\
			SQL_TABLE, MAX_AUTHID_LENGTH, MAX_NAME_LENGTH, MAX_IP_LENGTH, MAX_TIME_LENGTH, MAX_TIME_LENGTH, MAX_TIME_LENGTH );
			

			RunQuery( SQLConnection, szQuery, g_szSQLError, charsmax( g_szSQLError ) );
		}
	}
	
	register_clcmd( "say", "@OnSay" )
	register_clcmd( "say_team", "@OnSay" )
}

public OnSayText( iMsg, iDestination, iEntity )
{
	g_iFUserNameChanged = register_forward( FM_ClientUserInfoChanged, "OnNameChange", 1 )
}

public OnNameChange( id )
{
	if( !is_user_connected( id ) )
	{
		return;
	}

	new szName[ MAX_NAME_LENGTH ]
	get_user_name( id, szName, charsmax( szName ) )

	ReadData( id, SAVE );
	copy( g_iPlayer[ id ][ NickInfo ], charsmax( g_iPlayer[ ][ NickInfo ] ), szName )

	if( get_pcvar_num( g_cSaveMethod ) != Nvault )
	{
		ReadData( id, RESET );
	}
		
	ReadData( id, LOAD );
	ReadData( id, UPDATE );

	unregister_forward( FM_ClientUserInfoChanged, g_iFUserNameChanged , 1 )
}

public client_connect( id )
{
	if( !( g_iPlayer[ id ][ BotOrHLTV ] = bool:( is_user_bot( id ) || is_user_hltv( id ) ) ) )
	{
		ReadData( id, RESET );
		
		get_user_name( id, g_iPlayer[ id ][ NickInfo ], charsmax( g_iPlayer[ ][ NickInfo ] ) )
		get_user_ip( id, g_iPlayer[ id ][ IpInfo ], charsmax( g_iPlayer[ ][ IpInfo ] ), 1 )
		get_user_authid( id, g_iPlayer[ id ][ AuthInfo ], charsmax( g_iPlayer[ ][ AuthInfo ] ) )
		
		ReadData( id, LOAD );
		ReadData( id, UPDATE );
	}
}

public client_disconnected( id )
{
	if( !g_iPlayer[ id ][ BotOrHLTV ] )
	{
		g_iPlayer[ id ][ Last_Seen ] = get_systime( );
		ReadData( id, SAVE );
	}
}

@OnSay( id )
{
	static szMessage[ MAX_FMT_LENGTH ];
	read_args( szMessage, charsmax( szMessage ) ); remove_quotes( szMessage );
	
	if( equal( szMessage, "/time" ) || equal( szMessage, "/ptime" ) )
	{
		CC_SendMessage( id, "Czas gry:^4 %s", get_time_length_ex( g_iPlayer[ id ][ Time_Played ] ) ) 
	}
	else if( equal( szMessage, "/toptime" ) )
	{
		new website[128];
		formatex(website, charsmax(website), "http://biohazard.gameclan.pl/staty/czas.php");
			
		new motd[256];
		formatex(motd, sizeof(motd) - 1,\
			"<html><head><meta http-equiv=^"Refresh^" content=^"0;url=%s^"></head><body><p><center>LOADING...</center></p></body></html>",\
				website);
    
		show_motd(id, motd);

	}
	else if( equal( szMessage, "/timelist" ) )
	{
		TimeList( id )
	}
}

public ShowTop10( id, Handle:iQuery, const szError[ ], iErrCode, szData[ ], iDataSize )
{
	new szMOTD[ 1536 ] , iPos, iTime, iYear[ 2 ] , iMonth[ 2 ] , iDay[ 2 ] , iHour[ 2 ] , iMinute[ 2 ] , iSecond[ 2 ];

	if( get_pcvar_num( g_cSaveMethod ) )
	{
		iPos = formatex( szMOTD , charsmax( szMOTD ) , "<body bgcolor=#000000><font color=#98f5ff><pre>" );
		iPos += formatex( szMOTD[ iPos ] , charsmax( szMOTD ) - iPos , "%2s %-22.22s %-22.22s %-33.33s %s^n" , "#" , "Nick" , "Time Played" , "Joined Date" , "Last Seen" );
		new iNumResults = SQL_NumResults( iQuery ), szName[ MAX_NAME_LENGTH ];
		
		id = szData[ 0 ];
		
		if( iNumResults ) 
		{
			for(new i; i < min( iNumResults , 10 ); i++)
			{
				SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Nick" ), szName, charsmax( szName ) )
				iTime = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Time Played" ) )
				UnixToTime( SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "First Seen" ) ) , iYear[ 0 ] , iMonth[ 0 ] , iDay[ 0 ] , iHour[ 0 ] , iMinute[ 0 ] , iSecond[ 0 ] );
				UnixToTime( SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Last Seen" ) ), iYear[ 1 ] , iMonth[ 1 ] , iDay[ 1 ] , iHour[ 1 ] , iMinute[ 1 ] , iSecond[ 1 ] );
				if( iTime < 60 )
				{
					iPos += formatex( szMOTD[ iPos ] , charsmax( szMOTD ) - iPos ,"%2d %-22.22s %d %-22.22s %s %d, %d at %02d:%02d:%-11.11d %s %d, %d at %02d:%02d:%02d^n",
					( i + 1 ) , szName, iTime, "Secounds",
					str_to_month( iMonth[ 0 ] ) , iDay[ 0 ] , iYear[ 0 ] , iHour[ 0 ] , iMinute[ 0 ] , iSecond[ 0 ],
					str_to_month( iMonth[ 1 ] ) , iDay[ 1 ] , iYear[ 1 ] , iHour[ 1 ] , iMinute[ 1 ] , iSecond[ 1 ] );
				}
				else
				{
					iPos += formatex( szMOTD[ iPos ] , charsmax( szMOTD ) - iPos ,"%2d %-22.22s %d %-22.22s %s %d, %d at %02d:%02d:%-11.11d %s %d, %d at %02d:%02d:%02d^n",
					( i + 1 ) , szName, iTime / 60, "Minutes",
					str_to_month( iMonth[ 0 ] ) , iDay[ 0 ] , iYear[ 0 ] , iHour[ 0 ] , iMinute[ 0 ] , iSecond[ 0 ],
					str_to_month( iMonth[ 1 ] ) , iDay[ 1 ] , iYear[ 1 ] , iHour[ 1 ] , iMinute[ 1 ] , iSecond[ 1 ] );
				}
				SQL_NextRow( iQuery );
			}
		}
	}
   
	formatex( szMOTD[ iPos ], charsmax( szMOTD ) - iPos , "</body></font></pre>" );
	    
	show_motd( id , szMOTD , "Top 10 czasu" );
	    
	return PLUGIN_HANDLED;
}

public TimeList( id )
{
	new iPlayers[ MAX_PLAYERS ], iNum, iMenu = menu_create( "Time List:", "TimeHandler" );
	get_players( iPlayers, iNum, "ch" ); SortCustom1D( iPlayers, iNum, "CompareTime" );
	
	for( new szData[ 64 ], szName[ MAX_NAME_LENGTH ], szTime[ MAX_TIME_LENGTH ], iPlayer, i; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		format_time( szTime, charsmax( szTime ), "%m/%d/%Y %H:%M:%S", g_iPlayer[ iPlayer ][ First_Seen ] )
		
		if( g_iPlayer[ iPlayer ][ Time_Played ] < 60 )
		{
			formatex( szData, charsmax( szData ), "\y%s\w Czas:\r %i s\w Dołączono:\r %s", szName, g_iPlayer[ iPlayer ][ Time_Played ], szTime )
		}
		else 
		{
			formatex( szData, charsmax( szData ), "\y%s\w Czas:\r %i m\w Dołączono:\r %s", szName, g_iPlayer[ iPlayer ][ Time_Played ] / 60, szTime )
		}
		
		menu_additem( iMenu, szData )
	}
	menu_display( id, iMenu );
	return PLUGIN_HANDLED;
}

public TimeHandler( id, iMenu, iItem ) 
{
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

ReadData( const id, DataTypes:iType )
{
	new szQuery[ MAX_QUERY_LENGTH ];

	switch( iType )
	{
		case SAVE:
		{
			switch( get_pcvar_num( g_cSaveMethod ) )
			{
				case Nvault:
				{
					formatex( szQuery , charsmax( szQuery ), "%i %i %i", g_iPlayer[ id ][ Time_Played ], g_iPlayer[ id ][ First_Seen ], g_iPlayer[ id ][ Last_Seen ]);
					nvault_set( g_iVault, g_iPlayer[ id ][ AuthInfo ], szQuery )
				}
				case MySQL, SQLite:
				{
					
					formatex( szQuery , charsmax( szQuery ), "REPLACE INTO `%s` (`Auth`,`Nick`,`IP`,`Time Played`,`First Seen`,`Last Seen`) VALUES ('%s','%s','%s','%i','%i','%i');",\
					SQL_TABLE, g_iPlayer[ id ][ AuthInfo ], g_iPlayer[ id ][ NickInfo ], g_iPlayer[ id ][ IpInfo ], g_iPlayer[ id ][ Time_Played ], g_iPlayer[ id ][ First_Seen ], g_iPlayer[ id ][ Last_Seen ] );
					SQL_ThreadQuery( g_SQLTuple, "QueryHandle", szQuery );
				}
			}
		}
		
		case LOAD:
		{
			switch( get_pcvar_num( g_cSaveMethod ) )
			{
				case Nvault:
				{
					new szVaultData[ 3 ][ MAX_TIME_LENGTH ];
					nvault_get( g_iVault, g_iPlayer[ id ][ AuthInfo ], szQuery, charsmax( szQuery ) )
					parse( szQuery, szVaultData[ 0 ], charsmax( szVaultData[ ] ), szVaultData[ 1 ], charsmax( szVaultData[ ] ), szVaultData[ 2 ], charsmax( szVaultData[ ] ) )
					
					g_iPlayer[ id ][ Time_Played ] = str_to_num( szVaultData[ 0 ] )
					g_iPlayer[ id ][ First_Seen ] = str_to_num( szVaultData[ 1 ] )
					g_iPlayer[ id ][ Last_Seen ] = str_to_num( szVaultData[ 2 ] )
				}
				case MySQL, SQLite:
				{
					formatex( szQuery , charsmax( szQuery ), "SELECT * FROM `%s` WHERE Auth = '%s';", SQL_TABLE, g_iPlayer[ id ][ AuthInfo ] ); //Wczytanie z SID
					new szData[ 1 ]; szData[ 0 ] = id
					SQL_ThreadQuery( g_SQLTuple, "QueryHandle", szQuery, szData, sizeof( szData ) );
				}
			}
		}
		
		case RESET:
		{
			g_iPlayer[ id ][ Time_Played ] = 0;
			g_iPlayer[ id ][ First_Seen ] = 0;
			g_iPlayer[ id ][ Last_Seen ] = 0;
			g_iPlayer[ id ][ BotOrHLTV ] = false;
			remove_task( id + TASK_TIME_PLAYED );
		}
		
		case UPDATE:
		{
			if( !g_iPlayer[ id ][ First_Seen ] ) 
			{
				g_iPlayer[ id ][ First_Seen ] = g_iPlayer[ id ][ Last_Seen ] = get_systime( );
			}
			
			set_task( 1.0, "DisplayTimePlayed", id + TASK_TIME_PLAYED, .flags = "b" );
		}
	}
}

RunQuery( Handle:SQLConnection, const szQuery[ ], szSQLError[ ], iErrLen )
{
	new Handle:iQuery = SQL_PrepareQuery( SQLConnection , szQuery );
	
	if( !SQL_Execute( iQuery ) )
	{
		SQL_QueryError( iQuery, szSQLError, iErrLen );
		set_fail_state( szSQLError );
	}
	
	SQL_FreeHandle( iQuery );
}

public QueryHandle( iFailState, Handle:iQuery, const szError[ ], iErrCode, szData[ ], iDataSize )
{
	switch( iFailState )
	{
		case TQUERY_CONNECT_FAILED: { log_amx( "[SQL Error] Connection failed (%i): %s", iErrCode, szError ); return; }
		case TQUERY_QUERY_FAILED: { log_amx( "[SQL Error] Query failed (%i): %s", iErrCode, szError ); return; }
	}
	
	new id = szData[ 0 ];
	
	if( SQL_NumResults( iQuery ) )
	{
		g_iPlayer[ id ][ Time_Played ] = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Time Played" ) )
		g_iPlayer[ id ][ First_Seen ] = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "First Seen" ) )
		g_iPlayer[ id ][ Last_Seen ] = SQL_ReadResult( iQuery, SQL_FieldNameToNum( iQuery, "Last Seen" ) )
	}
} 

public CompareTime( id, Identity )
{
	return g_iPlayer[ Identity ][ Time_Played ] - g_iPlayer[ id ][ Time_Played ]
}

public DisplayTimePlayed( id )
{
	id -= TASK_TIME_PLAYED

	g_iPlayer[(id)][Time_Played] += (get_user_team(id) == 3 || get_user_team(id) == 4) ? 0 : 1;
}

get_time_length_ex( iTime ) 
{ 
	new szTime[ MAX_FMT_LENGTH ], iYear, iMonth, iWeek, iDay, iHour, iMinute, iSecond;
    
	iTime -= 31536000 * ( iYear = iTime / 31536000 ) 
	iTime -= 2678400 * ( iMonth = iTime / 2678400 ) 
	iTime -= 604800 * ( iWeek = iTime / 604800 ) 
	iTime -= 86400 * ( iDay = iTime / 86400 ) 
	iTime -= 3600 * ( iHour = iTime / 3600 ) 
	iTime -= 60 * ( iMinute = iTime / 60 ) 
	iSecond = iTime 
	
	formatex( szTime, charsmax( szTime ), "%d sekund", iSecond )
	if( iMinute ) format( szTime, charsmax( szTime ), "%d minut %s", iMinute, szTime )
	if( iHour ) format( szTime, charsmax( szTime ), "%d godzin %s", iHour, szTime )
	if( iDay ) format( szTime, charsmax( szTime ), "%d dni %s", iDay, szTime )
	if( iWeek ) format( szTime, charsmax( szTime ), "%d tygodni %s", iWeek, szTime )
	if( iMonth ) format( szTime, charsmax( szTime ), "%d miesiecy %s", iMonth, szTime )
	if( iYear ) format( szTime, charsmax( szTime ), "%d lat %s", iYear, szTime )
    
	return szTime;
}

str_to_month( iMonth )
{
	static szDate[ 32 ];
	
	switch( iMonth )
	{
		case 1: copy( szDate, charsmax( szDate ), "January" )
		case 2: copy( szDate, charsmax( szDate ), "February" )
		case 3: copy( szDate, charsmax( szDate ), "March" )
		case 4: copy( szDate, charsmax( szDate ), "April" )
		case 5: copy( szDate, charsmax( szDate ), "May" )
		case 6: copy( szDate, charsmax( szDate ), "June" )
		case 7: copy( szDate, charsmax( szDate ), "July" )
		case 8: copy( szDate, charsmax( szDate ), "August" )
		case 9: copy( szDate, charsmax( szDate ), "September" )
		case 10: copy( szDate, charsmax( szDate ), "October" )
		case 11: copy( szDate, charsmax( szDate ), "November" )
		case 12: copy( szDate, charsmax( szDate ), "December" )
	}
	return szDate;
}

public plugin_natives( )
{
	register_library("timeplayed");
	register_native( "get_time_played", "_get_time_played" );
	register_native( "get_first_seen", "_get_first_seen" );
	register_native( "get_last_seen", "_get_last_seen" );
}

public _get_time_played( iPlugin, iParams )
{
	return g_iPlayer[ get_param( 1 ) ][ Time_Played ];
}

public _get_first_seen( iPlugin, iParams )
{
	return g_iPlayer[ get_param( 1 ) ][ First_Seen ];
}
public _get_last_seen( iPlugin, iParams )
{
	return g_iPlayer[ get_param( 1 ) ][ Last_Seen ];
}

public plugin_end( )
{
	if( get_pcvar_num( g_cSaveMethod ) )
	{
		SQL_FreeHandle( g_SQLTuple );
	}
	else
	{
		nvault_close( g_iVault );
	}
}
