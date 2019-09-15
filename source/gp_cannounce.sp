#include <sourcemod>
#include <geoip>
#include <caxanga334>
#include <morecolors>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

public Plugin myinfo = {
	name = "Gamers ala Pro Connect Announce",
	author = "caxanga334",
	description = "Announces player connections.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/"
}

public void OnClientPutInServer(int client) {

	char clientip[20], clientcountry[64], playername[MAX_NAME_LENGTH], playerauth[64];
	GetClientIP(client, clientip, sizeof(clientip));
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthId(client, AuthId_Engine, playerauth, sizeof(playerauth));
	GeoipCountry(clientip, clientcountry, sizeof(clientcountry));

	CPrintToChatAll("{snow}Player %s ({green}%s{snow}) connected from {green}%s", playername, playerauth, clientcountry); 
}

public void OnClientDisconnect(int client) {

	char playerauth[64], playername[MAX_NAME_LENGTH];
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthId(client, AuthId_Engine, playerauth, sizeof(playerauth));

	CPrintToChatAll("{snow}Player %s ({green}%s{snow}) disconnected.", playername, playerauth);
}