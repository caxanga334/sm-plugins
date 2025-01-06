#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#include <stocksoup/memory>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

DynamicHook g_mytouch;
DynamicHook g_isbot;
bool g_touchbypass[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[TF2] Fix MvM Currency for RED Bots",
	author = "caxanga334",
	description = "Allow RED bots to collect currency in the Mann vs Machine gamemode.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This plugin is for Team Fortress 2 only!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData gd = new GameData("tf_bots_mvm_currency.games");

	if (gd == null)
	{
		SetFailState("Failed to open \"tf_bots_mvm_currency.games.txt\"!");
	}

	g_mytouch = DynamicHook.FromConf(gd, "CCurrencyPack::MyTouch");
	g_isbot = DynamicHook.FromConf(gd, "CBasePlayer::IsBot");

	delete gd;

	bool fail = false;

	if (g_mytouch == null)
	{
		LogError("Failed to setup dynamic hooks for CCurrencyPack::MyTouch");
		fail = true;
	}

	if (g_isbot == null)
	{
		LogError("Failed to setup dynamic hooks for CBasePlayer::IsBot");
		fail = true;
	}

	if (fail)
	{
		SetFailState("Dynamic hook setup failed!");
	}

	LogMessage("Dynamic hooks for CCurrencyPack::MyTouch and CBasePlayer::IsBot are ok!");
}

public void OnMapStart()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		g_touchbypass[i] = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "item_currencypack", 17) == 0)
	{
		g_mytouch.HookEntity(Hook_Pre, entity, Hook_MyTouch_Pre);
		g_mytouch.HookEntity(Hook_Post, entity, Hook_MyTouch_Post);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		g_isbot.HookEntity(Hook_Pre, client, Hook_IsBot_Pre);
		g_isbot.HookEntity(Hook_Post, client, Hook_IsBot_Post);
	}
}

MRESReturn Hook_MyTouch_Pre(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	Address pPlayer = DHookGetParamAddress(hParams, 1);
	int player = GetEntityFromAddress(pPlayer);

	if (IsValidEntity(player) && IsFakeClient(player) && TF2_GetClientTeam(player) == TFTeam_Red)
	{
		g_touchbypass[player] = true;
	}

	return MRES_Ignored;
}

MRESReturn Hook_MyTouch_Post(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	Address pPlayer = DHookGetParamAddress(hParams, 1);
	int player = GetEntityFromAddress(pPlayer);

	if (IsValidEntity(player) && g_touchbypass[player])
	{
		g_touchbypass[player] = false;
	}

	return MRES_Ignored;
}

MRESReturn Hook_IsBot_Pre(Address pThis, DHookReturn hReturn)
{
	int player = GetEntityFromAddress(pThis);

	if (IsValidEntity(player) && g_touchbypass[player])
	{
		DHookSetReturn(hReturn, view_as<any>(false));
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn Hook_IsBot_Post(Address pThis, DHookReturn hReturn)
{
	int player = GetEntityFromAddress(pThis);

	if (IsValidEntity(player) && g_touchbypass[player])
	{
		DHookSetReturn(hReturn, view_as<any>(false));
		return MRES_Override;
	}

	return MRES_Ignored;
}