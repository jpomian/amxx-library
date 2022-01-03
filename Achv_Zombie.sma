#include < Amxmodx >
#include < achievements >
#include < fakemeta >
#include < hamsandwich >
#include < engine >
#include < cstrike >
#include <colorchat>

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )
#define IsUserInAir(%1) ( ~pev( %1, pev_flags ) & FL_ONGROUND )
#define f(%1,%2,%3,%4) formatex(%1, charsmax(%1), "%s \y (\r%i/%i\y)%s",%2, GetProgress(id, %3)>%4 ? %4 : GetProgress(id, %3), %4,  HaveAchievement(id, %3) ? "\w - Odblokowane!" : "")
#define c(%1,%2) ColorChat(id, GREEN, "[%s]^x01 %s.", %1, %2)

const ONE_HOUR = 60;
const ONE_DAY  = 1440;

new ACH_ADDICT,
ACH_PLAY_AROUND,
ACH_DAY_MARATHON,
ACH_ROUNDS1,
ACH_ROUNDS2,
ACH_ART_OF_WAR,
ACH_BODY_BAGGER,
ACH_GOD_OF_WAR,
ACH_DEAD_MAN;
new ACH_UNSTOPPABLE,
ACH_BATTLE_ZERO,
ACH_FAVOR_POINTS,
ACH_MADE_POINTS,
ACH_HAT_TRICK,
ACH_DOUBLE_KILL,
ACH_CASH,
ACH_GRENADE,
ACH_GOLDEN_MEDAL;
new ACH_HARD_WAY,
ACH_VANDALISM,
ACH_HARDCORE,
ACH_HUMILIATE;

new Float:g_flGrenade[ 33 ], Float:g_flDoubleKill, g_iDoubleKiller;
new bool:g_bFirstConnect[ 33 ], g_iPlayTime[ 33 ];
new g_iKillsInRound[ 33 ], g_iHsInRow[ 33 ], g_iMaxPlayers, g_iLastMoney[ 33 ];
new g_iMapKills[ 33 ];
new Float:g_vDeathOrigin[ 33 ][ 3 ];

new const achsNazwy[][] = 
{
"Dobry start",
"Weteran",
"Sztuka wojny",
"Zoltodziob",
"Bog wojny",
"Farciarz",
"Niepowstrzymany",
"Celne oko",
"Zdobyte punkty",
"Totolotek",
"Hat Trick",
"Oszczednosc amunicji",
"Reparacje wojenne",
"Uzalezniony",
"Pierwsza godzina",
"1-dzienny maratonczyk",
"Hardcore",
"Zloty medal",
"Grenadier",
"Mistrz Teabagu"
}
new const achsOpisy[][] =
{
"Wygraj 10 rund",
"Wygraj 250 rund",
"Zrob spreja 100 razy",
"Zabij 100 zombie",
"Zabij 1000 zombie",
"Zabij zombie majac 1 hp",
"Zabij 8 zombie w jednej turze",
"Zabij 250 zombie headshotem",
"Zadaj lacznie 50,000 obrazen",
"Zadaj lacznie 1,000,000 obrazen",
"Wstrzel 3 headshoty w jednej rundzie",
"Zabij 2 zombie jednym nabojem",
"Zdobadz lacznie 250,000 dolarow",
"Polacz sie z serwerem 500 razy",
"Przegraj na serwerze 1 godzine",
"Przegraj na serwerze 24 godziny",
"Przegraj na serwerze 100 godzin",
"Zdobadz 10 osiagniec",
"Zabij dwoch zombie jednym granatem",
"Zrob spreja na 15 martwych CT"
}
new const achsWymagania[] = { 10, 250, 100, 100, 1000, 1, 1, 250, 50000, 1000000, 1, 1, 250000, 500, 1, 1, 1, 1, 1, 15}
new const AchievementMenuCommands[][] =
{
"say /achs",
"say_team /achs",
"say /osiagniecia",
"say_team /osiagniecia"
};

public plugin_init( )
{
register_plugin( "Dust2: Achievements", "1.0", "xPaw" );

g_iMaxPlayers = get_maxplayers( );


ACH_ROUNDS1       = RegisterAchievement( "Dobry start", "Wygraj 10 rund", 10 );
ACH_ROUNDS2       = RegisterAchievement( "Weteran", "Wygraj 250 rund", 250 );
ACH_ART_OF_WAR    = RegisterAchievement( "Sztuka wojny", "Zrob spreja 100 razy", 100 );
ACH_BODY_BAGGER   = RegisterAchievement( "Zoltodziob", "Zabij 100 zombie", 100 );
ACH_GOD_OF_WAR    = RegisterAchievement( "Bog wojny", "Zabij 1000 zombie", 1000 );
ACH_DEAD_MAN      = RegisterAchievement( "Farciarz", "Zabij zombie majac 1 hp", 1 );
ACH_UNSTOPPABLE   = RegisterAchievement( "Niepowstrzymany", "Zabij 8 zombie w jednej turze", 1 );
ACH_BATTLE_ZERO   = RegisterAchievement( "Celne oko", "Zabij 250 zombie headshotem", 250 );
ACH_FAVOR_POINTS  = RegisterAchievement( "Zdobyte punkty", "Zadaj lacznie 50,000 obrazen", 50000 );
ACH_MADE_POINTS   = RegisterAchievement( "Totolotek", "Zadaj lacznie 1,000,000 obrazen", 1000000 );
ACH_HAT_TRICK     = RegisterAchievement( "Hat Trick", "Wstrzel 3 headshoty w jednej rundzie", 1 );
ACH_DOUBLE_KILL   = RegisterAchievement( "Oszczednosc amunicji", "Zabij 2 zombie jednym nabojem", 1 );
ACH_CASH          = RegisterAchievement( "Reparacje wojenne", "Zdobadz lacznie 250,000 dolarow", 250000 );
ACH_ADDICT        = RegisterAchievement( "Uzalezniony", "Polacz sie z serwerem 500 razy", 500 );
ACH_PLAY_AROUND   = RegisterAchievement( "Pierwsza godzina", "Przegraj na serwerze 1 godzine", 1 );
ACH_DAY_MARATHON  = RegisterAchievement( "1-dzienny maratonczyk", "Przegraj na serwerze 24 godziny", 1 );
ACH_HARDCORE   = RegisterAchievement( "Hardcore", "Przegraj na serwerze 100 godzin", 1 );
ACH_GOLDEN_MEDAL  = RegisterAchievement( "Zloty medal", "Zdobadz 10 osiagniec", 1 );
ACH_HARD_WAY      = RegisterAchievement( "Grenadier", "Zabij dwoch zombie jednym granatem", 1 );
ACH_HUMILIATE     = RegisterAchievement( "Mistrz Teabagu", "Zrob spreja na 15 martwych CT", 15 );


RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerTakeDamage", true );
RegisterHam( Ham_TakeDamage, "func_breakable", "FwdBreakableThink", true );
RegisterHam( Ham_TakeDamage, "func_pushable", "FwdBreakableThink", true );

register_event( "Money", "EventMoney", "b" );
register_event( "DeathMsg", "EventDeathMsg", "a", "1>0", "2>0" );
register_event( "HLTV", "EventRoundStart", "a", "1=0", "2=0" );
register_event( "SendAudio", "EventSendAudio", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin" );
register_event( "23", "EventSpray", "a", "1=112" );
register_event( "ClCorpse", "EventClCorpse", "a" );

for(new i=0; i < sizeof AchievementMenuCommands; i++)
register_clcmd(AchievementMenuCommands[i], "MenuOsiagniec")

//g_tWeaponAchievements = TrieCreate( );

/*
http://wiki.amxmodx.org/CS_Weapons_Information
*/

/*TrieSetCell( g_tWeaponAchievements, "usp",       ACH_PISTOL1 );
TrieSetCell( g_tWeaponAchievements, "glock18",   ACH_PISTOL2 );
TrieSetCell( g_tWeaponAchievements, "deagle",    ACH_PISTOL3 );
TrieSetCell( g_tWeaponAchievements, "elite",     ACH_PISTOL4 );
TrieSetCell( g_tWeaponAchievements, "fiveseven", ACH_PISTOL5 );
TrieSetCell( g_tWeaponAchievements, "p228",      ACH_PISTOL6 );

TrieSetCell( g_tWeaponAchievements, "m4a1",      ACH_M4A1 );
TrieSetCell( g_tWeaponAchievements, "ak47",      ACH_AK47 );
TrieSetCell( g_tWeaponAchievements, "awp",       ACH_AWP );
TrieSetCell( g_tWeaponAchievements, "scout",     ACH_SCOUT );
TrieSetCell( g_tWeaponAchievements, "famas",     ACH_FAMAS );
TrieSetCell( g_tWeaponAchievements, "galil",     ACH_GALIL );
TrieSetCell( g_tWeaponAchievements, "mp5navy",   ACH_MP5 );*/
}

public Achv_Unlock( const id, const iAchievement )
{
new iUnlocks = GetUnlocksCount( id ) + 1;

if( 10 < iUnlocks < 20 )
{
new iData[ 1 ]; iData[ 0 ] = ACH_GOLDEN_MEDAL;

set_task( 0.1, "TaskUnlockAchievement", id, iData, 1 );

//AchievementProgress( id, ACH_GOLDEN_MEDAL );
}
}

public TaskUnlockAchievement( iData[ ], id )
{
AchievementProgress( id, iData[ 0 ] );
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
g_iPlayTime[ id ] = iPlayTime;

AchievementProgress( id, ACH_ADDICT );
}

public client_putinserver( id )
{
g_iMapKills[ id ] = 0;
g_iHsInRow[ id ] = 0;
g_iLastMoney[ id ] = 0;
g_iKillsInRound[ id ] = 0;
g_bFirstConnect[ id ] = true;
}
public MenuOsiagniec(id) {

new plAchs = GetUnlocksCount(id);
new achsStrBuffer1[128];
new achsStrBuffer2[128];
new achsStrBuffer3[128];
new achsStrBuffer4[128];
new achsStrBuffer5[128];
new achsStrBuffer6[128];
new achsStrBuffer7[128];
new achsStrBuffer8[128];
new achsStrBuffer9[128];
new achsStrBuffer10[128];
new achsStrBuffer11[128];
new achsStrBuffer12[128];
new achsStrBuffer13[128];
new achsStrBuffer14[128];
new achsStrBuffer15[128];
new achsStrBuffer16[128];
new achsStrBuffer17[128];
new achsStrBuffer18[128];
new achsStrBuffer19[128];
new achsStrBuffer20[128];
new achsTitle[128];

formatex(achsTitle, charsmax(achsTitle), "\y Lista Osiagniec - Masz\r [%i/%i]", plAchs, GetUnlocksCount(0));
new aMenu = menu_create(achsTitle, "aMenuHandler");
f(achsStrBuffer1, achsNazwy[0], ACH_ROUNDS1, achsWymagania[0])
f(achsStrBuffer2, achsNazwy[1], ACH_ROUNDS2, achsWymagania[1])
f(achsStrBuffer3, achsNazwy[2], ACH_ART_OF_WAR, achsWymagania[2])
f(achsStrBuffer4, achsNazwy[3], ACH_BODY_BAGGER, achsWymagania[3])
f(achsStrBuffer5, achsNazwy[4], ACH_GOD_OF_WAR, achsWymagania[4])
f(achsStrBuffer6, achsNazwy[5], ACH_DEAD_MAN, achsWymagania[5])
f(achsStrBuffer7, achsNazwy[6], ACH_UNSTOPPABLE, achsWymagania[6])
f(achsStrBuffer8, achsNazwy[7], ACH_BATTLE_ZERO, achsWymagania[7])
f(achsStrBuffer9, achsNazwy[8], ACH_FAVOR_POINTS, achsWymagania[8])
f(achsStrBuffer10, achsNazwy[9], ACH_MADE_POINTS, achsWymagania[9])
f(achsStrBuffer11, achsNazwy[10], ACH_HAT_TRICK, achsWymagania[10])
f(achsStrBuffer12, achsNazwy[11], ACH_DOUBLE_KILL, achsWymagania[11])
f(achsStrBuffer13, achsNazwy[12], ACH_CASH, achsWymagania[12])
f(achsStrBuffer14, achsNazwy[13], ACH_ADDICT, achsWymagania[13])
f(achsStrBuffer15, achsNazwy[14], ACH_PLAY_AROUND, achsWymagania[14])
f(achsStrBuffer16, achsNazwy[15], ACH_DAY_MARATHON, achsWymagania[15])
f(achsStrBuffer17, achsNazwy[16], ACH_HARDCORE, achsWymagania[16])
f(achsStrBuffer18, achsNazwy[17], ACH_GOLDEN_MEDAL, achsWymagania[17])
f(achsStrBuffer19, achsNazwy[18], ACH_HARD_WAY, achsWymagania[18])
f(achsStrBuffer20, achsNazwy[19], ACH_HUMILIATE, achsWymagania[19])

menu_additem(aMenu, achsStrBuffer1)
menu_additem(aMenu, achsStrBuffer2)
menu_additem(aMenu, achsStrBuffer3)
menu_additem(aMenu, achsStrBuffer4)
menu_additem(aMenu, achsStrBuffer5)
menu_additem(aMenu, achsStrBuffer6)
menu_additem(aMenu, achsStrBuffer7)
menu_additem(aMenu, achsStrBuffer8)
menu_additem(aMenu, achsStrBuffer9)
menu_additem(aMenu, achsStrBuffer10)
menu_additem(aMenu, achsStrBuffer11)
menu_additem(aMenu, achsStrBuffer12)
menu_additem(aMenu, achsStrBuffer13)
menu_additem(aMenu, achsStrBuffer14)
menu_additem(aMenu, achsStrBuffer15)
menu_additem(aMenu, achsStrBuffer16)
menu_additem(aMenu, achsStrBuffer17)
menu_additem(aMenu, achsStrBuffer18)
menu_additem(aMenu, achsStrBuffer19)
menu_additem(aMenu, achsStrBuffer20)


menu_setprop(aMenu, MPROP_EXIT, 0);
menu_display(id, aMenu);

return PLUGIN_HANDLED

}
public aMenuHandler(id, aMenu, item) {

if(item == MENU_EXIT)
{
return PLUGIN_CONTINUE;
}
switch(item)
{
			case 0: c(achsNazwy[0], achsOpisy[0])
			case 1: c(achsNazwy[1], achsOpisy[1])
			case 2: c(achsNazwy[2], achsOpisy[2])
			case 3: c(achsNazwy[3], achsOpisy[3])
			case 4: c(achsNazwy[4], achsOpisy[4])
			case 5: c(achsNazwy[5], achsOpisy[5])
			case 6: c(achsNazwy[6], achsOpisy[6])
			case 7: c(achsNazwy[7], achsOpisy[7])
			case 8: c(achsNazwy[8], achsOpisy[8])
			case 9: c(achsNazwy[9], achsOpisy[9])
			case 10: c(achsNazwy[10], achsOpisy[10])
			case 11: c(achsNazwy[11], achsOpisy[11])
			case 12: c(achsNazwy[12], achsOpisy[12])
			case 13: c(achsNazwy[13], achsOpisy[13])
			case 14: c(achsNazwy[14], achsOpisy[14])
			case 15: c(achsNazwy[15], achsOpisy[15])
			case 16: c(achsNazwy[16], achsOpisy[16])
			case 17: c(achsNazwy[17], achsOpisy[17])
			case 18: c(achsNazwy[18], achsOpisy[18])
			case 19: c(achsNazwy[19], achsOpisy[19])
		}
return PLUGIN_CONTINUE;
}
public FwdHamPlayerSpawnPost( const id )
{
	if( !is_user_alive( id ) )
		return;
	
	if( g_bFirstConnect[ id ] )
	{
		g_bFirstConnect[ id ] = false;
		
		if( g_iPlayTime[ id ] >= ONE_HOUR )
		{
			AchievementProgress( id, ACH_PLAY_AROUND );
			
			if( g_iPlayTime[ id ] >= ONE_DAY )
				AchievementProgress( id, ACH_DAY_MARATHON );
			
			if( g_iPlayTime[ id ] >= ONE_HOUR*100 )
				AchievementProgress( id, ACH_HARDCORE );
		}
	}
	
	g_flGrenade[ id ] = 0.0;
}

public FwdHamPlayerTakeDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits )
{
	if( iDamageBits & DMG_FALL || id == iAttacker || !IsPlayer( iAttacker ) )
	{
		return;
	}
	
	if( get_user_team( iAttacker ) != get_user_team( id ) )
	{
		new iDamage = floatround( flDamage );
		
		if( iDamageBits & ( 1 << 24 ) )
		{
			g_flGrenade[ id ] += flDamage;
		}
		
		AchievementProgress( iAttacker, ACH_FAVOR_POINTS, iDamage );
		AchievementProgress( iAttacker, ACH_MADE_POINTS, iDamage );
	}
}
public FwdBreakableThink( const iEntity, const iInflictor, const id )
	if( is_user_alive( id ) && entity_get_float( iEntity, EV_FL_health ) <= 0 )
	AchievementProgress( id, ACH_VANDALISM );

public EventMoney( const id )
{
	new iMoney = read_data( 1 ),
	iLast  = g_iLastMoney[ id ];
	
	if( iMoney > iLast )
	{
		AchievementProgress( id, ACH_CASH, ( iMoney - iLast ) );
	}
	
	g_iLastMoney[ id ] = iMoney;
}

public EventRoundStart( )
{
	arrayset( g_iHsInRow, 0, 33 );
	arrayset( g_iKillsInRound, 0, 33 );
}

public EventSendAudio( )
{
	if( get_playersnum( ) < 4 ) return;
	
	new iPlayers[ 32 ], iNum, id;
	read_data( 2, iPlayers, 8 );
	
	new CsTeams:iWinner = iPlayers[ 7 ] == 't' ? CS_TEAM_T : CS_TEAM_CT;
	
	get_players( iPlayers, iNum, "c" );
	
	for( new i; i < iNum; i++ )
	{
		id = iPlayers[ i ];
		
		if( is_user_alive( id ) && cs_get_user_team( id ) == iWinner )
		{
			AchievementProgress( id, ACH_ROUNDS1 );
			AchievementProgress( id, ACH_ROUNDS2 );
		}
	}
}
public EventClCorpse( )
{
	if( read_data( 11 ) != 2 ) // CS_TEAM_CT
	{
		return;
	}
	
	new id = read_data( 12 );
	
	read_data( 2, g_vDeathOrigin[ id ][ 0 ] );
	read_data( 3, g_vDeathOrigin[ id ][ 1 ] );
	read_data( 4, g_vDeathOrigin[ id ][ 2 ] );
	
	g_vDeathOrigin[ id ][ 0 ] /= 128.0;
	g_vDeathOrigin[ id ][ 1 ] /= 128.0;
	g_vDeathOrigin[ id ][ 2 ] /= 128.0;
}
public EventSpray( )
{
	new id = read_data( 2 );
	
	AchievementProgress( id, ACH_ART_OF_WAR );
	
	if( cs_get_user_team( id ) != CS_TEAM_T )
	{
		return;
	}
	
	new Float:vOrigin[ 3 ], iPlayers[ 32 ], iNum, iPlayer;
	
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	get_players( iPlayers, iNum, "be", "CT" );
	
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( get_distance_f( vOrigin, g_vDeathOrigin[ iPlayer ] ) < 80.0 )
		{
			AchievementProgress( id, ACH_HUMILIATE );
			
			break;
		}
	}
}

public EventDeathMsg( )
{
	new iVictim = read_data( 2 ), iKiller = read_data( 1 );
	
	if( iKiller == iVictim )
	{
		return;
	}
	
	AchievementProgress( iKiller, ACH_BODY_BAGGER );
	AchievementProgress( iKiller, ACH_GOD_OF_WAR );
	
	if( ++g_iKillsInRound[ iKiller ] == 8 )
	{
		AchievementProgress( iKiller, ACH_UNSTOPPABLE );
	}
	
	new szWeapon[ 12 ];
	read_data( 4, szWeapon, 11 );
	
	if( read_data( 3 ) ) // headshot
	{
		AchievementProgress( iKiller, ACH_BATTLE_ZERO );
		
		if( ++g_iHsInRow[ iKiller ] == 3 )
			AchievementProgress( iKiller, ACH_HAT_TRICK );
	}
	
	// Double kill check
	new Float:flGameTime = get_gametime( );
	
	if( g_iDoubleKiller == iKiller && g_flDoubleKill == flGameTime )
	{
		AchievementProgress( iKiller, ( szWeapon[ 0 ] == 'g' && szWeapon[ 1 ] == 'r' ) ? ACH_HARD_WAY : ACH_DOUBLE_KILL );
	}
	
	g_iDoubleKiller = iKiller;
	g_flDoubleKill  = flGameTime;
	
	if( is_user_alive( iKiller ) )
	{
		if( get_user_health( iKiller ) == 1 )
		{
			AchievementProgress( iKiller, ACH_DEAD_MAN );
		}
	} 
	else
	{
		if( szWeapon[ 0 ] == 'g' && szWeapon[ 1 ] == 'r' )
		{
			AchievementProgress( iKiller, ACH_GRENADE );
		}
	}
}

/*GetUserIndex( ) {
new szLogUser[ 80 ], szName[ 32 ];
read_logargv( 0, szLogUser, 79 );
parse_loguser( szLogUser, szName, 31 );

return get_user_index( szName );
}*/