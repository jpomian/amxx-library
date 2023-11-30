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

new OLDWORLD_MODEL[] = "models/w_hegrenade.mdl";


new PLUGIN_NAME[]        = "Custom Grenade Models" 
new PLUGIN_AUTHOR[]    = "Cheap_Suit ft. Mix" 
new PLUGIN_VERSION[]     = "1.0" 

new g_map[4], bool:g_bZmMode;

public plugin_init() 
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)     
    register_event("CurWeapon", "Event_CurWeapon", "be","1=1")
    register_forward(FM_SetModel, "fw_SetModel")

    get_mapname(g_map, charsmax(g_map))
    g_bZmMode = equali(g_map, "zm", 2) ? true : false;
} 

public plugin_precache() 
{
    for(new i=0; i<=sizeof(VIEW_MODELS); i++)
    {
        precache_model(VIEW_MODELS[i])     
        precache_model(PLAYER_MODELS[i]) 
        if( i != 2) precache_model(WORLD_MODELS[i])
    }
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

public fw_SetModel(entity, model[]) //do poprawy
{
    if(!is_valid_ent(entity)) 
        return FMRES_IGNORED

    if(!equali(model, OLDWORLD_MODEL)) 
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