#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

bool g_invalidmovesim[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Player Movement Bug Test",
	author = "caxanga334",
	description = "Tests some player movement bugs.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");

	RegAdminCmd("sm_bug_invalidmove", CMD_InvalidMoveBug, ADMFLAG_ROOT, "Triggers the invalid move bug.");
}

void ResetPlayerVars(int client)
{
	g_invalidmovesim[client] = false;
}

public void OnClientPutInServer(int client)
{
	ResetPlayerVars(client);
}

Action CMD_InvalidMoveBug(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bug_invalidmove <target> \n");
		return Plugin_Handled;
	}


	char arg1[MAX_TARGET_LENGTH];
 
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));
 
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (int i = 0; i < target_count; i++)
	{
		g_invalidmovesim[target_list[i]] = true;
		LogAction(client, target_list[i], "%L simulated the invalid move bug on %L.", client, target_list[i]);
	}
 
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_invalidmovesim[client])
	{
		g_invalidmovesim[client] = false;

		vel[0] = -65970646126952448.0000;
		vel[1] = 0.0 / 0.0;
		vel[2] = -52466203796439040.0000;
		LogAction(client, -1, "Activating invalid move bug for %L: %f %f %f", client, vel[0], vel[1], vel[2]);
		return Plugin_Changed;
	}


	return Plugin_Continue;
}