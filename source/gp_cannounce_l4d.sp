#include <sourcemod>
#include <geoip>
#include <caxanga334>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

public Plugin myinfo = {
	name = "[L4D] GP Connect Announce",
	author = "caxanga334",
	description = "Announces player connections.",
	version = "1.1.0",
	url = "https://github.com/caxanga334/"
}

public void OnPluginStart()
{
	LoadTranslations("gp_cannounce.phrases");
	HookEvent("player_disconnect", Event_PlayerDisc, EventHookMode_Pre);
}

public void OnClientPostAdminCheck(int client) {
	AnnounceConnect(client)
}

public void OnClientAuthorized(int client, const char[] auth) {
	char plrauth[64], plrname[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Engine, plrauth, sizeof(plrauth));
	GetClientName(client, plrname, sizeof(plrname));
	if ( !IsFakeClient(client) )
		PrintToChatAll("%t", "player_new", plrname, plrauth);
}

public Action Event_PlayerDisc(Event event, const char[] name, bool dontBroadcast)
{
	char plname[MAX_NAME_LENGTH], auth[64], reason[256];
	
	event.GetString("name", plname, sizeof(plname), "");
	event.GetString("networkid", auth, sizeof(auth), "");
	event.GetString("reason", reason, sizeof(reason), "");
	
	if(!StrEqual(auth, "BOT", true))
	{
		PrintToChatAll("%t", "player_disc", plname, auth, reason);
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

/**
public void OnClientDisconnect(int client) {

	char playerauth[64], playername[MAX_NAME_LENGTH];
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthId(client, AuthId_Engine, playerauth, sizeof(playerauth));

	if ( !IsFakeClient(client) )
		PrintToChatAll("Player %s(\x04%s\x01) disconnected.", playername, playerauth);
}
**/

void AnnounceConnect(int client)
{
	if( IsFakeClient(client) )
		return;

	char clientip[20], clientcountry[64], clientregion[64], clientcity[64], playername[MAX_NAME_LENGTH], playerauth[64];
	GetClientIP(client, clientip, sizeof(clientip));
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthId(client, AuthId_Engine, playerauth, sizeof(playerauth));
	GeoipCountry(clientip, clientcountry, sizeof(clientcountry));
	GeoipRegion(clientip, clientregion, sizeof(clientregion));
	GeoipCity(clientip, clientcity, sizeof(clientcity));
		
	for(int i = 1;i <= MaxClients; i++)
	{
		if( IsValidClient(i) )
		{
			if( CheckCommandAccess(i, "gpca_admin", ADMFLAG_BAN) )
			{
				PrintToChat(i,"%t", "player_full_admin", playername, playerauth, clientip, clientcountry, clientregion, clientcity);
			}
			else
			{
				PrintToChat(i,"%t", "player_full", playername, playerauth, clientcountry);
			}
		}
	}
}