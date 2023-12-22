

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <engine>

#define APPROVED_FLAG (get_user_flags(id) & ADMIN_LEVEL_A)

new AK_V_MODEL[64] = "models/biohazard/winner/v_golden_ak47.mdl"
new AK_P_MODEL[64] = "models/biohazard/winner/p_golden_ak47.mdl"
new bool:g_HasAk[33]

public plugin_init()
{
    register_event("CurWeapon","checkWeapon","be","1=1")
    register_event("WeapPickup","checkModel","b","1=19");
}

public plugin_precache(){
	precache_model(AK_V_MODEL);
	precache_model(AK_P_MODEL);
}

public client_putinserver(id)
{
    if(get_user_flags(id) & APPROVED_FLAG)
		g_HasAk[ id ] = true;
}

public client_connect(id)
{
	g_HasAk[id] = false
}

public client_disconnected(id)
{
	g_HasAk[id] = false
}

public checkModel(id)
{
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_AK47 && g_HasAk[id] == true )
	{
		set_pev(id, pev_viewmodel2, AK_V_MODEL)
		set_pev(id, pev_weaponmodel2, AK_P_MODEL)
	}

	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_AK47 && g_HasAk[id])
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}