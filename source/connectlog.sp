#pragma newdecls required // enforce new SM 1.7 syntax
#pragma semicolon 1

#include <sourcemod>

// ===variables===
char g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo = {
	name = "[ANY] Connect Log",
	author = "caxanga334",
	description = "Logs connections to a file.",
	version = "1.1.0",
	url = "https://github.com/caxanga334/"
}

stock void CreateLogFile() { // creates the log file in the system
	char cTime[64];
	FormatTime(cTime, sizeof(cTime), "%Y-%m-%d"); // add date to file name
	// Path used for logging.
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/connections_%s.log", cTime);
}

public void OnPluginStart() {
	CreateLogFile();
	CreateTimer(15.0, Timer_CheckTime, _, TIMER_REPEAT);
	HookEvent("player_disconnect", Event_PlayerDisc, EventHookMode_Pre);
}

public void OnMapStart() {
	CreateLogFile();
}

public void OnClientConnected(int client) {
	char sClientIP[64];

	GetClientIP(client, sClientIP, sizeof(sClientIP), false);

	if (!IsFakeClient(client)) 
	{
		LogToFileEx(g_sLogPath, "[Connection Log] New connection (%s).", sClientIP);
	}
}

public void OnClientAuthorized(int client, const char[] auth) {
	char sName[MAX_NAME_LENGTH];
	char sAuth[MAX_AUTHID_LENGTH];
	char sMethod[64];

	GetClientName(client, sName, sizeof(sName));
	GetClientAuthId(client, AuthId_Engine, sAuth, sizeof(sAuth));

	if (!GetClientInfo(client, "cl_connectmethod", sMethod, sizeof(sMethod)))
	{
		strcopy(sMethod, sizeof(sMethod), "Unknown");
	}

	if (!IsFakeClient(client)) 
	{
		LogToFileEx(g_sLogPath, "[Connection Log] Client %s Authorized (%s). Connection Method: %s", sName, sAuth, sMethod);
	}
}

public Action Event_PlayerDisc(Event event, const char[] name, bool dontBroadcast)
{
	char plname[MAX_NAME_LENGTH], auth[64], reason[256], sClientIP[64];
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if( client < 1 || client > MaxClients )
		return Plugin_Continue;
	
	GetClientIP(client, sClientIP, sizeof(sClientIP), false);
	
	event.GetString("name", plname, sizeof(plname), "");
	event.GetString("networkid", auth, sizeof(auth), "");
	event.GetString("reason", reason, sizeof(reason), "");
	
	if(!StrEqual(auth, "BOT", true))
	{
		LogToFileEx(g_sLogPath,
			"[Connection Log] Client %s disconnected (%s - %s). Reason: %s",
			plname,
			sClientIP,
			auth,
			reason);
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

/* public void OnClientDisconnect(int client) {
	char sName[MAX_NAME_LENGTH];
	char sClientIP[64];
	char sAuth[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	GetClientIP(client, sClientIP, sizeof(sClientIP), false);
	GetClientAuthId(client, AuthId_Engine, sAuth, sizeof(sAuth));
	if (!IsFakeClient(client)) {
		LogToFileEx(g_sLogPath,
			"[Connection Log] Client %s disconnected (%s - %s).",
			sName,
			sClientIP,
			sAuth);
	}
} */

public Action Timer_CheckTime(Handle timer)
{
	CreateLogFile();
	return Plugin_Continue;
}