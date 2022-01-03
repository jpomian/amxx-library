#include <amxmodx> 
#include <engine> 
#include <fakemeta> 

new VIEW_MODEL[]    = "models/v_zamrazacz.mdl" 
new PLAYER_MODEL[]    = "models/p_zamrazacz.mdl" 
new WORLD_MODEL[]    = "models/w_smokegrenade.mdl"

new OLDWORLD_MODEL[]    = "models/w_smokegrenade.mdl"

new PLUGIN_NAME[]        = "Custom SG Model" 
new PLUGIN_AUTHOR[]    = "Cheap_Suit" 
new PLUGIN_VERSION[]     = "1.0" 

public plugin_init() 
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)     
    register_event("CurWeapon", "Event_CurWeapon", "be","1=1")
    register_forward(FM_SetModel, "fw_SetModel")
} 

public plugin_precache() 
{    
    precache_model(VIEW_MODEL)     
    precache_model(PLAYER_MODEL) 
    precache_model(WORLD_MODEL)
} 

public Event_CurWeapon(id) 
{     
    new weaponID = read_data(2) 

    if(weaponID != CSW_SMOKEGRENADE)
        return PLUGIN_CONTINUE

    set_pev(id, pev_viewmodel2, VIEW_MODEL)
    set_pev(id, pev_weaponmodel2, PLAYER_MODEL)
    
    return PLUGIN_CONTINUE 
}

public fw_SetModel(entity, model[])
{
    if(!is_valid_ent(entity)) 
        return FMRES_IGNORED

    if(!equali(model, OLDWORLD_MODEL)) 
        return FMRES_IGNORED

    new className[33]
    entity_get_string(entity, EV_SZ_classname, className, 32)
    
    if(equal(className, "weaponbox") || equal(className, "armoury_entity") || equal(className, "grenade"))
    {
        engfunc(EngFunc_SetModel, entity, WORLD_MODEL)
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}