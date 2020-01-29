#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo =
{
	name = "[TF2] 10vM (Ten Mann vs Machine)",
	author = "FlaminSarge, caxanga334",
	description = "Allows MvM to support up to 10 people (less if Replay/STV)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}
ConVar hCvarSafety;
ConVar hCvarEnabled;

public void OnPluginStart()
{
	CreateConVar("tenmvm_version", PLUGIN_VERSION, "Allows up to 10 players (9/8 if Replay/STV are present) to join RED for MvM", FCVAR_NOTIFY);
	hCvarEnabled = CreateConVar("tenmvm_enabled", "1", "Enable/disable cvar", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarSafety = CreateConVar("tenmvm_safety", "1", "Set 0 to disable the check against more than 10 people joining RED", FCVAR_NONE, true, 0.0, true, 1.0);
	RegAdminCmd("sm_mvmred", Command_JoinRed, 0, "Usage: sm_mvmred to join RED team if on the spectator team");
	RegAdminCmd("sm_forcered", Command_ForceRed, ADMFLAG_SLAY, "Forces a specific player to join RED team");
	AddCommandListener(Cmd_JoinTeam, "jointeam");
	AddCommandListener(Cmd_JoinTeam, "autoteam");
	
	// EVENTS
	HookEvent( "mvm_begin_wave", E_WaveStart );
}
public void OnMapStart()
{
	IsMvM(true);
}
public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
		CreateTimer(10.0, Timer_CheckTeam, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action Cmd_JoinTeam(int client, const char[] command, int argc)
{
	char arg1[32];
	if (!GetConVarBool(hCvarEnabled)) return Plugin_Continue;
	if (!IsMvM()) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Continue;
	if (IsFakeClient(client)) return Plugin_Continue;	//Bots tend to join whatever team they want regardless of MvM limits
	if (!CheckCommandAccess(client, "sm_mvmred", 0)) return Plugin_Continue;
	if (DetermineTooManyReds()) return Plugin_Continue;
	if (argc > 0) GetCmdArg(1, arg1, sizeof(arg1));
	if (StrEqual(command, "autoteam", false) || StrEqual(arg1, "auto", false) || StrEqual(arg1, "spectator", false) || StrEqual(arg1, "red", false))
	{
		if (!StrEqual(arg1, "spectator", false) || GetClientTeam(client) == view_as<int>(TFTeam_Unassigned))
		{
			CreateTimer(0.0, Timer_TurnToRed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			//TurnToRed(client);	//this causes players to have 0 money, not good
			return Plugin_Continue;	//Let them join spec so their money is set properly, then a frame later swap 'em to red
		}
	}
	return Plugin_Continue;
}
public Action Timer_TurnToRed(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	TurnToRed(client);
}
public Action Timer_CheckTeam(Handle timer, any client)
{
	if(IsValidClient(client) && TF2_GetClientTeam(client) != TFTeam_Red)
	{
		TurnToRed(client);
	}
}
void TurnToRed(int client)
{
	if (GetClientTeam(client) == view_as<int>(TFTeam_Red)) return;
	int target[MAXPLAYERS + 1] = { -1, ... };
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) == view_as<int>(TFTeam_Red))
		{
			target[count] = i;
			count++;
		}
	}
	for (int i = 0; i < (count - 5); i++)
	{
		if (target[i] != -1) SetEntProp(target[i], Prop_Send, "m_iTeamNum", view_as<int>(TFTeam_Blue));
	}
	ChangeClientTeam(client, view_as<int>(TFTeam_Red));
	for (int i = 0; i < (count - 5); i++)
	{
		if (target[i] != -1)
		{
			SetEntProp(target[i], Prop_Send, "m_iTeamNum", view_as<int>(TFTeam_Red));
			int flag = GetEntPropEnt(target[i], Prop_Send, "m_hItem");
			if (flag > MaxClients && IsValidEntity(flag))
			{
				if (GetEntProp(flag, Prop_Send, "m_iTeamNum") != view_as<int>(TFTeam_Red)) AcceptEntityInput(flag, "ForceDrop");
			}
		}
	}
	if (GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") == view_as<int>(TFClass_Unknown)) ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
}
public Action Command_JoinRed(int client,int args)
{
	if (!GetConVarBool(hCvarEnabled)) return Plugin_Continue;	//"Command not found" if Plugin_Continue. We want this if disabled/not MvM
	if (!IsMvM()) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Handled;
	if (IsFakeClient(client)) return Plugin_Continue;	//Bots tend to join whatever team they want regardless of MvM limits
	if (GetClientTeam(client) != view_as<int>(TFTeam_Spectator)) return Plugin_Handled;	//Don't let unassigned/blue/red use this command, it'll cause issues
	if (DetermineTooManyReds())
	{
		ReplyToCommand(client, "[10vM] Sorry, there's too many people already on RED for the robots to spawn properly if you join.");
		return Plugin_Handled;
	}
	TurnToRed(client);
	ReplyToCommand(client, "[10vM] You're no longer spectating.");
	return Plugin_Handled;
}
public Action Command_ForceRed(int client,int args)
{
	if( args < 1 )
	{
		ReplyToCommand(client, "Usage: sm_forcered <target>");
		return Plugin_Handled;
	}

	char arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(int i = 0; i < target_count; i++)
	{
		if( TF2_GetClientTeam(target_list[i]) != TFTeam_Red )
		{
			TurnToRed(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" moved \"%L\" to RED team.", client, target_list[i]);
		}
		else
		{
			ReplyToCommand(client, "ERROR: The target player is on RED.");
			return Plugin_Handled;
		}
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Moved %t to RED team.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Moved %s to RED team.", target_name);
	}
	
	return Plugin_Handled;
}
bool DetermineTooManyReds()
{
	if (!GetConVarBool(hCvarSafety)) return false;
	int max = 10;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsClientReplay(i) || IsClientSourceTV(i)) max--;
		if (GetClientTeam(i) == view_as<int>(TFTeam_Red)) max--;
	}
	return (max <= 0);
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return !(IsClientSourceTV(client) || IsClientReplay(client));
}

bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

/****************************************************
					EVENTS
*****************************************************/
// Move players to RED when a wave starts.
public Action E_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			if(TF2_GetClientTeam(i) != TFTeam_Red)
			{
				TurnToRed(i);
			}
		}
	}
}