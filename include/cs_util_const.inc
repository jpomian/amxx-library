#include <reapi>

#define BIT_ADD(%0,%1)					(%0 |= (1 << (%1)))
#define BIT_SUB(%0,%1)					(%0 &= ~(1 << (%1)))
#define BIT_VALID(%0,%1)				(%0 & (1 << (%1)))
#define BIT_NOT_VALID(%0,%1)			(~(%0) & (1 << (%1)))

#define CS_GET_CURRENT_WEAPON_ENTITY(%0)	get_member(%0, m_pActiveItem) // fm_cs_get_current_weapon_ent
#define CS_GET_WEAPON_ID(%0)				get_member(get_member(%0, m_pActiveItem), m_iId) // cs_get_weapon_id
#define CS_GET_WEAPON_ENTITY_OWNER(%0)		get_member(%0, m_pPlayer) // fm_cs_get_weapon_ent_owner
#define CS_SET_USER_NEXT_ATTACK(%0,%1)		set_member(%0, m_flNextAttack, %1) // fm_cs_set_user_next_attack
#define GET_USER_NAME(%0,%1,%2)				get_entvar(%0, var_netname, %1, %2) // get_user_name
#define CS_GET_USER_TEAM(%0)				get_member(%0, m_iTeam) // cs_get_user_team
#define CS_SET_USER_TEAM(%0,%1)				set_member(%0, m_iTeam, %1) // cs_set_user_team
#define CS_GET_USER_MONEY(%0)				get_member(%0, m_iAccount) // cs_get_user_money
#define CS_SET_USER_MONEY(%0,%1)			set_member(%0, m_iAccount, %1) // cs_set_user_money
#define GET_USER_ARMOR(%0)					get_entvar(%0, var_armorvalue) // get_user_armor
#define SET_USER_ARMOR(%0,%1)				set_entvar(%0, var_armorvalue, %1) // set_user_armor

#define CS_SET_WEAPON_AMMO(%0,%1)			set_member(%0, m_Weapon_iClip, %1) // cs_set_weapon_ammo

// fun
#define SET_USER_HEALTH(%0,%1)				set_entvar(%0, var_health, %1) // set_user_health
#define GET_USER_HEALTH(%0)					get_entvar(%0, var_health) // get_user_health
#define GET_USER_GRAVITY(%0)				get_entvar(%0, var_gravity) // get_user_gravity
#define SET_USER_GRAVITY(%0,%1)				set_entvar(%0, var_gravity, %1) // set_user_gravity

#if !defined CsTeams

	enum CsTeams
	{
		CS_TEAM_UNASSIGNED = 0,
		CS_TEAM_T = 1,
		CS_TEAM_CT = 2,
		CS_TEAM_SPECTATOR = 3
	};

#endif
