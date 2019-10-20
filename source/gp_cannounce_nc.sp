#include <sourcemod>
#include <geoip>
#include <caxanga334>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===
// no color edition
public Plugin myinfo = {
	name = "Gamers ala Pro Connect Announce",
	author = "caxanga334",
	description = "Announces player connections.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/"
}

public void OnClientPostAdminCheck(int client) {
	AnnounceConnect(client)
}

public void OnClientDisconnect(int client) {

	char playerauth[64], playername[MAX_NAME_LENGTH];
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthId(client, AuthId_Engine, playerauth, sizeof(playerauth));

	if ( !IsFakeClient(client) )
		PrintToChatAll("Player %s(%s) disconnected.", playername, playerauth);
}

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
				PrintToChat(i,"Player %s (%s | %s) connected from %s, %s, %s", playername, playerauth, clientip, clientcountry, clientregion, clientcity);
			}
			else
			{
				PrintToChat(i,"Player %s (%s) connected from %s", playername, playerauth, clientcountry);
			}
		}
	}
}