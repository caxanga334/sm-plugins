#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "Map End Exec",
	author = "caxanga334",
	description = "Executes a config file when the map ends.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

bool g_isFirstExec = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!FileExists("cfg/server_onmapend.cfg"))
	{
		strcopy(error, err_max, "cfg/server_onmapend.cfg not found, disabling plugin!");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnConfigsExecuted()
{
	// execute the file once after onmapstart since these vars may not be present in the main server config file.
	if (!g_isFirstExec)
	{
		g_isFirstExec = true;
		ExecConfig();
	}
}

public void OnMapEnd()
{
	ExecConfig();
}

void ExecConfig()
{
	LogToGame("[SOURCEMOD] Executing server_onmapend.cfg!");
	ServerCommand("exec server_onmapend.cfg\n");
	ServerExecute();
}