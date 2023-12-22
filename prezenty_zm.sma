#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <biohazard>
#include <prezenty>
 
#define PLUGIN "Prezenty Zombie"
#define VERSION "1.0"
#define AUTHOR "Mix"

native get_player_modelent(id);
native set_user_kbimmunity(id, Float:fReduction, bool:isDucking);
native give_user_fireammo(id);
 
new pcvar_spawntime
new g_szSounds[][] = {
	"items/gunpickup4.wav",
	"biohazard/hohoho.wav"
};
new gScreenFadeMsg

new g_zmColors[3] = { 246, 129, 129 }
new g_ctColors[3] = { 91, 124, 153 }

public plugin_init() {

	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_gift("Prezent", "PrezentPickup");
	register_event("HLTV", "eventRoundInit", "a", "1=0", "2=0");

	pcvar_spawntime = register_cvar("gift_resptime", "25.0")

	set_task(get_pcvar_float(pcvar_spawntime), "taskSpawnGift", 2368, _, _, "b");

	gScreenFadeMsg = get_user_msgid("ScreenFade")
}

public plugin_precache() {
	for(new i = 0; i < sizeof g_szSounds; i++) 
    	precache_sound(g_szSounds[i])
}

public eventRoundInit()
{
	gifts_clear_map();
	
	for(new i = 1; i <= get_maxplayers(); i++) { 
		if(is_user_alive(i))
		{
			fm_set_rendering(i, kRenderFxNone, 255, 255, 255, kRenderNormal, 16);
			if(get_user_armor(i) >= 100)
				set_user_armor(i, 0)
			set_user_kbimmunity(i, 0.0, false)
		}
	}
}
 
public taskSpawnGift()
{
	gift_spawn(GIFT_RANDOM);
}
 
public PrezentPickup(id)
{
	if(is_user_zombie(id))
    {
		set_dhudmessage(246, 129, 129, -1.0, 0.7, 2, 0.01, 6.0, 0.07, 0.07)
		screenfade(id, 1)
		switch(random(100))
        {
            case 0..50:
			{
				new money, prize;
				money = cs_get_user_money(id);
				prize = 100 * random_num(5,20);
				cs_set_user_money(id, money + prize, 1);
				show_dhudmessage(id, "Kasa: +$%i", prize)
			}
			case 51..83: {
				new health, hpPack;
				health = get_user_health(id);
				hpPack = 10 * random_num(20, 60);
				set_user_health(id, health + hpPack);
				show_dhudmessage(id, "Zdrowie: +%i HP", hpPack)
			}
			case 84..100: {
				fm_set_rendering(id, kRenderFxGlowShell, 64, 64, 64, kRenderNormal, 1);
				cs_set_user_armor(id, 666, CS_ARMOR_VESTHELM)
				set_user_kbimmunity(id, 0.8, false);
				show_dhudmessage(id, "RZADKA NAGRODA!^nTytanowa Skóra")
			}
        }
	} else {
		set_dhudmessage(91, 124, 153, -1.0, 0.7, 2, 0.01, 6.0, 0.07, 0.07)
		screenfade(id, 2)
		switch(random(100))
        {
            case 0..30: {
				new money, prize;
				money = cs_get_user_money(id);
				prize = 100 * random_num(5,20);
				cs_set_user_money(id, money + prize, 1);
				show_dhudmessage(id, "Kasa: +$%i", prize)
			}
			case 31..70: {
				if(!user_has_weapon(id, CSW_SMOKEGRENADE))
				{
					give_item(id, "weapon_smokegrenade")
					show_dhudmessage(id, "Granat: Zamrazacz")
				}
				else {
					give_item(id, "weapon_flashbang")
					give_item(id, "weapon_flashbang")
					show_dhudmessage(id, "Granat: 2x Flara")
				}
			}
			case 71..85: {
				set_user_armor(id, get_user_armor(id) + 66);
				show_dhudmessage(id, "RZADKA NAGRODA!^nKamizelka antyinfekcyjna")
			}
			case 86..100: {
				give_user_fireammo(id);
				show_dhudmessage(id, "RZADKA NAGRODA!^nPłonące naboje")
			}
        }
	}

	emit_sound(id, CHAN_STATIC, g_szSounds[0], VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
	emit_sound(id, CHAN_STATIC, g_szSounds[1], VOL_NORM, ATTN_NONE, 0, PITCH_NORM)

}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)

	new ent = entity;
	
	if(is_user_connected(entity))
	{
		ent = get_player_modelent(entity);
	}

	set_pev(ent, pev_renderfx, fx)
	set_pev(ent, pev_rendercolor, color)
	set_pev(ent, pev_rendermode, render)
	set_pev(ent, pev_renderamt, float(amount))
}

stock screenfade(index, team) {
    
	static rgb[3];

	if(team == 1) {
		rgb[0] = g_zmColors[0];
		rgb[1] = g_zmColors[1];
		rgb[2] = g_zmColors[2];
	} else {
		rgb[0] = g_ctColors[0];
		rgb[1] = g_ctColors[1];
		rgb[2] = g_ctColors[2];
	}

	message_begin(MSG_ONE, gScreenFadeMsg, _, index)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0)
	write_byte(rgb[0])
	write_byte(rgb[1])
	write_byte(rgb[2])
	write_byte(120) //alpha
	message_end()

}