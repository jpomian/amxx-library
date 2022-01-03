#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>

#define PLUGIN	"Dynamic sky"
#define VERSION	"1.0"
#define AUTHOR	"Sneaky.amxx | GlobalModders.net"

new const g_szSky[] = "models/sky2.mdl";
new g_iSkyEnt;
new g_fwCheckVisibility, g_fwAddToFullPack;

//new map_light;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	//fix 1
	set_cvar_num("sv_zmax", 50000)
	//fix 2
	Set_lights();
	
	g_fwCheckVisibility = register_forward(FM_CheckVisibility, "fw_CheckVisibility");
	g_fwAddToFullPack = register_forward(FM_AddToFullPack, "fw_addToFullPackPost", 1);
	
	if (!unloadlist())
		g_iSkyEnt = CreateSky();
	else
	{
		unregister_forward(FM_CheckVisibility, g_fwCheckVisibility);
		unregister_forward(FM_AddToFullPack, g_fwAddToFullPack);
		g_fwCheckVisibility = -1;
		g_fwAddToFullPack = -1;
		g_iSkyEnt = 0;
	}
}
//fix 2
public Set_lights()
{
	new light[2];
	set_lights("d")
}

public unloadlist()
{
	new bool: ismap;
	new customdir[64], mapfile[128], mapname[32]

	get_customdir(customdir, charsmax(customdir));
	format(mapfile, charsmax(mapfile), "%s/unloadmaps.ini", customdir);

	get_mapname(mapname, charsmax(mapname));
	strtolower(mapname);
	
	ismap = false;

	if (file_exists(mapfile))
	{
		new File = fopen(mapfile, "r")
		new text[256]
		new tempMap[32]

		while(File && !feof(File))
		{
			fgets(File, text, charsmax(text))

			if (text[0] == ';')
				continue

			if (parse(text, tempMap, charsmax(tempMap)) < 1)
				continue

			if(!is_map_valid(tempMap))
				continue

			trim(tempMap)
			
			strtolower(tempMap);
			
			if (equal(mapname, tempMap))
			{
				ismap = true;
				break;
			}
		}

		if (File)
			fclose(File)
	}
	else
	{
		write_file(mapfile, "; 需要关闭动态天空的地图列表", -1);
		write_file(mapfile, "; 格式：一行一个地图名", -1);
		write_file(mapfile, "; 例子：de_dust2", -1);
	}
	
	return ismap;
}

public fw_CheckVisibility(iEnt, pset)
{
	if (g_iSkyEnt)
	{
		if (iEnt == g_iSkyEnt)
		{
			forward_return(FMV_CELL, 1);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public fw_addToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{
	if (g_iSkyEnt)
	{
		if (ent == g_iSkyEnt)
		{
			new Float: fOrigin[3];
			pev(host, pev_origin, fOrigin);
			fOrigin[2] -= 1000.0;
			set_es(es, ES_Origin, fOrigin);
		}
	}
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, g_szSky);
}

public CreateSky()
{
	set_cvar_num("sv_skycolor_r", 0);
	set_cvar_num("sv_skycolor_g", 0);
	set_cvar_num("sv_skycolor_b", 0);
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	set_pev(iEnt, pev_classname, "dynamic_sky");
	set_pev(iEnt, pev_solid, SOLID_NOT);
	set_pev(iEnt, pev_sequence, 0);
	set_pev(iEnt, pev_framerate, 0.5);
	set_pev(iEnt, pev_effects, EF_BRIGHTLIGHT | EF_DIMLIGHT);
	set_pev(iEnt, pev_light_level, 10.0);
	set_pev(iEnt, pev_flags, FL_PARTIALGROUND);
	engfunc(EngFunc_SetModel, iEnt, g_szSky);
	engfunc(EngFunc_SetOrigin, iEnt, Float:{0.0, 0.0, 0.0});
	return iEnt;
}