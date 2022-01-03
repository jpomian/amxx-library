#include <amxmodx>
#include <csx>

#define AUTHOR "aSior - amxx.pl/user/60210-asior/"

#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)
#define ForRangeLess(%1,%2,%3) for(new %1 = %2; %1 < %3; %1++)

// Comment this if your server allows changing nicknames.
#define GET_NAME_ONCE

new const configFilePath[] = "addons/amxmodx/configs/RanksConfig.ini";

new Array:rankName,
	Array:rankFrags[2],
	userRank[33];

#if defined GET_NAME_ONCE

new clientName[33][33];

#else

new clientName[33];

#endif

new const rankListMenuCommands[][] =
{
	"say /rangi",
	"say_team /rangi",
	"say /ranga",
	"say_team /ranga",
	"say /listarang",
	"say_team /listarang"
};

public plugin_init()
{
	register_plugin("x", "v0.1", AUTHOR);

	//register_message(get_user_msgid("SayText"), "handleSayText");
	
	ForRangeLess(i, 0, sizeof rankListMenuCommands)
		register_clcmd(rankListMenuCommands[i], "MainMenu");

	register_event("DeathMsg", "DeathMsg", "a");
}

public plugin_natives()
{
	register_native("GetCurrentRankProgress", "Native_GCRP", 1);
	register_native("GetNextRankFrags", "Native_GNRF", 1);
	register_native("GetUserRank", "Native_GUR", 1);
	register_native("GetUserRank", "native_GetUserRank", 1);
}

public native_GetUserRank(index)
	return userRank[index];
public Native_GCRP(index)
{
	static stats[8], blank[8];
	get_user_stats(index, stats, blank);

	return stats[0];
}

public Native_GNRF(index)
	return ArrayGetCell(rankFrags[0], userRank[index] + 1 < ArraySize(rankName) ? userRank[index] : ArraySize(rankName));

public Native_GUR(index, string[], length)
{
	param_convert(2);

	ArrayGetString(rankName, userRank[index], string, length);
}

public DeathMsg()
{
	new kid = read_data(1), vid = read_data(2);

	if(kid == vid || !is_user_connected(vid) || !is_user_connected(kid))
		return;

	GetUserRank(kid);
}

public client_authorized(index)
{
	#if defined GET_NAME_ONCE

	get_user_name(index, clientName[index], charsmax(clientName[]));

	#endif

	GetUserRank(index);
}

public GetUserRank(index)
{
	if(!ArraySize(rankName))
		return;

	new stats[8], blank[8]
	get_user_stats(index, stats, blank);

	if(userRank[index] == ArraySize(rankName))
		userRank[index] = ArraySize(rankName);
	else
	{
		ForRangeLess(i, 0, ArraySize(rankName))
		{
			if(stats[0] >= ArrayGetCell(rankFrags[1], i) && stats[0] <= ArrayGetCell(rankFrags[0], i))
			{
				userRank[index] = userRank[index] + 1 > ArraySize(rankName) ? ArraySize(rankName) : i;

				break;
			}
		}
	}
}

public plugin_precache()
	LoadConfigFile();

public LoadConfigFile()
{
	rankName = ArrayCreate(33, 1);

	ForRange(i, 0, 1)
		rankFrags[i] = ArrayCreate(1, 1);

	new LineText[60], Length, DataRead[4][64], Key[33], Value[64];

	for(new i = 0; read_file(configFilePath, i, LineText, charsmax(LineText), Length); i++)
	{
		if(LineText[0] == '/' || LineText[0] == ';' || LineText[0] == ' ' || !LineText[0])
			continue;

		parse(LineText, DataRead[0], charsmax(DataRead[]));

		strtok(LineText, Key, charsmax(Key), Value, charsmax(Value), '=');
		
		trim(Value);
		
		strtok(Value, DataRead[1], charsmax(DataRead[]), DataRead[2], charsmax(DataRead[]), '-');
	
		ArrayPushString(rankName, DataRead[0]);
		ArrayPushCell(rankFrags[1], str_to_num(DataRead[1]));
		ArrayPushCell(rankFrags[0], str_to_num(DataRead[2]));
	}

	if(ArraySize(rankName))
		log_amx("Zaladowano: %i rang(i) w zakresie (%i - %i).", ArraySize(rankName), ArrayGetCell(rankFrags[1], 0), ArrayGetCell(rankFrags[0], ArraySize(rankName) - 1));
}

public MainMenu(index)
{
	new MenuTitle[64], Item[64], TempRank[33];

	ArrayGetString(rankName, userRank[index], TempRank, charsmax(TempRank));

	formatex(MenuTitle, charsmax(MenuTitle), "Twoja ranga: %s (%i / %i)^nLista rang:", TempRank, userRank[index] + 1, ArraySize(rankName));
	
	new MenuIndex = menu_create(MenuTitle, "MainMenu_handler");

	ForRangeLess(i, 0, ArraySize(rankName))
	{
		ArrayGetString(rankName, i, TempRank, charsmax(TempRank));

		formatex(Item, charsmax(Item), "%s (Od: %i || Do: %i)", TempRank, ArrayGetCell(rankFrags[1], i), ArrayGetCell(rankFrags[0], i));

		menu_additem(MenuIndex, Item);
	}

	menu_display(index, MenuIndex);

	return PLUGIN_HANDLED;
}

public MainMenu_handler(index, menu, item)
{
	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}

/*public handleSayText(msgId, msgDest, msgEnt)
{
	new index = get_msg_arg_int(1);

	if(!is_user_connected(index))
		return PLUGIN_CONTINUE;

	new TempString[2][192], ChatPrefix[50];
	get_msg_arg_string(2, TempString[0], charsmax(TempString[]));

	ArrayGetString(rankName, userRank[index], ChatPrefix, charsmax(ChatPrefix));
	format(ChatPrefix, charsmax(ChatPrefix), "^x01[^x04%s^x01]", ChatPrefix);

	if(!equal(TempString[0], "#Cstrike_Chat_All"))
	{
		add(TempString[1], charsmax(TempString[]), "^x01");
		add(TempString[1], charsmax(TempString[]), ChatPrefix);
		add(TempString[1], charsmax(TempString[]), " ");
		add(TempString[1], charsmax(TempString[]), TempString[0]);
	}
	else
	{
		#if !defined GET_NAME_ONCE
		
		get_user_name(index, clientName, charsmax(clientName));

		#endif

		get_msg_arg_string(4, TempString[0], charsmax(TempString[]));
		set_msg_arg_string(4, "");

		add(TempString[1], charsmax(TempString[]), "^x01");
		add(TempString[1], charsmax(TempString[]), ChatPrefix);
		add(TempString[1], charsmax(TempString[]), "^x03 ");

		#if !defined GET_NAME_ONCE

		add(TempString[1], charsmax(TempString[]), clientName);

		#else

		add(TempString[1], charsmax(TempString[]), clientName[index]);

		#endif

		add(TempString[1], charsmax(TempString[]), "^x01 :  ");
		add(TempString[1], charsmax(TempString[]), TempString[0])
	}

	set_msg_arg_string(2, TempString[1]);

	return PLUGIN_CONTINUE;
}*/