#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

StringMap g_entstoLog = null;

public Plugin myinfo =
{
	name = "[DEV] Entity Speed Logger",
	author = "caxanga334",
	description = "Developer plugin for logging entity speeds",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};


public void OnPluginStart()
{
	g_entstoLog = new StringMap();
	RegAdminCmd("sm_esl_addentity", CMD_LogEntity, ADMFLAG_ROOT, "Adds an entity classname to the speed logger list.");
	RegAdminCmd("sm_esl_purgelist", CMD_Purge, ADMFLAG_ROOT, "Clears the list of monitored entities.");
}

Action CMD_LogEntity(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_esl_addentity <classname>");
		return Plugin_Handled;
	}

	char arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));

	if (g_entstoLog.ContainsKey(arg1))
	{
		ReplyToCommand(client, "Entity %s is already being logged!", arg1);
		return Plugin_Handled;
	}

	g_entstoLog.SetValue(arg1, view_as<any>(true));

	return Plugin_Handled;
}

Action CMD_Purge(int client, int args)
{
	g_entstoLog.Clear();
	return Plugin_Handled;	
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_entstoLog.ContainsKey(classname))
	{
		PrintToServer("Hooked entity %i %s!", entity, classname);
		SDKHook(entity, SDKHook_ThinkPost, OnEntityThinkPost);
	}
}

void OnEntityThinkPost(int entity)
{
	float vec[3];
	float speed = 0.0;
	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vec);
	speed = GetVectorLength(vec);
	PrintToServer("#%i <%s>: speed %3.4f (%3.4f, %3.4f, %3.4f)", entity, classname, speed, vec[0], vec[1], vec[2]);
}