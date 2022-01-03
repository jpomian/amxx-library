#include < amxmodx >
#include < engine >
#include < colorchat >

new g_szName[ 33 ][ 26 ];
new bool:g_bToggle[ 33 ];
new g_Hud;

public plugin_init( ) {
	register_plugin( "Speclist", "1.5", "xPaw" );
	
	register_clcmd( "say /speclist", "CmdSpecList" );
	
	new iEntity = create_entity( "info_target" );
	
	if( !is_valid_ent( iEntity ) )
		return;
	
	entity_set_string( iEntity, EV_SZ_classname, "xpaw_speclist" );
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 4.0 );
	
	register_think( "xpaw_speclist", "FwdThinkSpecList" );
	g_Hud = CreateHudSyncObj()
}

public CmdSpecList( id ) {
	if( g_bToggle[ id ] ) {
		ColorChat( id, RED, "[ZM]^x01 Lista Obserwatorow:^x04 wylaczona." );
		
		g_bToggle[ id ] = false;
	} else {
		ColorChat( id, RED, "[ZM]^x01 Lista Obserwatorow:^x04 wlaczona." );
		
		g_bToggle[ id ] = true;
	}
	return PLUGIN_HANDLED;
}

public FwdThinkSpecList( iEntity ) {
	static szHud[ 1102 ], szName[ 32 ], bool:bSendTo[ 33 ], bool:bSend;
	static iPlayers[ 32 ], iNum, iDead, id, i, i2;

	get_players( iPlayers, iNum, "ch" );
	
	for( i = 0; i < iNum; i++ ) {
		arrayset( bSendTo, false, 33 );
		
		id = iPlayers[ i ];
		
		if( !is_user_alive( id ) )
			continue;
		
		bSend = false;
		if( g_bToggle[ id ] ) bSendTo[ id ] = true;
		
		formatex( szHud, 250, "Obserwatorzy: %s (%i HP) ^n^n", g_szName[ id ], get_user_health(id) );
		
		for( i2 = 0; i2 < iNum; i2++ ) {
			iDead = iPlayers[ i2 ];
			
			if( is_user_alive( iDead ) || get_user_flags( iDead ) & ADMIN_BAN )
				continue;
			
			if( entity_get_int( iDead, EV_INT_iuser2 ) == id ) {
				formatex( szName, 31, "%s^n", g_szName[ iDead ] );
				add( szHud, 1101, szName, 0 );
				
				if( g_bToggle[ iDead ] ) bSendTo[ iDead ] = true;
				if( !bSend ) bSend = true;
			}
		}
		
		if( bSend ) {
			for( i2 = 0; i2 < iNum; i2++ ) {
				id = iPlayers[ i2 ];
				
				if( bSendTo[ id ] ) {
					set_hudmessage( 0, 127, 255, 0.75, 0.15, 0, 0.0, 1.1, 0.0, 0.0, 4 );
					ShowSyncHudMsg( id, g_Hud, szHud );
				}
			}
		}
	}
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
	
	return PLUGIN_CONTINUE;
}

public client_infochanged( id )
	get_user_info( id, "name", g_szName[ id ], 25 );

public client_putinserver( id )
	g_bToggle[ id ] = true;