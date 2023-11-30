#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <celltrie>
#include <colorchat>

new const Version[] = "0.1";

new const g_moneyReward = 1000;

new Trie:g_Trie;

public plugin_init() 
{
    register_plugin( "Multi Grenade Kill" , Version , "bugsy" );
    
    RegisterHam( Ham_TakeDamage , "player" , "fw_HamTakeDamage" , 1 );
    register_think( "grenade" , "fw_GrenadeThink" );

    g_Trie = TrieCreate();
}

public plugin_end()
{
    TrieDestroy( g_Trie );
}

public fw_GrenadeThink( iEntity ) 
{
    //This gets called 3 times when the condition ( get_gametime() > entity_get_float( iEntity, EV_FL_dmgtime ) is checked.
    //The third and last time always occurred at approx 0.650005 in my tests.
    if( !is_valid_ent( iEntity ) || ( ( get_gametime() - entity_get_float( iEntity, EV_FL_dmgtime ) ) < 0.64 ) )
        return;
    
    new szKey[ 4 ];
    num_to_str( iEntity , szKey , charsmax( szKey ) );
    
    if ( TrieKeyExists( g_Trie , szKey ) )
    {
        new iKills;
        TrieGetCell( g_Trie , szKey , iKills );
        
        if ( iKills > 1 )
        {
            new szOwner[ 9 ] , iKiller , szName[ 33 ]
            formatex( szOwner , charsmax( szOwner ) , "%s%s" , szKey , "OWNER" );
            TrieGetCell( g_Trie , szOwner , iKiller );
            
            get_user_name( iKiller , szName , charsmax( szName ) );
            ColorChat( 0 , GREEN , "*^x01 %s zabil granatem %d zombie!" , szName , iKills );
            cs_set_user_money(iKiller, cs_get_user_money(iKiller) + g_moneyReward*(iKills - 1))
            
            TrieDeleteKey( g_Trie , szOwner );
        }
        
        TrieDeleteKey( g_Trie , szKey );
    }
}

public fw_HamTakeDamage( iVictim , iInflictor , iAttacker , Float:fDamage , iDamageBits )
{
    if ( iInflictor && ( iInflictor != iAttacker ) && !is_user_alive( iVictim ) && ( fm_cs_get_grenade_type( iInflictor ) == CSW_HEGRENADE ) )
    {
        new szKey[ 4 ] , szOwner[ 9 ] , iKillCount;
        num_to_str( iInflictor , szKey , charsmax( szKey ) );
        formatex( szOwner , charsmax( szOwner ) , "%sOWNER" , szKey );
        TrieGetCell( g_Trie , szKey , iKillCount );
        TrieSetCell( g_Trie , szKey , ++iKillCount );
        TrieSetCell( g_Trie , szOwner , iAttacker );
    }
}

fm_cs_get_grenade_type( index ) 
{
    if (!pev_valid(index))
        return 0
    
    new classname[9]
    pev(index, pev_classname, classname, 8)
    if (!equal(classname, "grenade"))
        return 0
    
    if (get_pdata_int(index, 96) & (1<<8))
        return CSW_C4
    
    new bits = get_pdata_int(index, 114)
    if (bits & (1<<0))
        return CSW_HEGRENADE
    else if (bits & (1<<1))
        return CSW_SMOKEGRENADE
    else if (!bits)
        return CSW_FLASHBANG
    
    return 0
} 