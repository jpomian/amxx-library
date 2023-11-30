#include <amxmodx>
#include <colorchat>
#include <hamsandwich>
#include <fun>
#include <biohazard>

#define PLUGIN "BestPlayer"
#define VERSION "1.0"
#define AUTHOR "Mixtaz"

new Damage[33];
new g_Bestdmg, g_Bestdmgid
new g_iMaxPlayers;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "eHLTV", "a", "1=0", "2=0");
	register_logevent("wiadomosc",2,"1=Round_End")
	RegisterHam(Ham_TakeDamage, "player", "ForwardPlayerDmg", 1);
	g_iMaxPlayers = get_maxplayers();
}
public plugin_natives()
{
	register_native("get_id_bestplayer", "return_bestplayer", 1)
}
public return_bestplayer(id)
{
	return g_Bestdmgid;
}
public ForwardPlayerDmg(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits)
 {
	if(is_user_connected(iAttacker) && iAttacker != iVictim)
		Damage[iAttacker] += floatround(fDamage);

}
public wiadomosc() 
{ 
	if(get_playersnum() < 2)
		return
	
	g_Bestdmg = 0, g_Bestdmgid = 0;
	
	for(new i=1; i<= g_iMaxPlayers; i++)
	{
		if(is_user_connected(i))
		{
			if(!is_user_zombie(i) && Damage[i] > g_Bestdmg)
			{
				g_Bestdmg = Damage[i];
				g_Bestdmgid = i;
			}
		}
	}
	
	if(!g_Bestdmgid)
		return;
	
	new name[32];
	get_user_name(g_Bestdmgid, name, 31);
	ColorChat(0, GREEN, "[Biohazard] ^x01Najwiecej obrazen zadal ^x04%s ^x01(^x04%d^x01 obrazen).", name, g_Bestdmg);
}
public eHLTV()
{
	for( new i = 1 ; i <= g_iMaxPlayers ; i++ )
	{
		Damage[i] = 0;
	}
}