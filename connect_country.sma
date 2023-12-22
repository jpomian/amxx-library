#include < amxmodx >
#include < sxgeo >
#include < colorchat >

#define VIP ADMIN_LEVEL_H
#define is_admin(%1) (get_user_flags(%1) & ADMIN_KICK)
#define SFX_PATH "bhz_custom/enter.wav"

new g_pcvar_amx_language;
new g_bShowDetails[33] = false;

public plugin_init( )
{
	register_plugin( "Announce Connection", "1.1a", "xPaw ft. Mixtaz" );

	g_pcvar_amx_language = get_cvar_pointer("amx_language");

	register_clcmd("say /playerinfo", "togglePlayerInfo");
}
public plugin_precache ( )
{
	precache_sound(SFX_PATH);
}

public client_putinserver( id )
{
	if(!is_user_connected(id))
		return 0;

	new szLanguage[3];
	get_pcvar_string(g_pcvar_amx_language, szLanguage, charsmax(szLanguage));

	new szName[ 32 ], szIP[ 16 ], szCode[ 6 ], szShortCode[ 3 ];
	new szCountry[64], szRegion[64], szCity[64];
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIP, 15, 1 );

	new bool:bCountryFound = sxgeo_country(szIP, szCountry, charsmax(szCountry), /*use lang serveer*/ szLanguage);
	new bool:bRegionFound  = sxgeo_region (szIP, szRegion,  charsmax(szRegion),  /*use lang server*/ szLanguage);
	new bool:bCityFound    = sxgeo_city   (szIP, szCity,    charsmax(szCity),    /*use lang server*/ szLanguage);
	sxgeo_code(szIP, szShortCode);
	
	if(bCountryFound)
		ColorChat(0, TEAM_COLOR, "[System] [%s]^x01 %s ^x01 wszedl na serwer.", szShortCode, szName);
	else
		ColorChat(0, TEAM_COLOR, "[System]^x01 %s^x04 [--]^x01 wszedl na serwer.", szName);
		

	for(new i=1; i<get_maxplayers();i++) {
        if(is_admin(i) && g_bShowDetails[i])
            ColorChat(i, GREEN, "[AdminLog]^x01 Gracz %s polaczyl sie z^x04 %s (%s, %s)", szName, bCityFound ? szCity : "N/A", bRegionFound ? szRegion : "N/A", bCountryFound ? szCountry : "N/A");
    }

	emit_sound( 0, CHAN_VOICE, SFX_PATH, 1.0, ATTN_NORM, 0, PITCH_NORM )

	return PLUGIN_CONTINUE;
}

public togglePlayerInfo(id)
{
    if(!is_admin(id))
        return PLUGIN_HANDLED;

    g_bShowDetails[id] = !g_bShowDetails[id];
    ColorChat(id, GREEN, "[AdminLog]^x01 Zmieniono tryb wyswietlania lokalizacji.");

    return PLUGIN_HANDLED;
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
