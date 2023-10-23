#include <amxmodx>
#include <engine>
#include <fakemeta_util>

#define PLUGIN			"LANDSCAPE + RAINBOW"
#define VERSION			"1.5"
#define AUTHOR			"MayroN | Flymic24"

/*-----------------НАСТРОЙКИ КАРТ ДЛЯ ЛАНДШАФТА------------------*/

/*-----------------Летний вариант гор---------------------------------*/
new const SUMMER_MOUNTAINS_MAP_LIST[][] = { "zm_inferno" };

/*-----------------Зимний вариант гор--------------------------------*/
new const SNOW_MOUNTAINS_MAP_LIST[][] = { "zm_winter_big", "zm_snow_nv" };

/*-----------------Песчаные дюны-----------------------------------*/
new const DUNES_MAP_LIST[][] = { "zm_deko2" };

/*---------------------Город----------------------------------------*/
new const CITY_MAP_LIST[][] = { "zm_ziger_new"};

/*------------------------------------------------------------------*/

/*-----------------НАСТРОЙКА АНИМАЦИИ ПАДЕНИЯ КАМНЕЙ----------*/

#define RockFallTime				60.0		// Падение снежных камней с гор ( рандом в сек. )
#define DownTime        			8.0        	// (Frame / FPS = 201 / 24 = 8.375)    Время падения снежных камней с гор
/*------------------------------------------------------------------*/

/*-----------------ЗВУК ПАДЕНИЯ КАМНЕЙ---------------------------*/

#define SOUND_ROCK_FALL			"landscape/sound_rock_fall.wav"

/*------------------------------------------------------------------*/

/*-----------------НАСТРОЙКА РАДУГИ---------------------------*/

#define CREATE_REINBOW					// Закомментируйте,если не желаете видеть модель Радуги
/*------------------------------------------------------------------*/

#define LANDSCAPE				"models/landscape/landscape.mdl"

#if defined CREATE_REINBOW
#define RAINBOW				"models/landscape/rainbow.mdl"
#endif

#define CLASSNAME_LANDSCAPE		"landscape"

#if defined CREATE_REINBOW
#define CLASSNAME_RAINBOW		"rainbow"
#endif
enum _:eMapsType
{
    SUMMER = 0, SNOW, DUNES, CITY
};

new Trie:g_MapsType, iType = FM_NULLENT;
new ForwardType, ForwardResult

public plugin_init()
{
    	register_plugin(PLUGIN, VERSION, AUTHOR);

    	register_think(CLASSNAME_LANDSCAPE, "Think_Scape");

    	set_cvar_num("sv_zmax", 50000);
    	set_cvar_num("sv_skycolor_r", 0);
    	set_cvar_num("sv_skycolor_g", 0);
    	set_cvar_num("sv_skycolor_b", 0);
}

public plugin_precache()
{
    	precache_model(LANDSCAPE);

#if defined CREATE_REINBOW
    	precache_model(RAINBOW);
#endif
	precache_sound(SOUND_ROCK_FALL);

    	new a;
    	for(a = 1; a <= 3; a++)    precache_sky(fmt("snow_sky%i_", a));
    	for(a = 1; a <= 4; a++)    precache_sky(fmt("blue_sky%i_", a));

    	g_MapsType = TrieCreate();
    	ForwardType = CreateMultiForward("ws_map_type", ET_CONTINUE, FP_CELL);

    	for(a = 0; a < sizeof(SUMMER_MOUNTAINS_MAP_LIST); a++)
        	TrieSetCell(g_MapsType, SUMMER_MOUNTAINS_MAP_LIST[a], SUMMER);

    	for(a = 0; a < sizeof(SNOW_MOUNTAINS_MAP_LIST); a++)
        	TrieSetCell(g_MapsType, SNOW_MOUNTAINS_MAP_LIST[a], SNOW);

    	for(a = 0; a < sizeof(DUNES_MAP_LIST); a++)
        	TrieSetCell(g_MapsType, DUNES_MAP_LIST[a], DUNES);

    	for(a = 0; a < sizeof(CITY_MAP_LIST); a++)
        	TrieSetCell(g_MapsType, CITY_MAP_LIST[a], CITY);

    	SetMapsParam();
}

SetMapsParam()
{
    	new szMapName[32];    get_mapname(szMapName, charsmax(szMapName));
	TrieGetCell(g_MapsType, szMapName, iType);

    	new skyName = get_cvar_pointer("sv_skyname");

    	switch(iType)
	{
        	case SNOW:
		{
            		set_pcvar_string(skyName, fmt("snow_sky%i_", random_num(1, 3)));
        	}

        	case SUMMER, DUNES, CITY:
		{
            		set_pcvar_string(skyName, fmt("blue_sky%i_", random_num(1, 4)));
        	}
    	}

    	new g_entity_fog = create_entity("env_fog");

    	if(g_entity_fog)
	{
        	fm_set_kvd(g_entity_fog, "density", "0.0000", "env_fog");
    	}
}

public Think_Scape(const iEnt)
{
    	if(!pev_valid(iEnt))
        	return;

    	new Float:fGameTime = get_gametime();

    	if(iType != SNOW)
    	{
        	set_pev(iEnt, pev_nextthink, fGameTime + 99999.9);
        	return;
    	}

    	switch(pev(iEnt, pev_impulse))
	{
        	case 0:
		{
            		set_pev(iEnt, pev_sequence, 2);
            		set_pev(iEnt, pev_impulse, 1);
            		set_pev(iEnt, pev_framerate, 1.0);
			set_pev(iEnt, pev_animtime, fGameTime);

			emit_sound(0, CHAN_STATIC, SOUND_ROCK_FALL, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_pev(iEnt, pev_nextthink, fGameTime + DownTime);
        	}
        	case 1:
		{
            		set_pev(iEnt, pev_sequence, 0);
            		set_pev(iEnt, pev_impulse, 0);
            		set_pev(iEnt, pev_framerate, 0.0);
            		set_pev(iEnt, pev_animtime, 0.0);

			emit_sound(0, CHAN_STATIC, SOUND_ROCK_FALL, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);
    			set_pev(iEnt, pev_nextthink, fGameTime + RockFallTime);
        	}
    	}
}

public plugin_cfg()
{
	ExecuteForward(ForwardType, ForwardResult, iType);

	switch(iType)
	{
		case CITY:
		{
			Create_Landscape(0, 1, 1);
		}
		case SUMMER:
		{
			Create_Landscape(iType, 0, 0);

			#if defined CREATE_REINBOW
			Create_Rainbow();
			#endif
		}
		case SNOW, DUNES:
		{
			Create_Landscape(iType, 0, 0);
		}
	}
}

Create_Landscape(skin = 0, body = 0, sequence = 0)
{
    	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

    	if(!pev_valid(iEntity))
        	return;

    	set_pev(iEntity, pev_classname, CLASSNAME_LANDSCAPE);
    	set_pev(iEntity, pev_solid, SOLID_NOT);

    	set_pev(iEntity, pev_skin, skin);
    	set_pev(iEntity, pev_body, body);
    	set_pev(iEntity, pev_sequence, sequence);

    	set_pev(iEntity, pev_effects, EF_DIMLIGHT);

    	set_pev(iEntity, pev_impulse, 0);
    	set_pev(iEntity, pev_nextthink, get_gametime() + RockFallTime);

    	engfunc(EngFunc_SetModel, iEntity, LANDSCAPE);
    	engfunc(EngFunc_SetSize, iEntity, Float:{-50000.0, -50000.0, -50000.0}, Float:{50000.0, 50000.0, 50000.0});
}

#if defined CREATE_REINBOW
Create_Rainbow()
{
    	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

    	if(!pev_valid(iEntity))
        	return;

    	set_pev(iEntity, pev_classname, CLASSNAME_RAINBOW);
    	set_pev(iEntity, pev_solid, SOLID_NOT);

    	set_pev(iEntity, pev_skin, random_num(0, 1));

    	set_pev(iEntity, pev_effects, EF_DIMLIGHT);

    	engfunc(EngFunc_SetModel, iEntity, RAINBOW);
    	engfunc(EngFunc_SetSize, iEntity, Float:{-50000.0, -50000.0, -50000.0}, Float:{50000.0, 50000.0, 50000.0});
}
#endif

public precache_sky(const szSkyName[])
{
    	new g_Prefix[ ][ ] =    {    "up", "dn", "ft", "bk", "lf", "rt"    };

    	for( new i = 0, szBuffer[64]; i < sizeof g_Prefix; ++i )
	{
        	formatex(szBuffer, charsmax(szBuffer), "gfx/env/%s%s.tga", szSkyName, g_Prefix[i]);

        	if(!file_exists(szBuffer))
		{
            		set_fail_state(fmt("File ^"%s^" not found", szBuffer));
        	}

        	precache_generic(szBuffer);
    	}
}