#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.3.0"

DynamicHook g_mytouch;
DynamicHook g_isbot;
DynamicHook g_eventkilled;
DynamicHook g_builderattack;
bool g_fakeIsBot[MAXPLAYERS + 1]; // when true, IsBot will always return false
bool g_bEnabled;

//--------------------------------------------------------------------------
// Builder "weapon" states
//--------------------------------------------------------------------------
enum 
{
	BS_IDLE = 0,
	BS_SELECTING,
	BS_PLACING,
	BS_PLACING_INVALID

	//
	// ADD NEW ITEMS HERE TO AVOID BREAKING DEMOS
	//
};

public Plugin myinfo =
{
	name = "[TF2] MvM RED Bot Fixes",
	author = "caxanga334",
	description = "Some fixes for MvM for better RED bot support.",
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
	GameData gd = new GameData("tf_bots_mvm_fixes.games");

	if (gd == null)
	{
		SetFailState("Failed to open \"tf_bots_mvm_fixes.games.txt\"!");
	}

	g_mytouch = DynamicHook.FromConf(gd, "CCurrencyPack::MyTouch");
	g_isbot = DynamicHook.FromConf(gd, "CBasePlayer::IsBot");
	g_eventkilled = DynamicHook.FromConf(gd, "CTFPlayer::Event_Killed");
	g_builderattack = DynamicHook.FromConf(gd, "CTFWeaponBuilder::PrimaryAttack");

	delete gd;

	bool fail = false;

	// check one by one so it logs every failure at once

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

	if (g_eventkilled == null)
	{
		LogError("Failed to setup dynamic hooks for CTFPlayer::Event_Killed");
		fail = true;
	}

	if (fail)
	{
		SetFailState("Dynamic hook setup failed!");
	}

	LogMessage("Plugin gamedata is ok!");
	g_bEnabled = false;

	CreateConVar("sm_mvm_bots_fixes_version", PLUGIN_VERSION, "MvM RED bot fixes plugin version.", FCVAR_NOTIFY);
}

public void OnMapStart()
{
	g_bEnabled = IsMvM(true);

	if (!g_bEnabled)
	{
		LogMessage("Plugin will be disabled. Reason: Current map is not a Mann vs Machine map!");
	}

	for (int i = 0; i <= MaxClients; i++)
	{
		g_fakeIsBot[i] = false;
	}

	// Compatibility with NavBot (https://github.com/caxanga334/NavBot)
	// Tell them that currency collection is possible
	ConVar navbot_collect_currency = FindConVar("sm_navbot_tf_mvm_collect_currency");

	if (navbot_collect_currency != null)
	{
		if (navbot_collect_currency.BoolValue == false)
		{
			LogMessage("[NavBot Compatibility] Setting convar to enable bots to collect currency.");
		}

		navbot_collect_currency.BoolValue = true;
	}

	ConVar navbot_spy_sap_robots = FindConVar("sm_navbot_tf_spy_can_sap_robots");

	if (navbot_spy_sap_robots != null)
	{
		if (navbot_spy_sap_robots.BoolValue == false)
		{
			LogMessage("[NavBot Compatibility] Setting convar to enable bots to sap robots.");
		}

		navbot_spy_sap_robots.BoolValue = true;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bEnabled)
	{
		return;
	}

	if (strncmp(classname, "item_currencypack", 17) == 0)
	{
		g_mytouch.HookEntity(Hook_Pre, entity, Hook_MyTouch_Pre);
		g_mytouch.HookEntity(Hook_Post, entity, Hook_MyTouch_Post);
	}
	else if (strncmp(classname, "tf_weapon_builder", 17) == 0)
	{
		g_builderattack.HookEntity(Hook_Pre, entity, Hook_CTFWeaponBuilder_PrimaryAttack_Pre);
		g_builderattack.HookEntity(Hook_Post, entity, Hook_CTFWeaponBuilder_PrimaryAttack_Post);
	}
}

public void OnClientPutInServer(int client)
{
	if (!g_bEnabled)
	{
		return;
	}

	if (IsFakeClient(client))
	{
		g_isbot.HookEntity(Hook_Pre, client, Hook_IsBot_Pre);
		g_isbot.HookEntity(Hook_Post, client, Hook_IsBot_Post);
		g_eventkilled.HookEntity(Hook_Pre, client, Hook_CTFPlayer_Event_Killed_Pre);
		g_eventkilled.HookEntity(Hook_Post, client, Hook_CTFPlayer_Event_Killed_Post);
	}
}

MRESReturn Hook_MyTouch_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	int player = DHookGetParam(hParams, 1);

	if (IsValidEntity(player) && IsEntityAClient(player) && IsFakeClient(player) && TF2_GetClientTeam(player) == TFTeam_Red)
	{
		// PrintToServer("[PRE] Currency Pack touched by bot %i", player);
		g_fakeIsBot[player] = true;
	}

	return MRES_Ignored;
}

MRESReturn Hook_MyTouch_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	int player = DHookGetParam(hParams, 1);

	if (IsValidEntity(player) && g_fakeIsBot[player])
	{
		// PrintToServer("[POST] Currency Pack touched by bot %i", player);
		g_fakeIsBot[player] = false;
	}

	return MRES_Ignored;
}

MRESReturn Hook_IsBot_Pre(int pThis, DHookReturn hReturn)
{
	if (IsValidEntity(pThis) && g_fakeIsBot[pThis])
	{
		DHookSetReturn(hReturn, view_as<any>(false));
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn Hook_IsBot_Post(int pThis, DHookReturn hReturn)
{
	if (IsValidEntity(pThis) && g_fakeIsBot[pThis])
	{
		DHookSetReturn(hReturn, view_as<any>(false));
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn Hook_CTFPlayer_Event_Killed_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	// this check might be not needed
	if (IsValidEntity(pThis))
	{
		if (TF2_GetClientTeam(pThis) == TFTeam_Red)
		{
			g_fakeIsBot[pThis] = true; // lie about being a bot
		}
	}

	return MRES_Ignored;
}

MRESReturn Hook_CTFPlayer_Event_Killed_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	// this check might be not needed
	if (IsValidEntity(pThis))
	{
		// don't bother with team checks here it doesn't matter
		g_fakeIsBot[pThis] = false; // lie about being a bot
	}

	return MRES_Ignored;
}

MRESReturn Hook_CTFWeaponBuilder_PrimaryAttack_Pre(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
	int state = GetEntProp(pThis, Prop_Send, "m_iBuildState");

	// PrintToServer("Hook_CTFWeaponBuilder_PrimaryAttack_Pre %i %i %i", pThis, owner, state);

	if (IsValidEntity(owner) && state == BS_PLACING && IsFakeClient(owner) && TF2_GetClientTeam(owner) == TFTeam_Red)
	{
		g_fakeIsBot[owner] = true;
	}

	return MRES_Ignored;
}

MRESReturn Hook_CTFWeaponBuilder_PrimaryAttack_Post(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
	int state = GetEntProp(pThis, Prop_Send, "m_iBuildState");

	if (IsValidEntity(owner) && state == BS_PLACING && IsFakeClient(owner) && TF2_GetClientTeam(owner) == TFTeam_Red)
	{
		g_fakeIsBot[owner] = false;
	}

	return MRES_Ignored;
}

// IsMvM code by FlaminSarge
bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

bool IsEntityAClient(int entity)
{
	if (entity > 0 && entity <= MaxClients)
	{
		return true;
	}

	return false;
}