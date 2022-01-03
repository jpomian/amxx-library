/* AMX Mod X
*   Nextmap Chooser Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve,
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#include <amxmodx>
#include <amxmisc>

#define VERSION "1.1"

#define SELECTMAPS  3

#define charsof(%1) (sizeof(%1)-1)

new Array:g_mapName;
new g_mapNums;

new g_nextName[SELECTMAPS]
new g_voteCount[SELECTMAPS + 2]
new g_mapVoteNum
new g_lastMap[32]


////

#define TASKID 614
#define all 0
#define MENU "Glosowanie na mala mape"

new pcvar_interval
new pcvar_checknum
new pcvar_maxplayers

new cvar_interval
new cvar_checknum
new cvar_maxplayers

new trueCount = 0
new counter


////




public plugin_init()
{
	register_plugin("Automatyczna mala mapa", VERSION, "Sn!ff3r & AMXX Dev Team")
	register_dictionary("mapchooser.txt")
	register_dictionary("common.txt")
	
	g_mapName=ArrayCreate(32);
	
	register_menucmd(register_menuid(MENU), (-1^(-1<<(SELECTMAPS+2))), "countVote")
	register_cvar("amx_extendmap_max", "90")
	register_cvar("amx_extendmap_step", "15")

	
	get_localinfo("lastSmallMap", g_lastMap, 31)
	set_localinfo("lastSmallMap", "")
	
	new maps_ini_file[64]
	get_configsdir(maps_ini_file, 63);
	format(maps_ini_file, 63, "%s/smallmaps.ini", maps_ini_file);
	
	if (!file_exists(maps_ini_file))
		set_fail_state("Brak pliku smallmaps.ini")
		
	if (loadSettings(maps_ini_file))
		set_task(10.0, "plugin_run")
		
	////	
	pcvar_interval = register_cvar("amx_malamapa_czas", "30")
	pcvar_checknum = register_cvar("amx_malamapa_sprawdzen", "8")
	pcvar_maxplayers = register_cvar("amx_malamapa_gracze", "10")
	////	
	
}


public plugin_run() {
	cvar_interval = get_pcvar_num(pcvar_interval)	
	cvar_checknum = get_pcvar_num(pcvar_checknum)	
	cvar_maxplayers = get_pcvar_num(pcvar_maxplayers)	
	
	set_task(float(cvar_interval), "players_count", TASKID, .flags="b")
}


public players_count()
{
	new currentPlayers = get_playersnum(1)
	if(currentPlayers <= cvar_maxplayers)
	{
		trueCount++	
	}
	else
	{
		trueCount = 0
	}
	
	if(trueCount > cvar_checknum)
	{
		counter = 11
		
		remove_task(TASKID)
		client_print(all, print_chat, "[!] Z powodu malej ilosci graczy na serwerze uruchamiamy glosowanie na mala mape")
		client_print(all, print_chat, "[!] Jezeli chcesz grac dalej obecna mape, wybierz w glosowaniu opcje rozszerzenia mapy")
		client_print(all, print_chat, "[!] Glosowanie rozpocznie sie za %d sekund...", counter - 1)
		
		set_task(1.0, "countdown", .flags="a", .repeat=counter-1)
		set_task(float(counter), "voteNextmap")
	}
}

public countdown()
{
	set_hudmessage(255, 255, 255, -1.0, 0.3, 0, 6.0, 1.0)
	show_hudmessage(0, "Za %d sekund odbedzie sie glosowanie na mapa mape^nZapraszamy do zaglosowania", --counter)
	
	new word[20]
	num_to_word(counter, word, 19)
	
	client_cmd(0, "spk vox/%s", word)	
}

public checkVotes()
{
	new b = 0
	
	for (new a = 0; a < g_mapVoteNum; ++a)
		if (g_voteCount[b] < g_voteCount[a])
		b = a
	
	
	if (g_voteCount[SELECTMAPS] > g_voteCount[b] && g_voteCount[SELECTMAPS] > g_voteCount[SELECTMAPS+1])
	{
		new mapname[32]
		
		get_mapname(mapname, 31)
		
		client_print(0, print_chat, "[!] Wynikiem glosowania gramy obecna mape dalej")
		log_amx("Vote: Voting for the smallmap finished with negative result")
		
		return
	}
	
	new smap[32]
	if (g_voteCount[b] && g_voteCount[SELECTMAPS + 1] <= g_voteCount[b])
	{
		ArrayGetString(g_mapName, g_nextName[b], smap, charsof(smap));
		set_cvar_string("amx_nextmap", smap);
	}
	
	
	get_cvar_string("amx_nextmap", smap, 31)
	client_print(0, print_chat, "[!] Wiekszosc graczy wyrazila chec zmiany mapy na mala")
	client_print(0, print_chat, "[!] Za chwile zagramy %s", smap)
	
	set_hudmessage(255, 255, 255, -1.0, 0.3, 0, 6.0, 10.0)
	show_hudmessage(0, "Glosowanie zakonczone!^nZa kilka sekund zmiana mapy na %s",  smap)
	
	log_amx("Vote: Voting for the smallmap finished. The nextmap will be %s", smap)
	
	set_task(5.0, "executeNextmap")
}

public executeNextmap()
{
	new smap[32]
	get_cvar_string("amx_nextmap", smap, 31)
	server_cmd("changelevel %s", smap)
}

public countVote(id, key)
{
	if (get_cvar_float("amx_vote_answers"))
	{
		new name[32]
		get_user_name(id, name, 31)
		
		if (key == SELECTMAPS)
			client_print(0, print_chat, "* %s nie chce zmiany na mala mape", name)
		else if (key < SELECTMAPS)
		{
			new map[32];
			ArrayGetString(g_mapName, g_nextName[key], map, charsof(map));
			client_print(0, print_chat, "* %s zaglosowal na %s", name, map);
		}
	}
	++g_voteCount[key]
	
	return PLUGIN_HANDLED
}

bool:isInMenu(id)
{
	for (new a = 0; a < g_mapVoteNum; ++a)
		if (id == g_nextName[a])
		return true
	return false
}

public voteNextmap()
{
	//g_selected = true
	
	new menu[512], a, mkeys = (1<<SELECTMAPS)
	
	new pos = format(menu, 511, "\y%s:\w^n^n", MENU)
	new dmax = (g_mapNums > SELECTMAPS) ? SELECTMAPS : g_mapNums
	
	for (g_mapVoteNum = 0; g_mapVoteNum < dmax; ++g_mapVoteNum)
	{
		a = random_num(0, g_mapNums - 1)
		
		while (isInMenu(a))
			if (++a >= g_mapNums) a = 0
		
		g_nextName[g_mapVoteNum] = a
		pos += format(menu[pos], 511, "\r%d. \w%a^n", g_mapVoteNum + 1, ArrayGetStringHandle(g_mapName, a));
		mkeys |= (1<<g_mapVoteNum)
		g_voteCount[g_mapVoteNum] = 0
	}
	
	menu[pos++] = '^n'
	g_voteCount[SELECTMAPS] = 0
	g_voteCount[SELECTMAPS + 1] = 0
	
	new mapname[32]
	get_mapname(mapname, 31)
	
	if (get_cvar_float("mp_timelimit") < get_cvar_float("amx_extendmap_max"))
	{
		pos += format(menu[pos], 511, "\r%d. \wGramy dalej \y%s^n", SELECTMAPS + 1, mapname)
		mkeys |= (1<<SELECTMAPS)
	}
	
	show_menu(0, mkeys, menu, 15, MENU)
	set_task(15.0, "checkVotes")
	client_cmd(0, "spk Gman/Gman_Choose2")
	log_amx("Vote: Voting for the smallmap started")
}
stock bool:ValidMap(mapname[])
{
	if ( is_map_valid(mapname) )
	{
		return true;
	}
	// If the is_map_valid check failed, check the end of the string
	new len = strlen(mapname) - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if (len < 0)
	{
		return false;
	}
	if ( equali(mapname[len], ".bsp") )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname[len] = '^0';
		
		// recheck
		if ( is_map_valid(mapname) )
		{
			return true;
		}
	}
	
	return false;
}

loadSettings(filename[])
{
	if (!file_exists(filename))
		return 0
	
	new szText[32]
	new currentMap[32]
	
	new buff[256];
	
	get_mapname(currentMap, 31)
	
	new fp=fopen(filename,"r");
	
	while (!feof(fp))
	{
		buff[0]='^0';
		szText[0]='^0';
		
		fgets(fp, buff, charsof(buff));
		
		parse(buff, szText, charsof(szText));
		
		if(equali(szText, currentMap))
		{
			set_fail_state("Grana mala mapa")
			break;
		}
		
		if(szText[0] != ';' && ValidMap(szText) && !equali(szText, g_lastMap) && !equali(szText, currentMap))
		{
			ArrayPushString(g_mapName, szText);
			++g_mapNums;
		}	
	}

	fclose(fp);

	log_amx("Vote: zaladowano liste %d malych map", g_mapNums)
	
	return g_mapNums
}


public plugin_end()
{
	new current_map[32]
	
	get_mapname(current_map, 31)
	set_localinfo("lastSmallMap", current_map)
}
