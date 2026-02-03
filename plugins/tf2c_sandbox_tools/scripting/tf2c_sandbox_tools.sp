#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define TF2C_TEAM_SPEC 1

StringMap g_sandboxMaps = null;
bool g_bEnabled = false;

public Plugin myinfo =
{
	name = "[TF2C] Sandbox Tools",
	author = "caxanga334",
	description = "Provides sandbox utilities for players.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

enum struct PlayerData
{
	bool custom_spawn;
	float spawn_origin[3];

	void Reset()
	{
		this.custom_spawn = false;
	}
}

PlayerData g_plData[MAXPLAYERS + 1];

#include "sandbox_tools/functions.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (FindSendPropInfo("CTF2CUmbrella", "m_flBoostDelayTime") <= 0)
	{
		strcopy(error, err_max, "This plugin is for Team Fortress 2 Classified only!");
		return APLRes_SilentFailure;
	}

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/sandbox_maps.cfg");

	if (!FileExists(path))
	{
		strcopy(error, err_max, "Configuration file \"configs/sandbox_maps.cfg\" not found!");
		return APLRes_Failure;
	}

	if (late)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				OnClientPutInServer(client);
			}
		}
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_sandboxMaps = new StringMap();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/sandbox_maps.cfg");

	SMCParser parser = new SMCParser();
	parser.OnKeyValue = SandboxConfig_SMC_KeyValues;
	int line = 0;
	int col = 0;
	SMCError err = parser.ParseFile(path, line, col);

	if (err != SMCError_Okay)
	{
		SetFailState("Failed to parse config file!");
	}

	delete parser;

	RegAdminCmd("sm_sandboxmenu", Command_ShowSandboxMenu, 0, "Opens the sandbox menu");

	LoadTranslations("sandboxtools.phrases");
}

SMCResult SandboxConfig_SMC_KeyValues(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (!g_sandboxMaps.ContainsKey(key))
	{
		g_sandboxMaps.SetValue(key, 0);
	}

	return SMCParse_Continue;
}

Action Command_ShowSandboxMenu(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	if (!g_bEnabled && !CheckCommandAccess(client, "sm_sandboxtools_admin", ADMFLAG_CHEATS))
	{
		ReplyToCommand(client, "%t", "SandboxMenuNotAvailable");
		return Plugin_Handled;
	}

	SendSandboxMenu(client);

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	g_plData[client].Reset();
	SDKHook(client, SDKHook_SpawnPost, OnPlayerSpawnPost);
}

void OnPlayerSpawnPost(int entity)
{
	if (g_bEnabled && GetClientTeam(entity) > TF2C_TEAM_SPEC)
	{
		RequestFrame(Frame_PostPlayerSpawn, view_as<any>(GetClientSerial(entity)));
		CreateTimer(1.0, Timer_SendInfoMessage, view_as<any>(GetClientSerial(entity)), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Timer_SendInfoMessage(Handle timer, any data)
{
	int client = GetClientFromSerial(view_as<int>(data));

	if (client != 0)
	{
		PrintToChat(client, "%t", "SandboxMenuInfo");
	}
}

void Frame_PostPlayerSpawn(any data)
{
	int client = GetClientFromSerial(view_as<int>(data));

	if (client != 0)
	{
		Vscript_GiveInvul(client);
	}
}

public void OnMapStart()
{
	char map[256];
	char displayname[256];
	GetCurrentMap(map, sizeof(map));

	if (GetMapDisplayName(map, displayname, sizeof(displayname)))
	{
		strcopy(map, sizeof(map), displayname);
	}

	g_bEnabled = g_sandboxMaps.ContainsKey(map);
}