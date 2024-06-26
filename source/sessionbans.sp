#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[ANY] Session Bans",
	author = "caxanga334",
	description = "Temporarily ban players until level change.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
};

// globals

StringMap g_BanList = null;
char g_IPBan[18];

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");

	RegAdminCmd("sm_sessionban", ConCmd_SessionBanClient, ADMFLAG_BAN, "Session bans a client.");
}

public void OnMapStart()
{
	// Re-create the stringmap, purging old bans

	if (g_BanList != null)
	{
		delete g_BanList;
		g_BanList = null;
	}

	g_BanList = new StringMap();
}

// Use this instead of OnClientPutInServer since the client will always be authorized
// This plugin doesn't handle clients without auth, another plugin should be used for that
public void OnClientPostAdminCheck(int client)
{
	// Ignore bots
	if (IsFakeClient(client))
	{
		return;
	}

	char steamID[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID)))
	{
		LogError("Failed to get SteamID64 for client %L", client);
		return;
	}

	if (g_BanList.ContainsKey(steamID))
	{
		// client is session banned
		GetClientIP(client, g_IPBan, sizeof(g_IPBan));
		LogAction(0, client, "%L joined while session banned and was kicked.", client);
		ShowActivity2(0, "[SM] ", "%N is session banned and was kicked.", client);
		KickClient(client, "Session banned.");
		RequestFrame(ApplyIPBan);
	}
}

void AddSessionBan(int client)
{
	if (!IsClientInGame(client))
	{
		return;
	}

	char steamID[MAX_AUTHID_LENGTH];

	if (!GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID)))
	{
		return;
	}

	g_BanList.SetValue(steamID, view_as<any>(true));
	KickClient(client, "Session banned.");
}

Action ConCmd_SessionBanClient(int client, int args)
{
	if (g_BanList == null)
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_sessionban <target>");
		return Plugin_Handled;
	}

	char arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));

	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		LogAction(client, target_list[i], "%L session banned %L.", client, target_list[i]);
		AddSessionBan(target_list[i]);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t was session banned.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%s was session banned.", target_name);
	}

	return Plugin_Handled;
}

// If a session banned player joins the server, apply a 15 minutes IP ban so they can't keep reconnecting to the server.
void ApplyIPBan()
{
	BanIdentity(g_IPBan, 15, BANFLAG_IP, "Session Banned", "sm_sessionban");
	g_IPBan = "";
}