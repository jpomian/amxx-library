#include < amxmodx >
#include < csx >
#include < colorchat >

#define VIP ADMIN_LEVEL_H
#define is_admin(%1) (get_user_flags(%1) & ADMIN_KICK)
#define SFX_PATH "bhz_custom/enter.wav"

public plugin_init( )
{
	register_plugin( "Announce Connection", "1.1a", "xPaw ft. Mixtaz" );

}
public plugin_precache ( )
{
	precache_sound(SFX_PATH);
}

public client_putinserver( id )
{
	if(!is_user_connected(id))
		return 0;


	new szName[ 32 ], stats[8], body[8], iRank;
	get_user_name( id, szName, 31 );
	
	iRank = get_user_stats(id, stats, body)
	
	if(iRank)
		ColorChat(0, TEAM_COLOR, "[System] ^x01 %s (Ranking: ^x03%i^x01) ^x01 wszedl na serwer.", szName, iRank);
	else
		ColorChat(0, TEAM_COLOR, "[System]^x01 %s wszedl na serwer.", szName);

	emit_sound( 0, CHAN_VOICE, SFX_PATH, 1.0, ATTN_NORM, 0, PITCH_NORM )

	return PLUGIN_CONTINUE;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
