#include <cs_util_const>
#include <fakemeta>

new stock __g_Message_ID_ScreenFade = -1;

#define MESSAGE_ID_SCREEN_FADE (__g_Message_ID_ScreenFade != -1 ? __g_Message_ID_ScreenFade : (__g_Message_ID_ScreenFade = get_user_msgid("ScreenFade")))

stock UTIL_ScreenFade(iPlayer, iDuration, iHold_Time, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if (iPlayer == 0)
	{
		message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MESSAGE_ID_SCREEN_FADE);
	}
	
	else
	{
		engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MESSAGE_ID_SCREEN_FADE, {0.0, 0.0, 0.0}, iPlayer);
	}
	
	write_short(iDuration);
	write_short(iHold_Time);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

new stock __g_Message_ID_ScreenShake = -1;

#define MESSAGE_ID_SCREEN_SHAKE (__g_Message_ID_ScreenShake != -1 ? __g_Message_ID_ScreenShake : (__g_Message_ID_ScreenShake = get_user_msgid("ScreenShake")))

stock UTIL_ScreenShake(iPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MESSAGE_ID_SCREEN_SHAKE, {0.0, 0.0, 0.0}, iPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

new stock __g_Message_ID_SendAudio = -1;

#define MESSAGE_ID_SEND_AUDIO (__g_Message_ID_SendAudio != -1 ? __g_Message_ID_SendAudio : (__g_Message_ID_SendAudio = get_user_msgid("SendAudio")))

stock UTIL_SendAudio(iPlayer, iPitch = 100, const szPath_Sound[], any:...)
{
	new szBuffer[128];
	
	if (numargs() > 3)
	{
		vformat(szBuffer, charsmax(szBuffer), szPath_Sound, 4);
	}
	
	else
	{
		copy(szBuffer, charsmax(szBuffer), szPath_Sound);
	}
	
	if (iPlayer == 0)
	{
		message_begin(MSG_BROADCAST, MESSAGE_ID_SEND_AUDIO);
	}
	
	else
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MESSAGE_ID_SEND_AUDIO, {0.0, 0.0, 0.0}, iPlayer);
	}
	
	write_byte(iPlayer);
	write_string(szBuffer);
	write_short(iPitch);
	message_end();
}

new stock __g_Message_ID_BarTime = -1;

#define MESSAGE_ID_BAR_TIME (__g_Message_ID_BarTime != -1 ? __g_Message_ID_BarTime : (__g_Message_ID_BarTime = get_user_msgid("BarTime")))

stock UTIL_Show_Task_Bar(iPlayer, iTime)
{
	message_begin(MSG_ONE_UNRELIABLE, MESSAGE_ID_BAR_TIME, _, iPlayer);
	write_short(iTime);
	message_end();
}

stock UTIL_Weapon_Animation(iPlayer, iAnimation)
{
	set_pev(iPlayer, pev_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock UTIL_Player_Animation(iPlayer, const szAnimation[])
{
	new iAnim_Desired;
	
	new Float:fFrame_Rate;
	new Float:fGround_Speed;
	
	new bool:bLoops;
	
	if ((iAnim_Desired = lookup_sequence(iPlayer, szAnimation, fFrame_Rate, bLoops, fGround_Speed)) == -1)
	{
		iAnim_Desired = 0;
	}
	
	new Float:fGametime = get_gametime();
	
	set_entvar(iPlayer, var_frame, 0.0);
	set_entvar(iPlayer, var_framerate, 1.0);
	set_entvar(iPlayer, var_animtime, fGametime);
	set_entvar(iPlayer, var_sequence, iAnim_Desired);
	
	set_member(iPlayer, m_fSequenceLoops, bLoops);
	set_member(iPlayer, m_fSequenceFinished, 0);
	set_member(iPlayer, m_flFrameRate, fFrame_Rate);
	set_member(iPlayer, m_flGroundSpeed, fGround_Speed);
	set_member(iPlayer, m_flLastEventCheck, fGametime);
	set_member(iPlayer, m_Activity, ACT_RANGE_ATTACK1);
	set_member(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1);   
	set_member(iPlayer, m_flLastFired, fGametime); // m_flLastAttackTime
}

stock CREATE_BEAM_CYLINDER(Float:fVecOrigin[3], iRadius, iSprite, iStart_Frame = 0, iFrame_Rate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScroll_Speed = 0)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fVecOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, fVecOrigin[0]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[1]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[2]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[0]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[1]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[2] + 32.0 + iRadius * 2);
	write_short(iSprite);
	write_byte(iStart_Frame);
	write_byte(iFrame_Rate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScroll_Speed); // 0.1's
	message_end();
}

stock CREATE_BEAM_FOLLOW(iEntity, iSprite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(iSprite);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock CREATE_PLAYER_ATTACHMENT(iPlayer, iHeight = 50, iSprite, iLife)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(iPlayer);
	write_coord(iHeight);
	write_short(iSprite);
	write_short(iLife); // 0.1's
	message_end();
}

stock CREATE_KILL_PLAYER_ATTACHMENTS(iPlayer)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(iPlayer);
	message_end();
}

stock CREATE_KILLBEAM(iEntity)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(iEntity);
	message_end();
}

stock fm_set_kvd(iEntity, const szClassName[], const szKeyName[], const szValue[]) 
{
	set_kvd(0, KV_ClassName, szClassName);
	set_kvd(0, KV_KeyName, szKeyName);
	set_kvd(0, KV_Value, szValue);
	set_kvd(0, KV_fHandled, 0);
	
	return dllfunc(DLLFunc_KeyValue, iEntity, 0);
}

stock rh_set_user_rendering(iEntity, iFx = kRenderFxNone, r = 255, g = 255, b = 255, iRender = kRenderNormal, iAmount = 16)
{
	new Float:fRender_Color[3];
	
	fRender_Color[0] = float(r);
	fRender_Color[1] = float(g);
	fRender_Color[2] = float(b);
	
	set_entvar(iEntity, var_renderfx, iFx);
	set_entvar(iEntity, var_rendercolor, fRender_Color);
	set_entvar(iEntity, var_rendermode, iRender);
	set_entvar(iEntity, var_renderamt, float(iAmount));
}

// Set entity's rendering type (float parameters version)
stock rh_set_rendering_float(iEntity, iFX = kRenderFxNone, Float:fColor[3], iRender = kRenderNormal, Float:fAmount = 16.0)
{
	set_entvar(iEntity, var_renderfx, iFX);
	set_entvar(iEntity, var_rendercolor, fColor);
	set_entvar(iEntity, var_rendermode, iRender);
	set_entvar(iEntity, var_renderamt, fAmount);
}

// Get entity's aim origins (from fakemeta_util)
stock UTIL_fm_get_aim_origin(iPlayer, Float:fOrigin[3])
{
	static Float:fOrigin1[3];
	static Float:fOrigin2[3];
	
	pev(iPlayer, pev_origin, fOrigin1);
	pev(iPlayer, pev_view_ofs, fOrigin2);
	
	xs_vec_add(fOrigin1, fOrigin2, fOrigin1);
	
	pev(iPlayer, pev_v_angle, fOrigin2);
	
	engfunc(EngFunc_MakeVectors, fOrigin2);
	
	global_get(glb_v_forward, fOrigin2);
	
	xs_vec_mul_scalar(fOrigin2, 9999.0, fOrigin2);
	xs_vec_add(fOrigin1, fOrigin2, fOrigin2);
	
	engfunc(EngFunc_TraceLine, fOrigin1, fOrigin2, 0, iPlayer, 0);
	
	get_tr2(0, TR_vecEndPos, fOrigin);
}

enum
{
	INFO_TARGET,
	ENV_SPRITE,
	
	END
};

stock UTIL_Create_Entity(iEntity_Type)
{
	static iClass_Cache[END];
	
	static const sValid_Classes[END][] =
	{
		"info_target",
		"env_sprite"
	};
	
	new iReturn = -1;
	new iEntity = 0;
	
	if (iClass_Cache[iEntity_Type] || (iClass_Cache[iEntity_Type] = engfunc(EngFunc_AllocString, sValid_Classes[iEntity_Type]))) 
	{
		if (is_entity((iEntity = engfunc(EngFunc_CreateNamedEntity, iClass_Cache[iEntity_Type])))) 
		{
			iReturn = iEntity;
		}
	}
	
	return iReturn;
}

stock UTIL_Play_Weapon_Animation(const iPlayer, const iSequence)
{
	set_entvar(iPlayer, var_weaponanim, iSequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = iPlayer);
	write_byte(iSequence);
	write_byte(0);
	message_end();
}

stock _fm_get_speed(iEntity)
{
	new Float:fVel[3];
	
	get_entvar(iEntity, var_velocity, fVel);
	
	return floatround(vector_length(fVel));
}

// Check if a player is stuck (credits to VEN)
stock Is_Player_Stuck(iPlayer)
{
	static Float:fOrigin[3];
	
	get_entvar(iPlayer, var_origin, fOrigin);
	
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, (get_entvar(iPlayer, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, iPlayer, 0);
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
	{
		return true;
	}
	
	return false;
}

// Checks if a space is vacant (credits to VEN)
stock Is_Hull_Vacant(Float:fOrigin[3], iHull)
{
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, iHull, 0, 0);
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
	{
		return true;
	}
	
	return false;
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock Str_Count(const sStr[], iSearch_Char)
{
	new iCount;
	new iLen = strlen(sStr);
	
	for (new i = 0; i <= iLen; i++)
	{
		if (sStr[i] == iSearch_Char)
		{
			iCount++
		}
	}
	
	return iCount;
}
