#include <sourcemod>
#include "include/discord.inc"
#pragma newdecls required
#pragma semicolon 1

// === DEFINES ===
#define PLUGIN_VERSION "1.0.0"
#define STATUS_MSG "{\"username\":\"{BOTNAME}\", \"content\":\"\", \"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"Server: {NICKNAME}\",\"fields\": [{\"title\": \"Player Count\",\"value\": \"{NUMPLAYERS}/{MAXSLOTS} players\",\"short\": false}]}]}"

// === GLOBAL VARIABLES ===

int g_iLastPlayers; // How many players were in the server the last time we announced it

// timers
float g_flLastMessageTime;

// cvars
ConVar g_cServerNick = null;
ConVar g_cBotName = null;
ConVar g_cColor = null;
ConVar g_cWebhook = null;
ConVar g_cMaxPlayers = null;
ConVar g_cMessageCooldown = null;
ConVar g_cMinPlayers = null;

// === PLUGIN INFO ===

public Plugin myinfo = {
	name = "[ANY] Discord Server Status",
	author = "caxanga334",
	description = "Sends discord messages with the server status.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
}

public void OnPluginStart()
{
	CreateConVar("sm_discord_serverstatus_version", PLUGIN_VERSION, "Discord server status plugin version", FCVAR_NOTIFY);
	g_cServerNick = CreateConVar("discord_serverstatus_nickname", "", "Server nickname.");
	g_cBotName = CreateConVar("discord_serverstatus_botname", "", "Discord botname, leave this blank to use the webhook default name.");
	g_cColor = CreateConVar("discord_serverstatus_color", "#0247fe", "Discord/Slack attachment color used for reports.");
	g_cWebhook = CreateConVar("discord_serverstatus_webhook", "serverstatus", "Config key from configs/discord.cfg.");
	g_cMaxPlayers = CreateConVar("discord_serverstatus_maxplayers", "32", "The maximum amount of players that can join the server.");
	g_cMessageCooldown = CreateConVar("discord_serverstatus_cooldown", "90", "Delay between server status messages.", FCVAR_NONE, true, 60.0);
	g_cMinPlayers = CreateConVar("discord_serverstatus_minplayers", "2", "Minimum amount of players on the server to send message.", FCVAR_NONE, true, 0.0, true, 32.0);
	
	RegAdminCmd("sm_serverstatus_force", cmd_serverstatusforce, ADMFLAG_ROOT, "Force a server status message to be sent.");
	
	AutoExecConfig(true, "discord_serverstatus");
}

public void OnMapStart()
{
	g_iLastPlayers = 0;
	g_flLastMessageTime = GetGameTime() + 20.0;
}

public void OnClientPutInServer(int client)
{
	if(g_flLastMessageTime < GetGameTime() && !IsFakeClient(client))
	{
		RequestFrame(FrameSendPlrCountMsg);
		g_flLastMessageTime = GetGameTime() + g_cMessageCooldown.FloatValue;
	}
}

public void OnClientDisconnect(int client)
{
	if(g_flLastMessageTime < GetGameTime() && !IsFakeClient(client))
	{
		RequestFrame(FrameSendPlrCountMsg);
		g_flLastMessageTime = GetGameTime() + g_cMessageCooldown.FloatValue;
	}	
}

public Action cmd_serverstatusforce(int client, int args)
{
	if(GetNumPlayersInGame() > 0)
	{
		ReplyToCommand(client, "Sending update to discord.");
		PlayerCountMessage();
	}
	else
	{
		ReplyToCommand(client, "Error: Server is empty.");
	}
	
	return Plugin_Handled;
}

// sends message 1 frame later
void FrameSendPlrCountMsg()
{
	int iInGame = GetNumPlayersInGame();
	if(iInGame >= g_cMinPlayers.IntValue)
	{
		if(iInGame != g_iLastPlayers)
		{
			PlayerCountMessage();
			g_iLastPlayers = iInGame;
		}
	}
}

// Format message
void PlayerCountMessage()
{
	char message[512] = STATUS_MSG;
	
	char sbot[64];
	g_cBotName.GetString(sbot, sizeof(sbot));
	
	char sColor[8];
	g_cColor.GetString(sColor, sizeof(sColor));
	
	char sMaxSlots[4];
	g_cMaxPlayers.GetString(sMaxSlots, sizeof(sMaxSlots));
	
	char servernick[64];
	g_cServerNick.GetString(servernick, sizeof(servernick));
	Discord_EscapeString(servernick, sizeof(servernick));
	
	char sNumPlayers[4];
	FormatEx(sNumPlayers, sizeof(sNumPlayers), "%i", GetNumPlayersInGame());


	ReplaceString(message, sizeof(message), "{BOTNAME}", sbot, false);
	ReplaceString(message, sizeof(message), "{COLOR}", sColor, false);
	ReplaceString(message, sizeof(message), "{NICKNAME}", servernick, false);
	ReplaceString(message, sizeof(message), "{NUMPLAYERS}", sNumPlayers, false);
	ReplaceString(message, sizeof(message), "{MAXSLOTS}", sMaxSlots, false);
	
	SendMessage(message);
}

// returns the number of players in game.
int GetNumPlayersInGame()
{
	int count = 0;
	for(int i = 1;i <= MaxClients;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
			count++;
	}
	return count;
}

// Sends a discord message to the webhook set in the convar
void SendMessage(char[] message)
{
	char webhook[32];
	g_cWebhook.GetString(webhook, sizeof(webhook));
	Discord_SendMessage(webhook, message);
#if defined DEBUG
	LogMessage("[DISCORD] Servind message \"%s\" to webhook \"%s\"", message, webhook);
#endif
}