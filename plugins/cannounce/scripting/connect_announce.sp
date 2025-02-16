#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Connect Announce",
	author = "caxanga334",
	description = "Announces player connects and disconnects.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

// globals

ConVar cvar_disconnect_mode = null;
ConVar cvar_announce_prejoin = null;
bool g_bInGame[MAXPLAYERS + 1];


public void OnPluginStart()
{
	cvar_disconnect_mode = CreateConVar("sm_cannounce_disconnect_mode", "0", "Player disconnect detection mode\n0 - OnClientDisconnect\n1 - Game Event", FCVAR_NONE);
	cvar_announce_prejoin = CreateConVar("sm_cannounce_prejoin", "0", "Announce when players are connecting to the server?", FCVAR_NONE);

	AutoExecConfig();

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	LoadTranslations("cannounce.phrases");
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client)) { return; }

	if (cvar_announce_prejoin.BoolValue && !g_bInGame[client])
	{
		char name[128];
		GetClientName(client, name, sizeof(name));

		PrintToChatAll("[SM] %t", "ClientPreConnect", name, auth);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client)) { return; }

	g_bInGame[client] = true;

	char authid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_Engine, authid, sizeof(authid)))
	{
		strcopy(authid, sizeof(authid), "STEAM_ID_UNAUTHENTICATED");
	}

	char name[128];
	GetClientName(client, name, sizeof(name));

	PrintToChatAll("[SM] %t", "ClientJoined", name, authid);
}

public void OnClientDisconnect(int client)
{
	g_bInGame[client] = false;

	if (IsFakeClient(client)) { return; }

	if (cvar_disconnect_mode.IntValue != 0) { return; }

	char authid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_Engine, authid, sizeof(authid)))
	{
		strcopy(authid, sizeof(authid), "STEAM_ID_UNAUTHENTICATED");
	}

	char name[128];
	GetClientName(client, name, sizeof(name));

	PrintToChatAll("[SM] %t", "ClientDisconnectSimple", name, authid);
}

Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (cvar_disconnect_mode.IntValue != 1) { return Plugin_Continue; }

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0) { return Plugin_Continue; }

	char authid[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_Engine, authid, sizeof(authid)))
	{
		strcopy(authid, sizeof(authid), "STEAM_ID_UNAUTHENTICATED");
	}

	char Clientname[128];
	char reason[512];

	GetClientName(client, Clientname, sizeof(Clientname));
	event.GetString("reason", reason, sizeof(reason));

	PrintToChatAll("[SM] %t", "ClientDisconnectWithReason", Clientname, authid, reason);

	return Plugin_Continue;
}