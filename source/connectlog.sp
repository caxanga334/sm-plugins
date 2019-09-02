#include <sourcemod>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===
char g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo = {
	name = "[ANY] Connect Log",
	author = "caxanga334",
	description = "Logs connections to a file.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/"
}

stock void CreateLogFile() { // creates the log file in the system
	char cTime[64];
	FormatTime(cTime, sizeof(cTime), "%Y%m%d"); // add date to file name
	// Path used for logging.
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/connections_%s.log", cTime);
}

public void OnPluginStart() {
	CreateLogFile();
}

public void OnMapStart() {
	CreateLogFile();
}

public void OnClientConnected(int client) {
	char sClientIP[64];
	GetClientIP(client, sClientIP, sizeof(sClientIP), false);
	if (!IsFakeClient(client)) {
		LogToFileEx(g_sLogPath,
			"[Connection Log] New connection (%s).",
			sClientIP);
	}
}

public void OnClientAuthorized(int client, const char[] auth) {
	char sName[MAX_NAME_LENGTH];
	char sAuth[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName))
	GetClientAuthId(client, AuthId_Engine, sAuth, sizeof(sAuth))
	if (!IsFakeClient(client)) {
		LogToFileEx(g_sLogPath,
			"[Connection Log] Client %s Authorized (%s).",
			sName,
			sAuth);
	}
}

public void OnClientDisconnect(int client) {
	char sName[MAX_NAME_LENGTH];
	char sClientIP[64];
	char sAuth[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName))
	GetClientIP(client, sClientIP, sizeof(sClientIP), false);
	GetClientAuthId(client, AuthId_Engine, sAuth, sizeof(sAuth))
	if (!IsFakeClient(client)) {
		LogToFileEx(g_sLogPath,
			"[Connection Log] Client %s disconnected (%s - %s).",
			sName,
			sClientIP,
			sAuth);
	}
}