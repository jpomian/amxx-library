#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

new const VERSION[ ] = "1.3.1"
new const TRKCVAR[ ] = "specinfo_version"
#define IMMUNE_FLAG ADMIN_IMMUNITY
#define HIDDEN_FLAG ADMIN_BAN

#define KEYS_STR_LEN 31
#define LIST_STR_LEN 610
#define BOTH_STR_LEN KEYS_STR_LEN + LIST_STR_LEN

//cl_prefs constants
#define FL_LIST    ( 1 << 0 )
#define FL_KEYS    ( 1 << 1 )
#define FL_OWNKEYS ( 1 << 2 )
#define FL_HIDE    ( 1 << 3 )

//cvar pointers
new p_enabled, p_list_enabled, p_keys_enabled, p_list_default;
new p_red, p_grn, p_blu, p_immunity;
new g_hudSync;

//data arrays
new cl_keys[33], cl_prefs[33];
new keys_string[33][KEYS_STR_LEN + 1], list_string[33][LIST_STR_LEN + 1]
new cl_names[33][21], spec_ids[33][33];


public plugin_init( )
{
	register_plugin( "SpecInfo", VERSION, "Ian Cammarata" );
	register_cvar( TRKCVAR, VERSION, FCVAR_SERVER );
	set_cvar_string( TRKCVAR, VERSION );
	
	p_enabled = register_cvar( "si_enabled", "1" );
	p_list_enabled = register_cvar( "si_list_enabled", "1" );
	p_keys_enabled = register_cvar( "si_keys_enabled", "1" );
	p_list_default = register_cvar( "si_list_default", "1" );
	p_immunity = register_cvar( "si_immunity", "1" );
	p_red = register_cvar( "si_msg_r", "45" );
	p_grn = register_cvar( "si_msg_g", "89" );
	p_blu = register_cvar( "si_msg_b", "116" );
	
	register_clcmd( "say /speclist", "toggle_list", _, "Toggle spectator list." );
	register_clcmd( "say /speckeys", "toggle_keys", HIDDEN_FLAG, "Toggle spectator keys." );
	register_clcmd( "say /showkeys", "toggle_ownkeys", IMMUNE_FLAG, "Toggle viewing own keys." );
	register_clcmd( "say /spechide", "toggle_hide", HIDDEN_FLAG, "Admins toggle being hidden from list." );
	
	set_task( 1.0, "list_update", _, _, _, "b" );
	set_task( 0.1, "keys_update", _, _, _, "b" );
	
	register_dictionary( "specinfo.txt" );

	g_hudSync = CreateHudSyncObj();
}

public client_connect( id )
{
	cl_prefs[id] = 0;
	if( !is_user_bot( id ) )
	{
		if( get_pcvar_num( p_list_default ) ) cl_prefs[id] |= FL_LIST;
		// if( get_pcvar_num( p_immunity ) ) cl_prefs[id] |= FL_HIDE;
	}
	get_user_name( id, cl_names[id], 20 );
	return PLUGIN_CONTINUE;
}

public client_infochanged( id )
{
	get_user_name( id, cl_names[id], 20 );
	return PLUGIN_CONTINUE;
}

public list_update( )
{
	if( get_pcvar_num( p_enabled ) && get_pcvar_num ( p_list_enabled ) )
  {
		new players[32], num, id, id2, i, j;
		for( i = 1; i < 33; i++ ) spec_ids[i][0] = 0;
		
		get_players( players, num, "bch" );
		for( i = 0; i < num; i++ )
    {
			id = players[i];
			if( !( get_user_flags( id ) & HIDDEN_FLAG && get_pcvar_num( p_immunity ) && cl_prefs[id] & FL_HIDE ) )
			{
				id2 = pev( id, pev_iuser2 );
				if( id2 )
				{
					spec_ids[ id2 ][ 0 ]++;
					spec_ids[ id2 ][ spec_ids[ id2 ][ 0 ] ] = id;
				}
			}
		}
		new tmplist[ LIST_STR_LEN + 1 ], tmpstr[41];
		new count, namelen, tmpname[21];
		for( i=1; i<33; i++ )
    {
			count = spec_ids[i][0];
			if( count )
			{
				namelen = ( LIST_STR_LEN - 10 ) / count;
				clamp( namelen, 10, 20 );
				format( tmpname, namelen, cl_names[i] );
				formatex( tmplist, LIST_STR_LEN - 1, "^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t (%i) %s %s :^n", count, "%L", tmpname);
				for( j=1; j<=count; j++ )
        {
					format( tmpname, namelen, cl_names[spec_ids[i][j]]);
					formatex( tmpstr, 40, "^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t^t%s", tmpname );
					if( strlen( tmplist ) + strlen( tmpstr ) + ( 11 - j ) < ( LIST_STR_LEN - 1 ) )
						format( tmplist, LIST_STR_LEN - 10, "%s%s^n", tmplist, tmpstr );
					else
          {
						format( tmplist, LIST_STR_LEN, "%s...^n", tmplist );
						break;
					}
				}
				if( count < 10 )
          format( tmplist, LIST_STR_LEN,
						"%s^n^n",
						tmplist
					);
				for( j+=0; j<10; j++ )
          format( tmplist, LIST_STR_LEN, "%s%s", tmplist, "^n" );
				list_string[i] = tmplist;
			}
		}
		get_players( players, num, "ch" );
		for( i=0; i<num; i++ ) clmsg( players[i] );
	}
	return PLUGIN_HANDLED;
}

public keys_update( )
{
	if( !get_pcvar_num( p_enabled ) && !get_pcvar_num( p_keys_enabled ) ) return;

	new players[32], num, id, i;
	get_players( players, num, "a" );
	for( i = 0; i < num; i++ )
  {
		id = players[i];
		formatex( keys_string[id], KEYS_STR_LEN, " ^n^t^t%s^t^t^t%s^n^t%s %s %s^t^t%s",
			cl_keys[id] & IN_FORWARD ? "W" : " .",
			"%L",
			cl_keys[id] & IN_MOVELEFT ? "A" : ".",
			cl_keys[id] & IN_BACK ? "S" : ".",
			cl_keys[id] & IN_MOVERIGHT ? "D" : ".",
			"%L"
		);
		
		//Flags stored in string to fill translation char in clmsg function
		keys_string[id][0] = 0; 
		if( cl_keys[id] & IN_JUMP ) keys_string[id][0] |= IN_JUMP;
		if( cl_keys[id] & IN_DUCK ) keys_string[id][0] |= IN_DUCK;
		
		cl_keys[id] = 0;

	}
	
	new id2;
	get_players( players, num, "ch" );
	for( i=0; i<num; i++ )
  {
		id = players[i];

		if( is_user_alive( id ) )
		{
			if( cl_prefs[id] & FL_OWNKEYS ) clmsg( id );
		}
		else
		{
			id2 = pev( id, pev_iuser2 );
			if( cl_prefs[id] & FL_KEYS && id2 && id2 != id ) clmsg( id );
		}
	}

}

public server_frame( )
{
	if( get_pcvar_num( p_enabled ) && get_pcvar_num( p_keys_enabled ) )
  {
		new players[32], num, id;
		get_players( players, num, "a" );
		for( new i = 0; i < num; i++ )
		{
			id = players[i];
			if( get_user_button( id ) & IN_FORWARD )
				cl_keys[id] |= IN_FORWARD;
			if( get_user_button( id ) & IN_BACK )
				cl_keys[id] |= IN_BACK;
			if( get_user_button( id ) & IN_MOVELEFT )
				cl_keys[id] |= IN_MOVELEFT;
			if( get_user_button( id ) & IN_MOVERIGHT )
				cl_keys[id] |= IN_MOVERIGHT;
			if( get_user_button( id ) & IN_DUCK )
				cl_keys[id] |= IN_DUCK;
			if( get_user_button( id ) & IN_JUMP )
				cl_keys[id] |= IN_JUMP;
		}
	}
	return PLUGIN_CONTINUE
}

public clmsg( id )
{
	if( !id ) return;
	
	new prefs = cl_prefs[id];
	
	new bool:show_own = false;
	if( is_user_alive( id ) && prefs & FL_OWNKEYS ) show_own = true;
	
	if( is_user_alive( id ) && !show_own )
  {
		if( prefs & FL_LIST && spec_ids[id][0] && get_pcvar_num( p_list_enabled ) )
		{
			set_hudmessage(
        get_pcvar_num( p_red ),
        get_pcvar_num( p_grn ),
        get_pcvar_num( p_blu ),
        0.75, /*x*/
        0.15, /*y*/
        0, /*fx*/
        0.0, /*fx time*/
        1.1, /*hold time*/
        0.0, /*fade in*/
        0.0, /*fade out*/
        -1 /*chan*/
			);
			ShowSyncHudMsg(id, g_hudSync, list_string[id], id, "SPECTATING");
		}
	}
	else
  {
		new id2;
		if( show_own ) id2 = id;
		else id2 = pev( id, pev_iuser2 );
		if( !id2 ) return;
		
		if( prefs & FL_LIST || prefs & FL_KEYS || show_own )
    {
			set_hudmessage(
        get_pcvar_num( p_red ),
        get_pcvar_num( p_grn ),
        get_pcvar_num( p_blu ),
        0.48, /*x*/
        0.14, /*y*/
        0, /*fx*/
        0.0, /*fx time*/
        prefs & FL_KEYS || show_own ? 0.1 : 1.1, /*hold time*/
        0.1, /*fade in*/
        0.1, /*fade out*/
        3 /*chan*/
			);
			new msg[BOTH_STR_LEN + 1];
			if( prefs & FL_LIST && get_pcvar_num( p_list_enabled ) && spec_ids[id2][0] )
        formatex(msg,BOTH_STR_LEN,list_string[id2],id,"SPECTATING");
			else msg ="^n^n^n^n^n^n^n^n^n^n^n^n";
			if( get_pcvar_num( p_keys_enabled ) && ( prefs & FL_KEYS || show_own ) )
      {
        format( msg, BOTH_STR_LEN, "%s%s", msg, keys_string[id2][1] );
        format( msg, BOTH_STR_LEN, msg,
					id, keys_string[id2][0] & IN_JUMP ? "JUMP" : "LAME",
					id, keys_string[id2][0] & IN_DUCK ? "DUCK" : "LAME"
				);
      }
			ShowSyncHudMsg(id, g_hudSync, msg)
		}
	}
}

public set_hudmsg_flg_notify( )
{
	set_hudmessage(
		get_pcvar_num( p_red ),
		get_pcvar_num( p_grn ),
		get_pcvar_num( p_blu ),
		-1.0, /*x*/
		0.8, /*y*/
		0, /*fx*/
		0.0, /*fx time*/
		3.0, /*hold time*/
		0.0, /*fade in*/
		0.0, /*fade out*/
		-1 /*chan*/
	);
}

public toggle_list( id )
{
	set_hudmsg_flg_notify( );
	cl_prefs[id] ^= FL_LIST;
	show_hudmessage( id, "%L", id, cl_prefs[id] & FL_LIST ? "SPEC_LIST_ENABLED" : "SPEC_LIST_DISABLED" );
	return PLUGIN_HANDLED;
}

public toggle_keys( id )
{
	set_hudmsg_flg_notify( );
	cl_prefs[id] ^= FL_KEYS;
	show_hudmessage( id, "%L", id, cl_prefs[id] & FL_KEYS ? "SPEC_KEYS_ENABLED" : "SPEC_KEYS_DISABLED" );
	return PLUGIN_HANDLED;
}

public toggle_ownkeys( id )
{
	set_hudmsg_flg_notify( );
	cl_prefs[id] ^= FL_OWNKEYS;
	show_hudmessage( id, "%L", id, cl_prefs[id] & FL_OWNKEYS ? "SPEC_OWNKEYS_ENABLED" : "SPEC_OWNKEYS_DISABLED" );
	return PLUGIN_HANDLED;
}

public toggle_hide( id, level, cid )
{
	if( cmd_access( id, level, cid, 0 ) )
	{
		set_hudmsg_flg_notify( );
		cl_prefs[id] ^= FL_HIDE;
		show_hudmessage( id, "%L", id, cl_prefs[id] & FL_HIDE ? "SPEC_HIDE_ENABLED" : "SPEC_HIDE_DISABLED" );
	}
	return PLUGIN_HANDLED;
}