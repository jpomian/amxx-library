#include <amxmodx>
#include <nvault>
 
#define AUTHOR "Alelluja | aSior - amxx.pl/user/60210-asiorr/"
 
#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)
#define ForArray(%1,%2) for(new %1 = 0; %1 < sizeof %2; %1++)
 
new const statTrakMenuCommands[][] =
{
    "/stattrak",
    "/st",
    "/bronie"
};
 
new const weaponsData[][] =
{
	"NOZ",
    "AK47",
    "M4A1",
    "AWP",
    "MP5",
    "FAMAS",
    "AUG",
    "MAC10",
    "SG550",
    "UMP45",
    "GALIL",
    "P90",
    "TMP",
    "M249",
    "XM1014",
    "M3",
    "SCOUT",
    "AWP",
    "G3SG1 (autokampa)",
    "SG552 (autokampa)",
    "USP",
    "GLOCK18",
    "DEAGLE",
    "ELITE",
    "P228",
    "FIVESEVEN"
};
 
new const weaponIndexes[] =
{
	CSW_KNIFE,
    CSW_AK47,
    CSW_M4A1,
    CSW_AWP,
    CSW_MP5NAVY,
    CSW_FAMAS,
    CSW_AUG,
    CSW_MAC10,
    CSW_SG550,
    CSW_UMP45,
    CSW_GALI,
    CSW_TMP,
    CSW_P90,
    CSW_M249,
    CSW_XM1014,
    CSW_M3,
    CSW_SCOUT,
    CSW_AWP,
    CSW_G3SG1,
    CSW_SG552,
    CSW_USP,
    CSW_GLOCK18,
    CSW_DEAGLE,
    CSW_ELITE,
    CSW_P228,
    CSW_FIVESEVEN,

};
 
 
new userStatTrak[33][33],
    vaultFile;
 
public plugin_init()
{
    register_plugin("Stattrak CSGO", "v0.1", AUTHOR);
   
    registerCommands(statTrakMenuCommands, charsmax(statTrakMenuCommands), "statTrakMenu");
 
    register_event("DeathMsg", "playerDeathEvent", "a");
 
    vaultFile = nvault_open("statTrak");
}
 
public playerDeathEvent()
{
    new killer = read_data(1),
        victim = read_data(2),
        weaponName[33],
        weaponIndex;
 
    if(killer == victim || !is_user_connected(killer) || !is_user_connected(victim))
    {
        return;
    }
 
    read_data(4, weaponName, charsmax(weaponName));
 
    format(weaponName, charsmax(weaponName), "weapon_%s", weaponName);
 
    weaponIndex = get_weaponid(weaponName);
 
    if(!weaponIndex || !inArray(weaponIndex, weaponIndexes, sizeof(weaponIndexes)))
    {
        return;
    }
 
    userStatTrak[killer][weaponIndex]++;
    saveData(killer)
}
 
public statTrakMenu(index)
{
    new menuIndex = menu_create("Zabicia z danej broni:", "statTrakMenu_handler"),
        item[64],
        menuCallback = menu_makecallback("blockOptions");
 
    ForArray(i, weaponsData)
    {
        formatex(item, charsmax(item), "\y%s \w--> Zabojstwa: \r%i", weaponsData[i], userStatTrak[index][weaponIndexes[i]]);
       
        menu_additem(menuIndex, item, _, _, menuCallback);
    }
 
    menu_display(index, menuIndex);
 
    return PLUGIN_HANDLED;
}
 
public statTrakMenu_handler(id, menu, item)
{
    menu_destroy(menu);
   
    if(item == MENU_EXIT)
    {
        return PLUGIN_HANDLED;
    }
 
    return PLUGIN_HANDLED;
}
 
public blockOptions(index, menu, item)
{
    return ITEM_DISABLED;
}
 
public client_putinserver(index)
{
    readData(index);
}

saveData(index)
{
    new userName[33],
        vaultKey[33],
        vaultData[33];
 
    get_user_name(index, userName, charsmax(userName));
 
    formatex(vaultKey, charsmax(vaultKey), "%s-statTrak", userName);
   
    ForArray(i, weaponIndexes)
    {
        format(vaultData, charsmax(vaultData), "%s%i#", vaultData, userStatTrak[index][weaponIndexes[i]]);
    }
 
    nvault_set(vaultFile, vaultKey, vaultData);
}
 
readData(index)
{
    new userName[33],
        vaultKey[33],
        vaultData[33],
        intValues[30][30];
 
    get_user_name(index, userName, charsmax(userName));
 
    formatex(vaultKey, charsmax(vaultKey), "%s-statTrak", userName);
 
    nvault_get(vaultFile, vaultKey, vaultData, charsmax(vaultData));
 
    explode(vaultData, '#', intValues, charsmax(intValues), sizeof(weaponIndexes))
 
    ForArray(i, weaponIndexes)
    {
        userStatTrak[index][weaponIndexes[i]] = str_to_num(intValues[i]);
    }
}

inArray(value, const array[], arraySize)
{
    ForRange(i, 0, arraySize)
    {
        if(array[i] == value)
        {
            return true;
        }
    }
 
    return false;
}
 
stock explode(const string[],const character,output[][],const maxs,const maxlen)
{
    new iDo = 0,
        len = strlen(string),
        oLen = 0;
 
    do
    {
        oLen += (1+copyc(output[iDo++],maxlen,string[oLen],character))
    }
    while(oLen < len && iDo < maxs)
}
 
stock registerCommands(const array[][], arraySize, function[])
{
	#if !defined ForRange

		#define ForRange(%1,%2,%3) for(new %1 = %2; %1 <= %3; %1++)

	#endif

	#if AMXX_VERSION_NUM >= 183 
	
	ForRange(i, 0, arraySize - 1)
	{
		ForRange(j, 0, 1)
		{
			register_clcmd(fmt("%s %s", !j ? "say" : "say_team", array[i]), function);
		}
	}

	#else

	new newCommand[33];

	ForRange(i, 0, arraySize - 1)
	{
		ForRange(j, 0, 1)
		{
			formatex(newCommand, charsmax(newCommand), "%s %s", !j ? "say" : "say_team", array[i]);
			register_clcmd(newCommand, function);
		}
	}

	#endif
}