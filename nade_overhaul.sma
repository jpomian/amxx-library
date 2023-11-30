#include <amxmodx> 
#include <engine> 
#include <fakemeta> 

new VIEW_MODELS[][] =
{
    "models/biohazard/v_zamrazacz.mdl",
    "models/biohazard/v_heZM.mdl",
    "models/biohazard/v_heDM.mdl"
}
new PLAYER_MODELS[][] =
{
    "models/biohazard/p_zamrazacz.mdl",
    "models/p_hegrenade.mdl",
    "models/biohazard/p_heDM.mdl"
}  
new WORLD_MODELS[][] =
{
    "models/biohazard/w_heZM.mdl",
    "models/biohazard/w_heDM.mdl"
}

new OLDWORLD_MODELS[][] =
{
    "models/w_hegrenade.mdl",
    "models/w_flashbang.mdl"
} 


new PLUGIN_NAME[]        = "Custom Grenade Models" 
new PLUGIN_AUTHOR[]    = "Cheap_Suit ft. Mix" 
new PLUGIN_VERSION[]     = "1.0" 

new g_map[4], bool:g_bZmMode;

public plugin_init() 
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)     
    register_event("CurWeapon", "Event_CurWeapon", "be","1=1")

    register_forward(FM_SetModel, "fw_SetModel")
    register_touch("*", "grenade", "fwTouchGrenade2");
    register_touch("grenade", "*", "fwTouchGrenade");

    get_mapname(g_map, charsmax(g_map))
    g_bZmMode = equali(g_map, "zm", 2) ? true : false;
} 

public plugin_precache() 
{
    for(new i=0; i< sizeof VIEW_MODELS; i++)
    {
        precache_model(VIEW_MODELS[i])     
        precache_model(PLAYER_MODELS[i]) 
    }

    for(new i=0; i< sizeof WORLD_MODELS; i++) 
        precache_model(WORLD_MODELS[i])
} 

public Event_CurWeapon(id) 
{     
    new weaponID = read_data(2) 

    if(weaponID == CSW_SMOKEGRENADE)
    {
        set_pev(id, pev_viewmodel2, VIEW_MODELS[0])
        set_pev(id, pev_weaponmodel2, PLAYER_MODELS[0])
    }

    if(weaponID == CSW_HEGRENADE)
    {
        if(g_bZmMode)
        {
            set_pev(id, pev_viewmodel2, VIEW_MODELS[1])
            set_pev(id, pev_weaponmodel2, PLAYER_MODELS[1])
        } else
        {
            set_pev(id, pev_viewmodel2, VIEW_MODELS[2])
            set_pev(id, pev_weaponmodel2, PLAYER_MODELS[2])
        }
    }
    
    return PLUGIN_CONTINUE 
}

public fw_SetModel(entity, model[])
{
    if(!is_valid_ent(entity)) 
        return FMRES_IGNORED

    if(!equali(model, OLDWORLD_MODELS[0])) 
        return FMRES_IGNORED

    new className[33]
    entity_get_string(entity, EV_SZ_classname, className, 32)
    
    if(equal(className, "weaponbox") || equal(className, "armoury_entity") || equal(className, "grenade"))
    {
        g_bZmMode ? engfunc( EngFunc_SetModel, entity, WORLD_MODELS[0] ) : engfunc( EngFunc_SetModel, entity, WORLD_MODELS[1] )
        return FMRES_SUPERCEDE
    }

    return FMRES_IGNORED

}

public fwTouchGrenade2(ent, nade) {
	fwTouchGrenade(nade, ent);
}

public fwTouchGrenade(nade, ent) {

	if(pev_valid(ent) && pev(ent, pev_solid) == SOLID_TRIGGER) return;
	
	static szModel[64];
	pev(nade, pev_model, szModel, charsmax(szModel)); // error
	
	if(equali(szModel, "models/w_flashbang.mdl") || equali(szModel, "models/biohazard/w_heDM.mdl")) {
		set_pev(nade, pev_dmgtime, get_gametime());
		dllfunc(DLLFunc_Think, nade);
    }

}