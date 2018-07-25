// Super Tanks++: Item Ability
#pragma semicolon 1
#pragma newdecls required
#include <super_tanks++>

public Plugin myinfo =
{
	name = "[ST++] Item Ability",
	author = ST_AUTHOR,
	description = ST_DESCRIPTION,
	version = ST_VERSION,
	url = ST_URL
};

bool g_bTankConfig[ST_MAXTYPES + 1];
char g_sItemLoadout[ST_MAXTYPES + 1][325];
char g_sItemLoadout2[ST_MAXTYPES + 1][325];
int g_iItemAbility[ST_MAXTYPES + 1];
int g_iItemAbility2[ST_MAXTYPES + 1];
int g_iItemChance[ST_MAXTYPES + 1];
int g_iItemChance2[ST_MAXTYPES + 1];
int g_iItemMode[ST_MAXTYPES + 1];
int g_iItemMode2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[ST++] Item Ability only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("super_tanks++"))
	{
		SetFailState("No Super Tanks++ library found.");
	}
}

public void OnConfigsExecuted()
{
	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	if (IsMapValid(sMapName))
	{
		vIsPluginAllowed();
	}
}

void vIsPluginAllowed()
{
	ST_PluginEnabled() ? vHookEvent(true) : vHookEvent(false);
}

void vHookEvent(bool hook)
{
	static bool hooked;
	if (hook && !hooked)
	{
		HookEvent("player_death", eEventPlayerDeath);
		hooked = true;
	}
	else if (!hook && hooked)
	{
		UnhookEvent("player_death", eEventPlayerDeath);
		hooked = false;
	}
}

public Action eEventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iUserId = event.GetInt("userid");
	int iPlayer = GetClientOfUserId(iUserId);
	int iItemAbility = !g_bTankConfig[ST_TankType(iPlayer)] ? g_iItemAbility[ST_TankType(iPlayer)] : g_iItemAbility2[ST_TankType(iPlayer)];
	int iItemChance = !g_bTankConfig[ST_TankType(iPlayer)] ? g_iItemChance[ST_TankType(iPlayer)] : g_iItemChance2[ST_TankType(iPlayer)];
	int iItemMode = !g_bTankConfig[ST_TankType(iPlayer)] ? g_iItemMode[ST_TankType(iPlayer)] : g_iItemMode2[ST_TankType(iPlayer)];
	if (iItemAbility == 1 && GetRandomInt(1, iItemChance) == 1 && bIsTank(iPlayer))
	{
		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				switch (iItemMode)
				{
					case 0:
					{
						char sItems[5][64];
						char sItemLoadout[325];
						sItemLoadout = !g_bTankConfig[ST_TankType(iPlayer)] ? g_sItemLoadout[ST_TankType(iPlayer)] : g_sItemLoadout2[ST_TankType(iPlayer)];
						TrimString(sItemLoadout);
						ExplodeString(sItemLoadout, ",", sItems, sizeof(sItems), sizeof(sItems[]));
						switch (GetRandomInt(1, 5))
						{
							case 1: vCheatCommand(iSurvivor, "give", sItems[0]);
							case 2: vCheatCommand(iSurvivor, "give", sItems[1]);
							case 3: vCheatCommand(iSurvivor, "give", sItems[2]);
							case 4: vCheatCommand(iSurvivor, "give", sItems[3]);
							case 5: vCheatCommand(iSurvivor, "give", sItems[4]);
						}
					}
					case 1:
					{
						char sItemLoadout[325];
						sItemLoadout = !g_bTankConfig[ST_TankType(iPlayer)] ? g_sItemLoadout[ST_TankType(iPlayer)] : g_sItemLoadout2[ST_TankType(iPlayer)];
						TrimString(sItemLoadout);
						char sItems[5][64];
						ExplodeString(sItemLoadout, ",", sItems, sizeof(sItems), sizeof(sItems[]));
						for (int iItem = 0; iItem < sizeof(sItems); iItem++)
						{
							if (StrContains(sItemLoadout, sItems[iItem]) != -1 && sItems[iItem][0] != '\0')
							{
								vCheatCommand(iSurvivor, "give", sItems[iItem]);
							}
						}
					}
				}
			}
		}
	}
}

public void ST_Configs(char[] savepath, int limit, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);
	for (int iIndex = 1; iIndex <= limit; iIndex++)
	{
		char sName[MAX_NAME_LENGTH + 1];
		Format(sName, sizeof(sName), "Tank %d", iIndex);
		if (kvSuperTanks.JumpToKey(sName))
		{
			main ? (g_bTankConfig[iIndex] = false) : (g_bTankConfig[iIndex] = true);
			main ? (g_iItemAbility[iIndex] = kvSuperTanks.GetNum("Item Ability/Ability Enabled", 0)) : (g_iItemAbility2[iIndex] = kvSuperTanks.GetNum("Item Ability/Ability Enabled", g_iItemAbility[iIndex]));
			main ? (g_iItemAbility[iIndex] = iSetCellLimit(g_iItemAbility[iIndex], 0, 1)) : (g_iItemAbility2[iIndex] = iSetCellLimit(g_iItemAbility2[iIndex], 0, 1));
			main ? (g_iItemChance[iIndex] = kvSuperTanks.GetNum("Item Ability/Item Chance", 4)) : (g_iItemChance2[iIndex] = kvSuperTanks.GetNum("Item Ability/Item Chance", g_iItemChance[iIndex]));
			main ? (g_iItemChance[iIndex] = iSetCellLimit(g_iItemChance[iIndex], 1, 9999999999)) : (g_iItemChance2[iIndex] = iSetCellLimit(g_iItemChance2[iIndex], 1, 9999999999));
			main ? (kvSuperTanks.GetString("Item Ability/Item Loadout", g_sItemLoadout[iIndex], sizeof(g_sItemLoadout[]), "rifle,pistol,first_aid_kit,pain_pills")) : (kvSuperTanks.GetString("Item Ability/Item Loadout", g_sItemLoadout2[iIndex], sizeof(g_sItemLoadout2[]), g_sItemLoadout[iIndex]));
			main ? (g_iItemMode[iIndex] = kvSuperTanks.GetNum("Item Ability/Item Mode", 0)) : (g_iItemMode2[iIndex] = kvSuperTanks.GetNum("Item Ability/Item Mode", g_iItemMode[iIndex]));
			main ? (g_iItemMode[iIndex] = iSetCellLimit(g_iItemMode[iIndex], 0, 1)) : (g_iItemMode2[iIndex] = iSetCellLimit(g_iItemMode2[iIndex], 0, 1));
			kvSuperTanks.Rewind();
		}
	}
	delete kvSuperTanks;
}

void vCheatCommand(int client, char[] command, char[] arguments = "", any ...)
{
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, iCmdFlags|FCVAR_CHEAT);
}