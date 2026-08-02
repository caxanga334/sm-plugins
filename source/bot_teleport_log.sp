#include <sourcemod>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Log Bot Teleports",
	author = "caxanga334",
	description = "Logs every time a bot/fakeclient is teleported via CBaseEntity::Teleport",
	version = "1.0.0",
	url = "https://github.com/caxanga334"
};

DynamicHook g_TeleportHook = null;
DynamicDetour g_SetAbsOriginDetour = null;
char g_logfile[PLATFORM_MAX_PATH];
ConVar cvar_min_distance = null;
float g_MinDist;

public void OnPluginStart()
{
	GameData gd = new GameData("sdktools.games");

	if (gd == null)
	{
		SetFailState("Failed to load SDKTools gamedata!");
		return;
	}

	int offset = gd.GetOffset("Teleport");
	delete gd;

	if (offset <= 0)
	{
		SetFailState("Teleport offset not available for the current game!");
		return;
	}

	g_TeleportHook = new DynamicHook(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	
	if (g_TeleportHook == null)
	{
		SetFailState("Failed to create dynamic hook!");
		return;
	}

	g_TeleportHook.AddParam(HookParamType_VectorPtr); // position
	g_TeleportHook.AddParam(HookParamType_VectorPtr); // angles
	g_TeleportHook.AddParam(HookParamType_VectorPtr); // velocity

	ReadPluginGamedata();

	cvar_min_distance = CreateConVar("sm_bot_teleport_logger_min_dist", "128.0", "Minimum distance between bot current position and destination to consider logging.");
	cvar_min_distance.AddChangeHook(OnMinDistChanged);
	AutoExecConfig();
}

void ReadPluginGamedata()
{
	GameData gd = new GameData("bot_teleport_log.games");

	if (gd == null)
	{
		SetFailState("Failed to open bot_teleport_log.games.txt gamedata file!");
	}

	Address func = gd.GetMemSig("CBaseEntity::SetAbsOrigin");

	if (func != Address_Null)
	{
		g_SetAbsOriginDetour = DynamicDetour.FromConf(gd, "CBaseEntity::SetAbsOrigin");

		if (g_SetAbsOriginDetour == null)
		{
			LogError("Failed to setup CBaseEntity::SetAbsOrigin detour!");
		}

		g_SetAbsOriginDetour.Enable(Hook_Pre, OnSetAbsOriginPre);
		g_SetAbsOriginDetour.Enable(Hook_Post, OnSetAbsOriginPost);
		LogMessage("CBaseEntity::SetAbsOrigin detour enabled!");
	}
	else
	{
		LogMessage("No signature for CBaseEntity::SetAbsOrigin available, not setting up detour.");
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		g_TeleportHook.HookEntity(Hook_Pre, client, OnTeleportPre);
		g_TeleportHook.HookEntity(Hook_Post, client, OnTeleportPost);
	}
}

public void OnMapStart()
{
	char timestamp[64];
	FormatTime(timestamp, sizeof(timestamp), "%Y%m%d");
	char map[128];
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));

	BuildPath(Path_SM, g_logfile, sizeof(g_logfile), "logs/bot_teleports_%s_%s.log", map, timestamp);
}

public void OnConfigsExecuted()
{
	g_MinDist = cvar_min_distance.FloatValue;
}

void OnMinDistChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_MinDist = convar.FloatValue;
}

bool IsPlayerEntity(int entity)
{
	return entity > 0 && entity <= MaxClients;
}

MRESReturn OnTeleportPre(int pThis, DHookParam hParams)
{
	// If the position vector is NULL, don't care about logging.
	if (hParams.IsNull(1))
	{
		return MRES_Ignored;
	}

	float origin[3];
	float dest[3];
	GetClientAbsOrigin(pThis, origin);
	hParams.GetVector(1, dest);

	// ignore short distance teleports.
	if (GetVectorDistance(origin, dest) < g_MinDist)
	{
		return MRES_Ignored;
	}


	LogToFile(g_logfile, "[PRE] Bot \"%L\" teleported (CBaseEntity::Teleport) from <%f %f %f> to <%f %f %f>", pThis, origin[0], origin[1], origin[2], dest[0], dest[1], dest[2]);
	return MRES_Ignored;
}

MRESReturn OnTeleportPost(int pThis, DHookParam hParams)
{
	return MRES_Ignored;
}

MRESReturn OnSetAbsOriginPre(int pThis, DHookParam hParams)
{
	// this is a CBaseEntity function
	// null checks shouldn't be needed here since the vector is byref and not a pointer

	if (IsPlayerEntity(pThis))
	{
		if (IsFakeClient(pThis))
		{
			float origin[3];
			float dest[3];
			GetClientAbsOrigin(pThis, origin);
			hParams.GetVector(1, dest);

			// ignore short distance SetAbsOrigin calls.
			if (GetVectorDistance(origin, dest) < g_MinDist)
			{
				return MRES_Ignored;
			}

			LogToFile(g_logfile, "[PRE] Bot \"%L\" teleported (CBaseEntity::SetAbsOrigin) from <%f %f %f> to <%f %f %f>", pThis, origin[0], origin[1], origin[2], dest[0], dest[1], dest[2]);
		}
	}

	return MRES_Ignored;
}

MRESReturn OnSetAbsOriginPost(int pThis, DHookParam hParams)
{
	return MRES_Ignored;
}