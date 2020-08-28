#include <sourcemod>
#include <multicolors>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

public Plugin myinfo = {
	name = "Gamers ala Pro Connect Announce",
	author = "caxanga334",
	description = "Announces player connections.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/"
}

public void OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisc, EventHookMode_Pre);
}

public void OnClientPostAdminCheck(int client) {
	AnnounceConnect(client)
}

public Action Event_PlayerDisc(Event event, const char[] name, bool dontBroadcast)
{
	char plname[MAX_NAME_LENGTH], auth[64], reason[256];
	
	event.GetString("name", plname, sizeof(plname), "");
	event.GetString("networkid", auth, sizeof(auth), "");
	event.GetString("reason", reason, sizeof(reason), "");
	
	if(!StrEqual(auth, "BOT", true))
	{
		PrintToChatAll("{snow}Player {green}%s{snow} ({green}%s{snow}) disconnected. Reason: %s ", plname, auth, reason);
		return Plugin_Continue;
	}
		
	return Plugin_Continue;
}

void AnnounceConnect(int client)
{
	if( IsFakeClient(client) )
		return;

	char playername[MAX_NAME_LENGTH], playerauth[64];
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthId(client, AuthId_Engine, playerauth, sizeof(playerauth));
		
	for(int i = 1;i <= MaxClients; i++)
	{
		if( IsValidClient(i) )
		{
			CPrintToChat(i,"{snow}Player {green}%s{snow} ({green}%s{snow}) connected.", playername, playerauth);
		}
	}
}

/**
 * Checks if the given client index is valid.
 *
 * @param client         The client index.  
 * @return              True if the client is valid
 *                      False if the client is invalid.
 */
stock bool IsValidClient(int client)
{
	if( client < 1 || client > MaxClients ) return false;
	if( !IsValidEntity(client) ) return false;
	if( !IsClientConnected(client) ) return false;
	return IsClientInGame(client);
}