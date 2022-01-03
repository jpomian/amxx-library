#include <amxmodx>
#include <fakemeta>

#define VERSION "0.0.1"
#define PLUGIN "Personal FlashLight"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, "ConnorMcLeod")
    register_forward(FM_AddToFullPack, "AddToFullPack_Post", true)
}

public AddToFullPack_Post(es, e, ent, id, hostflags, player )
{
    static bitEffects
    if(    player
    &&    ent != id
    &&    get_orig_retval()
    &&    (bitEffects = get_es(es, ES_Effects)) & EF_DIMLIGHT    )
    {
        set_es(es, ES_Effects, bitEffects & ~EF_DIMLIGHT)
    }
}
