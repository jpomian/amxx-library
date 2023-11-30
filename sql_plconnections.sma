#include < amxmodx >
#include < sqlx >

new sqlConfig[ ][ ] = {
	"sql.pukawka.pl",
	"898035",
	"zmKOLOSEUM",
	"898035_connects"
}

enum playerData {
	SteamID[ 33 ],
	IP[ 16 ],
	Nick[ 64 ],
	CON
};

new Handle: gSqlTuple;
new gPlayer[ 33 ][ playerData ];

public SqlInit( ) {
	gSqlTuple = SQL_MakeDbTuple( sqlConfig[ 0 ], sqlConfig[ 1 ], sqlConfig[ 2 ], sqlConfig[ 3 ] );
	
	if( gSqlTuple == Empty_Handle )
		set_fail_state( "Nie mozna utworzyc uchwytu do polaczenia" );
	
	new iErr, szError[ 32 ];
	new Handle:link = SQL_Connect( gSqlTuple, iErr, szError, 31 );
	
	if( link == Empty_Handle ) {
		log_amx( "Error (%d): %s", iErr, szError );
		set_fail_state( "Brak polaczenia z baza danych" );
	}
	
	new Handle: query;
	query = SQL_PrepareQuery( link, "CREATE TABLE IF NOT EXISTS `players_connections` (\
		`id` int(11) NOT NULL AUTO_INCREMENT,\
		`steamid` varchar(33) NOT NULL,\
		`nick` varchar(64) NOT NULL,\
		`ip` varchar(16) NOT NULL,\
		`connections` int(16) NOT NULL,\
		PRIMARY KEY (`id`),\
		UNIQUE KEY `authid` (`nick`)\
	)" );
	
	SQL_Execute( query );
	SQL_FreeHandle( query );
	SQL_FreeHandle( link );
}

public Query( failstate, Handle:query, error[ ] ) {
	if( failstate != TQUERY_SUCCESS ) {
		log_amx( "SQL query error: %s", error );
		return;
	}
}

public plugin_init() {
	register_plugin( "Save Player Connections", "1.0", "Mixtaz" );
	register_clcmd("say /cons", "load")
	set_task( 0.1, "SqlInit" );
}

public client_connect( id ) {
	gPlayer[ id ][ CON ] = 0;	
	get_user_authid( id, gPlayer[ id ][ SteamID ], 32 );
	get_user_ip( id, gPlayer[ id ][ IP ], 15, 1 );
	get_user_name( id, gPlayer[ id ][ Nick ], 63 );	
	SQL_PrepareString( gPlayer[ id ][ Nick ], gPlayer[ id ][ Nick ], 63 );
	gPlayer[ id ][ CON ]++;
}

public client_disconnected( id ) {
	save( id );	
	gPlayer[ id ][ CON ] = 0;
}

public load(id)
{
	new szTemp[512]
	
	new data[1] //Zmiennaq
	data[0] = id // Id gracza 
	
	formatex(szTemp,charsmax(szTemp),"SELECT * FROM `players_connections` WHERE `steamid` = '%s'", gPlayer[ id ][ SteamID ])
	SQL_ThreadQuery(gSqlTuple,"register_client",szTemp, data, sizeof(data))
}

public register_client(failstate, Handle:query, error[],errcode, data[], datasize)
{
	if(failstate != TQUERY_SUCCESS){
		log_amx("<Query> Error: %s", error)
		return;
	}

	new id = data[0], user = data[1], iConnects[33];

	if(get_user_userid(id) != user)
        return;

	if(!is_user_connected(id) && !is_user_connecting(id)) // Gracz nie połączony anuluje akcje
		return;
	
	if(SQL_NumRows(query))
	{
		iConnects[id] = SQL_ReadResult(query, 4)
	}

	client_print(id, print_chat, "Loaded query for player [%s]. Total connects", gPlayer[id][SteamID], iConnects[id])
}
stock SQL_PrepareString( const szQuery[], szOutPut[], size ) {
	copy( szOutPut, size, szQuery );
	replace_all( szOutPut, size, "'", "\'" );
	replace_all( szOutPut, size, "`", "\`" );    
	replace_all( szOutPut, size, "\\", "\\\\" );
	replace_all( szOutPut, size, "^0", "\0");
	replace_all( szOutPut, size, "^n", "\n");
	replace_all( szOutPut, size, "^r", "\r");
	replace_all( szOutPut, size, "^x1a", "\Z");	
}

stock save( id ) {
	new query[ 1024 ]	
	formatex( query, charsmax( query ), "INSERT IGNORE INTO `players_connections` ( `steamid`, `nick`, `ip`, `connections`) VALUES ( '%s', '%s', '%s', %d ) ON DUPLICATE KEY UPDATE `connections` = `connections` + %d", 
	gPlayer[ id ][ SteamID ], gPlayer[ id ][ Nick ], gPlayer[ id ][ IP ], gPlayer[ id ][ CON ], gPlayer[ id ][ CON ] );
	
	if( gSqlTuple )
		SQL_ThreadQuery (gSqlTuple, "Query", query );
}