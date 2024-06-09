#include <sourcemod>
#include <autoexecconfig>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D/2] Anti Early Vote",
	author = "caxanga334",
	description = "Block players that just joined the server from calling votes.",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/sm-plugins"
};

ConVar c_JoinCastVoteDelay;

enum struct PlayerData
{
	float allowvotetime; // time the player will be allowed to cast votes

	void Reset()
	{
		this.allowvotetime = 0.0;
	}

	void OnClientJoin(float delay)
	{
		this.Reset();
		this.allowvotetime = GetGameTime() + delay;
	}

	bool IsAllowedToStartVotes()
	{
		float now = GetGameTime();

		if (now > this.allowvotetime)
		{
			return true;
		}

		return false;
	}
}

PlayerData g_data[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	switch (engine)
	{
		case Engine_Left4Dead, Engine_Left4Dead2:
		{
			return APLRes_Success;
		}
		default:
		{
			strcopy(error, err_max, "This plugin is for Left 4 Dead / 2 only!");
			return APLRes_Failure;
		}
	}
}

public void OnPluginStart()
{
	c_JoinCastVoteDelay = AutoExecConfig_CreateConVar("sm_l4d_anti_vote_delay", "90.0", "Block new players from casting votes for this many seconds.");
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("l4d.antiearlyvote");
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	AddCommandListener(OnCallVoteCommand, "callvote");
}

public void OnClientPutInServer(int client)
{
	g_data[client].OnClientJoin(c_JoinCastVoteDelay.FloatValue);
}

public void OnClientDisconnect_Post(int client)
{
	g_data[client].Reset();
}

Action OnCallVoteCommand(int client, const char[] command, int argc)
{
	if (client == 0)
	{
		return Plugin_Continue; // server/console
	}

	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if (CheckCommandAccess(client, "sm_l4d_bypass_early_votes", ADMFLAG_KICK))
	{
		return Plugin_Continue;
	}

	if (!g_data[client].IsAllowedToStartVotes())
	{
		char buffer[1024];

		FormatEx(buffer, sizeof(buffer), "Client %L called vote. Args: ", client);

		for (int i = 1; i <= argc; i++)
		{
			char argument[256];
			GetCmdArg(i, argument, sizeof(argument));
			StrCat(buffer, sizeof(buffer), argument);
		}

		LogAction(client, -1, "%s", buffer);
		PrintToChat(client, "Newly joined players cannot start votes! Please wait a few minutes.");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}