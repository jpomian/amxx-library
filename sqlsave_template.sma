#include < amxmodx >
#include < sqlx >

new sqlConfig[ ][ ] = {
	"sql.pukawka.pl",
	"898035",
	"zmKOLOSEUM",
	"898035_hs"
}

enum playerData {
	SteamID[ 33 ],
	IP[ 16 ],
	Nick[ 64 ],
	HS
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
	query = SQL_PrepareQuery( link, "CREATE TABLE IF NOT EXISTS `players_hs` (\
		`id` int(11) NOT NULL AUTO_INCREMENT,\
		`steamid` varchar(33) NOT NULL,\
		`nick` varchar(64) NOT NULL,\
		`ip` varchar(16) NOT NULL,\
		`hs` int(16) NOT NULL,\
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
	register_plugin( "Zapis HS", "1.0", "AMXX.pl" );
	register_event( "DeathMsg", "eventDeathMsg", "ae" );
	
	set_task( 0.1, "SqlInit" );
}

public eventDeathMsg( ) {
	if( read_data( 3 ) ) {
		gPlayer[ read_data( 1 ) ][ HS ]++;
	}	
}

public client_connect( id ) {
	gPlayer[ id ][ HS ] = 0;	
	get_user_authid( id, gPlayer[ id ][ SteamID ], 32 );
	get_user_ip( id, gPlayer[ id ][ IP ], 15, 1 );
	get_user_name( id, gPlayer[ id ][ Nick ], 63 );	
	SQL_PrepareString( gPlayer[ id ][ Nick ], gPlayer[ id ][ Nick ], 63 );
}

public client_disconnect( id ) {
	save( id );	
	gPlayer[ id ][ HS ] = 0;
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
	formatex( query, charsmax( query ), "INSERT IGNORE INTO `players_hs` ( `steamid`, `nick`, `ip`, `hs`) VALUES ( '%s', '%s', '%s', %d ) ON DUPLICATE KEY UPDATE `hs` = `hs` + %d", 
	gPlayer[ id ][ SteamID ], gPlayer[ id ][ Nick ], gPlayer[ id ][ IP ], gPlayer[ id ][ HS ] );
	
	if( gSqlTuple )
		SQL_ThreadQuery (gSqlTuple, "Query", query );
}