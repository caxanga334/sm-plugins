#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "Player Run Command Debug",
	author = "caxanga334",
	description = "Player Run Command Debug",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins/"
};

bool g_bEnabled = false;

public void OnPluginStart()
{
	RegConsoleCmd("sm_runcmd_toggle_debug", Cmd_Toggle, "Toggle debug print.");
}

Action Cmd_Toggle(int client, int args)
{
	g_bEnabled = !g_bEnabled;
	return Plugin_Handled;
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!g_bEnabled)
	{
		return;
	}

	if (IsClientInGame(client) && IsFakeClient(client))
	{
		PrintToServer("OnPlayerRunCmdPre %N seed = %i", client, seed);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}

	if (IsClientInGame(client) && IsFakeClient(client))
	{
		PrintToServer("OnPlayerRunCmd %N seed = %i", client, seed);
	}

	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!g_bEnabled)
	{
		return;
	}

	if (IsClientInGame(client) && IsFakeClient(client))
	{
		PrintToServer("OnPlayerRunCmdPost %N seed = %i", client, seed);
	}
}