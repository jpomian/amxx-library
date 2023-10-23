#include <amxmodx>
#include <colorchat>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN_VERSION "1.2"

enum _:Cvars
{
	gospec_respawn
}

static const spPrefix[] = "[DeathMatch]"

new g_eCvars[Cvars]

new CsTeams:g_iOldTeam[33]

public plugin_init()
{
	register_plugin("GoSpec", PLUGIN_VERSION, "OciXCrom")
	register_cvar("@CRXGoSpec", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("GoSpec.txt")
	
	register_clcmd("say /spec", "GoSpec")
	register_clcmd("say /back", "GoBack")
	
	g_eCvars[gospec_respawn] = register_cvar("gospec_respawn", "0")
}

public GoSpec(id)
{	
	if(get_user_flags(id) & ADMIN_KICK || !is_user_alive(id))
	{
		new CsTeams:iTeam = cs_get_user_team(id)

		if(iTeam == CS_TEAM_SPECTATOR)
			ColorChat(id, GREEN, "%s ^x01Jestes juz widzem.", spPrefix)
		else
		{
			g_iOldTeam[id] = iTeam
			cs_set_user_team(id, CS_TEAM_SPECTATOR)
			ColorChat(id, GREEN, "%s ^x01Przeniesiono do trybun.", spPrefix)

			if(is_user_alive(id))
				user_silentkill(id)
		}
	} else
		ColorChat(id, GREEN, "%s ^x01Musisz byc martwy, aby przejsc na spekta.", spPrefix)

	return PLUGIN_HANDLED
}

public GoBack(id)
{
		
	if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
		ColorChat(id, GREEN, "%s Nie jestes widzem. Aby przejsc na SPEC wpisz ^x03/spec", spPrefix)
	else
	{
		new iPlayers[32], iCT, iT
		get_players(iPlayers, iCT, "e", "CT")
		get_players(iPlayers, iT, "e", "TERRORIST")
		
		if(iCT == iT)
		{
			cs_set_user_team(id, g_iOldTeam[id])
			ColorChat(id, GREEN, "%s ^x01Przeniesiono z powrotem do gry.", spPrefix)
		}
		else
		{
			cs_set_user_team(id, iCT > iT ? CS_TEAM_T : CS_TEAM_CT)
			ColorChat(id, GREEN, "%s ^x01Przeniesiono z powrotem do gry.", spPrefix)
		}
		
		if(get_pcvar_num(g_eCvars[gospec_respawn]))
			ExecuteHamB(Ham_CS_RoundRespawn, id)
	}		
	
	return PLUGIN_HANDLED
}