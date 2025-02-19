#include <sourcemod>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

// Uncomment to enable debug logs
// #define DEBUG

public Plugin myinfo =
{
	name = "AI Navigation File Download Blocker",
	author = "Russianeer, caxanga334",
	description = "Blocks the server navigation files from being downloaded by the client.",
	version = "1.2.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2805645"
};

public void OnPluginStart()
{
	GameData gamedata = LoadGameConfigFile("ainavfile-blocker");

	if (gamedata == null)
	{
		SetFailState("Could't find ainfile-blocker.txt!");
	}

	DHookSetup hDetour = DHookCreateFromConf(gamedata, "OnResourcePrecachedFullPath");

	if (hDetour == null)
	{
		delete gamedata;
		SetFailState("Failed to setup OnResourcePrecachedFullPath detour!");
	}

	if (!DHookEnableDetour(hDetour, false, Detour_OnResourcePrecachedFullPath))
	{
		delete gamedata;
		SetFailState("Failed to enable OnResourcePrecachedFullPath detour!");
	}

	delete gamedata;
	LogMessage("Detour enable for OnResourcePrecachedFullPath.");
}

public MRESReturn Detour_OnResourcePrecachedFullPath(Handle hParams)
{
	char sFile[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 2, sFile, sizeof(sFile));

#if defined(DEBUG)
	LogMessage("Detour_OnResourcePrecachedFullPath: %s", sFile);
#endif

	int len = strlen(sFile);

	if(len > 3 && (strcmp(sFile[len-4], ".ain", false) == 0 || strcmp(sFile[len-4], ".nav", false) == 0))
	{
#if defined(DEBUG)
		LogMessage("Precache Blocked for \"%s\"!", sFile);
#endif
		return MRES_Supercede;
	}

	return MRES_Ignored;
}