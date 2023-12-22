#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <prezenty>

#define KeysPrezenty (1<<0)|(1<<1)|(1<<8)|(1<<9) // Keys: 1290


#define PLUGIN "Prezenty"
#define VERSION "1.1"
#define AUTHOR "R3X"

#define MAX_GIFTS_NAMELEN 32

#define MAX_SPOTS 128 

new bool:gbEdytor = false;
new bool:gbCustomLocations = false;
new Float:gfImportantSpots[MAX_SPOTS][3];
new giImportantSpots = 0;



new giLastGift = 0;

new gszGiftContent[MAX_GIFTS][MAX_GIFTS_NAMELEN];
new giGiftCallbacks[MAX_GIFTS];
new giChance[MAX_GIFTS];
new giSummary = 0;

bool:isValidGift(Gift:award)
{
	return (_:award >= 0 && _:award <= giLastGift)
}


executeGift(id, Gift:award)
{	
	new iRet = 0;
	
	if(isValidGift(Gift:award) && award != GIFT_RANDOM)
	{
		ExecuteForward(giGiftCallbacks[_:award], iRet, id);
	}
	return iRet;
}


new const gszModels[][32] = 
{
	"models/bio_prezent.mdl",
	"models/bio_prezent2.mdl"
};

new const gszPointerModel[] = "models/can.mdl";
new const gszPackageTrail[] = "sprites/ballsmoke.spr";

new gPackTrailSprite;

new Float:gfShouldUse[33][2];
new giTryToTake[33];

new gcvarTakingTime;

static szFile[256];
static szTemp[256];



public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_menucmd(register_menuid("Prezenty"), KeysPrezenty, "PressedPrezenty");
	
	register_forward(FM_PlayerPreThink, "fwPlayerPreThink", 1);
	register_forward(FM_TraceLine, "fwTraceLine", 1);
	register_think("gift_pointer", "thinkCPPOinter");
	
	RegisterHam(Ham_Use, "func_button", "fwButtonUse");
	
	
	gcvarTakingTime = register_cvar("amx_taking_time", "1.0");
	
	
	//Build config patch
	static szMap[32];
	get_mapname(szMap, 31);
	
	get_configsdir(szFile, charsmax(szFile));
	add(szFile, charsmax(szFile), "/prezenty/");
	
	add(szFile, charsmax(szFile), szMap);
	add(szFile, charsmax(szFile), ".ini");
	
	makeImportantSpotList();
	
	register_clcmd("prezenty", "cmdPrezenty", ADMIN_CFG);
}
public plugin_end()
{
	saveImportantSpotList();
}

public plugin_natives()
{
	register_native("register_gift", "_register_gift");
	register_native("gift_spawn", "_gift_spawn");
	register_native("gifts_clear_map", "_gifts_clear_map");
}


public Gift:_register_gift(plugin, params)
{
	if(params < 3)
		return Gift:-1;
	
	if(giLastGift >= MAX_GIFTS)
	{
		log_amx("Wiecej sie nie da, limit %d", MAX_GIFTS);
		return Gift:-1;
	}
	
	//Next pointer
	giLastGift++;
	
	//Read name
	get_string(1, gszGiftContent[giLastGift], MAX_GIFTS_NAMELEN-1);
	
	//Make callback
	new szFunction[64]
	get_string(2, szFunction, 63);
	
	giGiftCallbacks[giLastGift] = CreateOneForward(plugin, szFunction, FP_CELL);
	
	//Save chance to get
	giChance[giLastGift] = get_param(3);
	giSummary += giChance[giLastGift];
	
	
	
	return Gift:giLastGift;
}

public _gift_spawn(plugin, params)
{
	if(params < 1)
		return 0;
		
	new Gift:gift = Gift:get_param(1);
	if(!isValidGift(gift))
		return 0;
	
	if(params >= 2)
	{
		new Float:fOrigin[3];
		get_array_f(2, fOrigin, 3);
		
		return createPointer( gift, fOrigin );
	}
	
	return randomSpawnGift(gift);
}

public _gifts_clear_map(plugin, params)
{
	remove_entity_name("gift_package");
	remove_entity_name("gift_pointer");
	return 1;
}

stock bool:is_hull_vacant(const Float:origin[3], hull, id = 0) {
        static tr
        engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
        if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
                return true
        
        return false
}


randomSpawnGift(Gift:gift)
{	
	new Float:fOrigin[3];
	new try = 256;
	
	new index;
	
	do
	{
		try--;
		
		index = random(giImportantSpots);
		
		
		fOrigin[0] = gfImportantSpots[index][0];
		fOrigin[1] = gfImportantSpots[index][1];
		fOrigin[2] = gfImportantSpots[index][2]; 
		
		if(!gbCustomLocations)
		{
			fOrigin[0] += random_float(-489.0, 489.0);
			fOrigin[1] += random_float(-489.0, 489.0);
			fOrigin[2] += random_float(-289.0, 289.0);
		}
		
		
		if(is_hull_vacant(fOrigin, HULL_HUMAN))
		{							
			createPointer(gift, fOrigin);
			break;
		}
		
	}
	while(try > 0);
	
	return 1;
}

public plugin_precache()
{
	for(new i=0;i<sizeof(gszModels); i++)
	{
		precache_model(gszModels[i])
	}
	
	precache_model(gszPointerModel);
	
	gPackTrailSprite = precache_model(gszPackageTrail);
}


Gift:getRandomGift()
{
	new iRand = random(giSummary);
	
	for(new i=1;i<=giLastGift; i++)
	{
		iRand -= giChance[i];
		if(iRand <= 0)
		{
			return Gift:i;
		}
	}
	return Gift:giLastGift;
}

createPointer( Gift:gift, const Float:fOrigin[3] )
{
	if(!isValidGift(gift))
		return 0;
		
	if(giLastGift == 0)
		return 0;
		
	if(gift == GIFT_RANDOM)
		gift = getRandomGift();
		
	static const Float:DELAY = 3.0;
	
	new ent = create_entity("info_target");
		
	set_pev(ent, pev_classname, "gift_pointer");
	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
		
	engfunc(EngFunc_SetModel, ent, gszPointerModel);
		
	engfunc(EngFunc_SetOrigin,ent, fOrigin);
		
	engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	
	//Zawartosc paczki
	set_pev(ent, pev_iuser2, gift);
	
	//Czy juz zrzucono? 
	set_pev(ent, pev_iuser4, 0);
	//Czas dymienia
	set_pev(ent, pev_fuser4, 0.0)
		
	set_pev(ent, pev_ltime,  get_gametime()+DELAY);
	set_pev(ent, pev_nextthink, get_gametime()+0.3);
	
		
	set_rendering(ent, kRenderFxGlowShell, 50, 50, 50,kRenderNormal, 16);
	return 1;
}

stock Create_TE_EXPLOSION(const Float:fOrigin[3], sprite, scale, framerate, flags){
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_EXPLOSION);
	write_coord(floatround(fOrigin[0]));
	write_coord(floatround(fOrigin[1]));
	write_coord(floatround(fOrigin[2]));
	write_short(sprite);
	write_byte(scale);
	write_byte(framerate);
	write_byte(flags);
	message_end();
}

public thinkCPPOinter(ent){
	new Float:fLTime;
	pev(ent, pev_ltime, fLTime);
	
	new Float:fNow = get_gametime();
	
	if(fNow > Float:fLTime){
		if(pev(ent, pev_flags)&FL_ONGROUND == 0)
			return;
		
		remove_entity(ent);
		return;
	}else{
		if(pev(ent, pev_iuser4) == 0 && (fLTime-fNow) < 0.5){
			set_pev(ent, pev_iuser4, 1);
			dropBox(ent);
		}
		
		new Float:fSmoking;
		pev(ent, pev_fuser4, fSmoking);
		
		new Float:fOrigin[3];
		pev(ent, pev_origin, fOrigin);
		
		Create_TE_EXPLOSION(fOrigin, gPackTrailSprite, 3+random(3), 5, TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS);
		if(pev(ent, pev_flags)&FL_ONGROUND){
			set_pev(ent, pev_fuser4, fSmoking+0.3);
			
			if(fSmoking > 0.3){
				fOrigin[2] += 25.0;
				Create_TE_EXPLOSION(fOrigin, gPackTrailSprite, 4+random(3),5, TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS);
			}
			if(fSmoking > 0.9){
				fOrigin[2] += 25.0;
				Create_TE_EXPLOSION(fOrigin, gPackTrailSprite, 5+random(3), 5, TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS);
			}
		}
	}
	set_pev(ent, pev_nextthink, get_gametime()+0.3);
}

dropBox(ent){	
	new id = pev(ent, pev_owner);
	
	new Float:fStart[3], Float:fStop[3];
	pev(ent, pev_origin, fStart);
	
	xs_vec_copy(fStart, fStop);
	fStop[2] += 2000.0;
	
	engfunc(EngFunc_TraceLine, fStart, fStop, IGNORE_MONSTERS|IGNORE_GLASS, ent, 0);
	get_tr2(0, TR_vecEndPos, fStop);
		
	
	new ent2 = create_entity("func_button");
	set_pev(ent2, pev_spawnflags, SF_BUTTON_DONTMOVE);
	set_pev(ent2, pev_classname, "gift_package");
	
	set_pev(ent2 , pev_euser4, id);
	set_pev(ent2, pev_iuser2, pev(ent, pev_iuser2));
		
	fStop[2] -= 100.0;
	engfunc(EngFunc_SetOrigin, ent2, fStop);
	
	engfunc(EngFunc_SetModel, ent2, gszModels[ random(sizeof gszModels) ]);
	
	set_pev(ent2, pev_gravity, 1.0);
	dllfunc(DLLFunc_Spawn, ent2);
	
	set_pev(ent2, pev_solid, SOLID_SLIDEBOX);
	set_pev(ent2, pev_movetype, MOVETYPE_TOSS);
	
	engfunc(EngFunc_SetSize, ent2, Float:{-4.0, -4.0, 0.0}, Float:{4.0, 4.0, 30.0});
	
	
	set_rendering(ent2, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 255);
}

Gift:getCPContent(ent)
{
	return Gift:pev(ent, pev_iuser2);
}

stock Create_BarTime(id, duration){
	new msgid = 0;
	if(!msgid)
		msgid = get_user_msgid("BarTime");
	
	message_begin(MSG_ONE_UNRELIABLE, msgid, _, id);
	write_short(duration);
	message_end();
}

startTaking(id, ent)
{			
	new Float:fTime = get_pcvar_float(gcvarTakingTime);
		
	Create_BarTime(id, floatround(fTime));
	giTryToTake[id] = ent;
		
	gfShouldUse[id][0] = get_gametime();
	gfShouldUse[id][1] = gfShouldUse[id][0] + fTime;
}

stopTaking(id)
{
	executeGift(id, getCPContent(giTryToTake[id]));
	
	set_pev(giTryToTake[id], pev_flags, FL_KILLME);
	gfShouldUse[id][0] = gfShouldUse[id][1] = 0.0;
	giTryToTake[id] = 0;
}

cancelTaking(id)
{
	Create_BarTime(id, 0);
	gfShouldUse[id][0] = gfShouldUse[id][1] = 0.0;
	giTryToTake[id] = 0;
}

public fwButtonUse(this, idcaller, idactivator, use_type, Float:value){
	static szClass[32];
	pev(this, pev_classname, szClass, 31);
	
	if(equal(szClass, "gift_package") == 0)
		return HAM_IGNORED;
	
	if(use_type != 2 && value != 1.0 && idcaller != idactivator)
		return HAM_IGNORED;
	
	startTaking(idactivator, this);
	return HAM_SUPERCEDE;
}

public fwPlayerPreThink(id){
	new Float:fNow = get_gametime();
	
	if(gbEdytor)
	{
		static Float:fLast = 0.0;
		if(fNow - fLast >= 0.5)
		{
			fLast = fNow;
			for(new i=0; i<giImportantSpots; i++)
				Create_TE_EXPLOSION(gfImportantSpots[i], gPackTrailSprite, 3, 5, TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS);
		}
	}
	
	
	if(!is_user_alive(id) ){
		
		if(gfShouldUse[id][0] && fNow > gfShouldUse[id][0])
			cancelTaking(id);
		return FMRES_IGNORED;
	}
	
	new button = pev(id, pev_button);
		
	
	//Usage of care package
	if(gfShouldUse[id][0]){
		if(fNow > gfShouldUse[id][0]){
			if(pev_valid(giTryToTake[id])){
				if(fNow > gfShouldUse[id][1])
					stopTaking(id);
				else 
				if( 
					button&IN_USE == 0 || 
					(!pev_valid(giTryToTake[id])) || 
					get_entity_distance(id, giTryToTake[id]) > 100.0
				   )
					cancelTaking(id);
			}else
				cancelTaking(id);
		}
	}

	return FMRES_IGNORED;
}


public fwTraceLine(const Float:V1[3], const Float:V2[3], fNoMonsters, const id, tr_handle){
	static fLastEnt[33];
	static Float:fLastInfo[33];
	
	if(is_user_connected(id)){
		new ent = get_tr2(tr_handle, TR_pHit);
		if(!pev_valid(ent))
			return FMRES_IGNORED;
		
		static szClass[32];
		pev(ent, pev_classname, szClass, 31);
	
		if(equal(szClass, "gift_package") == 0)
			return HAM_IGNORED;
			
		if(entity_range(id, ent) >= 100.0)
			return HAM_IGNORED;
		
		
		new Float:fNow = get_gametime();
		
		new Float:fInterval;
		if(fLastEnt[id] == ent)
			fInterval == 0.5;
		else{
			fInterval == 0.1;
		}
		
		if(fNow > (fLastInfo[id]+fInterval)){
			client_print(id, print_center, "[E] Prezent");
			fLastInfo[id] = fNow;
			fLastEnt[id] = ent;
		}
	}
		
	return FMRES_IGNORED;
}

saveImportantSpotList()
{
	if(!gbCustomLocations) return;
	
	new fp = fopen(szFile, "wt");
	
	for(new i=0;i<giImportantSpots;i++)
	{
		fprintf(fp, "%f %f %f^n", gfImportantSpots[i][0], gfImportantSpots[i][1], gfImportantSpots[i][2]);
	}
	fclose(fp);
	
}
makeImportantSpotList()
{
	new fp = fopen(szFile, "rt");
	
	if(fp)
	{
		new X[11];
		new Y[11];
		new Z[11];
		
		while(!feof(fp))
		{
			if(giImportantSpots >= MAX_SPOTS)
				break;
				
			fgets(fp, szTemp, charsmax(szTemp));
			trim(szTemp);
			
			if(szTemp[0] == ';') continue;
			
			if(3 == parse(szTemp, X, 10, Y, 10, Z, 10))
			{
				gfImportantSpots[giImportantSpots][0] = str_to_float(X);
				gfImportantSpots[giImportantSpots][1] = str_to_float(Y);
				gfImportantSpots[giImportantSpots][2] = str_to_float(Z);
				
				giImportantSpots++;
			}
			
		}
		fclose(fp);
		
		gbCustomLocations = true;
	}
	else
	{
		for(new ent=1; ent<=512; ent++)
		{
			if(giImportantSpots >= MAX_SPOTS)
				break;
				
			if(pev_valid(ent))
			{	
				get_brush_entity_origin(ent, gfImportantSpots[giImportantSpots]);
				giImportantSpots++;
			}
		}
	}
}

public cmdPrezenty(id, level, cid) 
{
	if(cmd_access(id, level, cid, 1))
	{
		gbEdytor = true;
		showMenuPrezenty(id);
	}
}

showMenuPrezenty(id)
{
	show_menu
		(
			id,
			KeysPrezenty, 
				"\yMiejsca na prezenty^n^n \
				\w1. Dodaj obecne^n \
				2. Usun najblizsze^n^n \
				9. Wyczysc^n \
				0. Wyjdz^n",
			-1, 
			"Prezenty"
		);
}

public PressedPrezenty(id, key) {
	switch (key) {
		case 0: 
		{ 
			if(!gbEdytor)
				giImportantSpots = 0;
				
			if(giImportantSpots < MAX_SPOTS)
			{
				gbCustomLocations = true;
				gbEdytor = true;
				
				pev(id, pev_origin, gfImportantSpots[giImportantSpots]);
				giImportantSpots++;
			}
			
			showMenuPrezenty(id);
		}
		case 1: 
		{ 
			new Float:fOrigin[3];
			pev(id, pev_origin, fOrigin);
			
			new iNearest = -1;
			new Float:fDistance = 99999999.0;
			new Float:fDistance2;
			for(new i=0;i<giImportantSpots;i++)
			{
				fDistance2 = vector_distance(fOrigin, gfImportantSpots[i]);
				if( fDistance2 < fDistance)
				{
					fDistance = fDistance2;
					iNearest = i;
				}
			}
			
			if(iNearest >= 0)
			{
				gfImportantSpots[iNearest][0] = gfImportantSpots[giImportantSpots-1][0];
				gfImportantSpots[iNearest][1] = gfImportantSpots[giImportantSpots-1][1];
				gfImportantSpots[iNearest][2] = gfImportantSpots[giImportantSpots-1][2];
				giImportantSpots--;
			}
			
			showMenuPrezenty(id);
		}
		case 8: 
		{
			giImportantSpots = 0;
			gbCustomLocations = false;
			gbEdytor = false;
			
			showMenuPrezenty(id);
		}
		case 9: 
		{
			gbEdytor = false;
		}
	}
}

