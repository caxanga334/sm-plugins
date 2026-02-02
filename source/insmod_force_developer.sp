#include <sourcemod>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

#define STEAMIDTYPE_DEVELOPER 1

public Plugin myinfo =
{
	name = "[INSMOD] Force Developer",
	author = "caxanga334",
	description = "Forces every player to be marked as a developer in INSMOD.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

DynamicDetour g_detour = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (FindSendPropInfo("CINSCombineBall", "m_flRadius") <= 0)
	{
		strcopy(error, err_max, "This plugin is for Insurgency: Modern Infantry Combat only!");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData gamedata = LoadGameConfigFile("insmod_forcedev.games");

	if (gamedata == null)
	{
		SetFailState("Could not open insmod_forcedev.games.txt gamedata file!");
	}

	g_detour = DynamicDetour.FromConf(gamedata, "UTIL_FindSteamIDType");

	if (g_detour == null)
	{
		SetFailState("Could not setup \"UTIL_FindSteamIDType\" detour!");
	}

	if (!g_detour.Enable(Hook_Pre, Detour_FindSteamIDPre))
	{
		SetFailState("Failed to enable \"UTIL_FindSteamIDType\" detour!");
	}

	if (!g_detour.Enable(Hook_Post, Detour_FindSteamIDPost))
	{
		SetFailState("Failed to enable \"UTIL_FindSteamIDType\" detour!");
	}

	delete gamedata;
}

MRESReturn Detour_FindSteamIDPre(DHookReturn hReturn, DHookParam hParams)
{
	PrintToServer("Detour_FindSteamIDPre");
	hReturn.Value = STEAMIDTYPE_DEVELOPER;
	return MRES_Supercede;
}

MRESReturn Detour_FindSteamIDPost(DHookReturn hReturn, DHookParam hParams)
{
	PrintToServer("Detour_FindSteamIDPost");
	hReturn.Value = STEAMIDTYPE_DEVELOPER;
	return MRES_Supercede;
}