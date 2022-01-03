#include < amxmodx >
#include < GeoIP >
#include < Achievements >
#include < ColorChat >

new g_iAchievements;

#define VIP ADMIN_LEVEL_H

public plugin_init( )
{
	register_plugin( "Connect Announcer", "1.0", "xPaw" );
}
public plugin_precache ( )
{
	precache_sound("duch/coin.wav");
}
public plugin_cfg( )
{
	g_iAchievements = GetUnlocksCount( 0 );
	
	if( !g_iAchievements ) g_iAchievements = 1; // divide by zero
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	new szName[ 32 ], szIP[ 16 ], szCode[ 3 ];
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIP, 15, 1 );
	
	if( !geoip_code2_ex( szIP, szCode ) )
	{
		szCode[ 0 ] = '-';
		szCode[ 1 ] = '-';
	}
	
	new iCount = GetUnlocksCount( id );

	if(get_user_flags(id) &~ ADMIN_BAN)
	{
		if( iConnects ) { 
			ColorChat(0, RED, "[Osiagniecia] %s %s^x04 [%s]^x01 wszedl na serwer. Osiagniecia:^x04 %i/%i", get_user_flags(id) & VIP ? "VIP" : "^x01Gracz", szName, szCode, iCount, g_iAchievements);
		} else {
			ColorChat(0, RED, "[Osiagniecia] %s %s^x04 [%s]^x01 wszedl na serwer.", get_user_flags(id) & VIP ? "VIP" : "^x01Gracz", szName, szCode);
		}

		emit_sound( 0, CHAN_VOICE, "duch/coin.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
