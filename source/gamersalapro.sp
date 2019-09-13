#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

float flSavedPosVec[3][MAXPLAYERS];

// regen toggle
Handle T_Regen[MAXPLAYERS+1];
bool g_bToggleRegen[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Gamers ala Pro",
	author = "caxanga334",
	description = "Gamers ala Pro Server Plugin.",
	version = "1.0.0",
	url = "https://www.gamersalapro.com"
}

public void OnPluginStart() {
	LoadTranslations("common.phrases.txt");
	
	RegAdminCmd( "sm_add_attribute", Command_AddAttrb, ADMFLAG_CHEATS, "Adds attribute to a player.");
	RegAdminCmd( "sm_regen", Command_Regen, ADMFLAG_CHEATS, "Regenerates ammo and health." );
	RegAdminCmd( "sm_regentoggle", Command_RegenToggle, ADMFLAG_CHEATS, "Toggles constant regeneration of ammo and health." );
	RegAdminCmd( "sm_fullcharge", Command_FullCharge, ADMFLAG_CHEATS, "Sets full charge." );
	RegAdminCmd( "sm_save", Command_SavePos, ADMFLAG_CHEATS, "Saves your position." );
	RegAdminCmd( "sm_gotosaved", Command_GoToPos, ADMFLAG_CHEATS, "Go to your saved position." );
	RegAdminCmd( "sm_teletoorigin", Command_TeleToPos, ADMFLAG_CHEATS, "Teleports the target client to the specified origin." );
	RegAdminCmd( "sm_getclientinfo", Command_GetClientInfo, ADMFLAG_CHEATS, "Prints information about the target client." );
	RegConsoleCmd( "sm_printorigin", Command_PrintOrigin, "Prints your origin." );
}

public void OnClientDisconnect(int client)
{
	if( g_bToggleRegen[client] )
	{
		g_bToggleRegen[client] = false;
		KillTimer(T_Regen[client]);
		T_Regen[client] = null;
	}
}

public Action Command_AddAttrb(int client, int nArgs)
{
	if( nArgs < 3 )
	{
		ReplyToCommand(client, "Usage: sm_add_attribute <target> <attribute> <value>");
		return Plugin_Handled;
	}
	
	char Arg3[64];
	char attrib[256];
	char Arg1[MAX_NAME_LENGTH];
	float value;
	
	GetCmdArg(3, Arg3, sizeof(Arg3));
	GetCmdArg(2, attrib, sizeof(attrib));
	GetCmdArg(1, Arg1, sizeof(Arg1));
	value = StringToFloat(Arg3);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(Arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		TF2Attrib_SetByName(target_list[i], attrib, value);
		LogAction(client, target_list[i], "\"%L\" add attribute \"%s\" (%f) to \"%L\"", client, attrib, value, target_list[i] );
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Added an attribute \"%s\" (%f) on %t.", attrib, value, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Added an attribute \"%s\" (%f) on %s.", attrib, value, target_name);
	}

	return Plugin_Handled;
}

public Action Command_Regen(int client, int args)
{
	if( IsPlayerAlive(client) )
	{
		TF2_RegeneratePlayer(client);
	}
	
	return Plugin_Handled;
}

public Action Command_RegenToggle(int client, int args)
{
	if( !g_bToggleRegen[client] )
	{
		T_Regen[client] = CreateTimer(0.1, Timer_Regenerate, client, TIMER_REPEAT);
		g_bToggleRegen[client] = true;
		ReplyToCommand(client, "Regen Enabled.");
	}
	else
	{
		KillTimer(T_Regen[client]);
		T_Regen[client] = null;
		g_bToggleRegen[client] = false;
		ReplyToCommand(client, "Regen Disabled.");
	}
	
	return Plugin_Handled;
}
	
public Action Command_SavePos(int client, int args)
{
	float posVec[3];

	if( IsPlayerAlive(client) )
	{
		GetClientAbsOrigin(client, posVec);
		// transfer to global var.
		flSavedPosVec[0][client] = posVec[0];
		flSavedPosVec[1][client] = posVec[1];
		flSavedPosVec[2][client] = posVec[2];
		ShowActivity2(client, "[SM] ", "%N saved his position.", client);
		LogAction(client, -1, "\"%L\" saved his position.", client);
	}
	
	return Plugin_Handled;
}

public Action Command_GoToPos(int client, int args)
{
	float posVec[3];

	if( IsPlayerAlive(client) )
	{
		posVec[0] = flSavedPosVec[0][client];
		posVec[1] = flSavedPosVec[1][client];
		posVec[2] = flSavedPosVec[2][client];
		TeleportEntity(client, posVec, NULL_VECTOR, NULL_VECTOR);
		ShowActivity2(client, "[SM] ", "teleported to his saved position.");
		LogAction(client, -1, "\"%L\" teleported to his saved position.", client);
	}
	
	return Plugin_Handled;
}

public Action Command_PrintOrigin(int client, int args)
{
	float EyeVec[3], OriginVec[3];
	
	GetClientEyePosition(client, EyeVec);
	GetClientAbsOrigin(client, OriginVec);
	
	ReplyToCommand(client, "Eye Position: %f, %f, %f", EyeVec[0],EyeVec[1],EyeVec[2]);
	ReplyToCommand(client, "ABS Origin: %f, %f, %f", OriginVec[0],OriginVec[1],OriginVec[2]);

	return Plugin_Handled;
}

public Action Command_TeleToPos(int client, int nArgs)
{
	if( nArgs < 4 )
	{
		ReplyToCommand(client, "Usage: sm_teletoorigin <target> <x> <y> <z>");
		return Plugin_Handled;
	}
	
	char Arg1[MAX_NAME_LENGTH], Arg2[32], Arg3[32], Arg4[32];
	float TargetVec[3];
	
	GetCmdArg(1, Arg1, sizeof(Arg1));
	GetCmdArg(2, Arg2, sizeof(Arg2));
	GetCmdArg(3, Arg3, sizeof(Arg3));
	GetCmdArg(4, Arg4, sizeof(Arg4));
	TargetVec[0] = StringToFloat(Arg2);
	TargetVec[1] = StringToFloat(Arg3);
	TargetVec[2] = StringToFloat(Arg4);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(Arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		TeleportEntity(target_list[i], TargetVec, NULL_VECTOR, NULL_VECTOR);
		LogAction(client, target_list[i], "\"%L\" teleported \"%L\" to (%f,%f,%f)", client, target_list[i], TargetVec[0],TargetVec[1],TargetVec[2] );
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Teleported \"%t\" to (%f,%f,%f)", target_name,TargetVec[0],TargetVec[1],TargetVec[2]);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Teleported \"%s\" to (%f,%f,%f)", target_name,TargetVec[0],TargetVec[1],TargetVec[2]);
	}

	return Plugin_Handled;
}

public Action Command_GetClientInfo(int client, int nArgs)
{
	if( nArgs < 1 )
	{
		ReplyToCommand(client, "Usage: sm_getclientinfo <target>");
		return Plugin_Handled;
	}
	
	char Arg1[MAX_NAME_LENGTH];
	float EyeVec[3], OriginVec[3];
	int iHealth;
	
	GetCmdArg(1, Arg1, sizeof(Arg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(Arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		iHealth = GetClientHealth(target_list[i]);
		GetClientEyePosition(target_list[i], EyeVec);
		GetClientAbsOrigin(target_list[i], OriginVec);
		
	}
	
	ReplyToCommand(client, "Target: %s | Health: %i", target_name, iHealth);
	ReplyToCommand(client, "Eye Position: %f, %f, %f", EyeVec[0],EyeVec[1],EyeVec[2]);
	ReplyToCommand(client, "ABS Origin: %f, %f, %f", OriginVec[0],OriginVec[1],OriginVec[2]);

	return Plugin_Handled;
}

public Action Command_FullCharge(int client, int args)
{
	if( IsPlayerAlive(client) )
	{
		TFClassType TFClass = TF2_GetPlayerClass(client);
	
		SetEntPropFloat( client, Prop_Send, "m_flRageMeter", 100.0 );
		
		switch( TFClass )
		{
			case TFClass_Medic:
			{
				int iEnt = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if( IsValidEntity(iEnt) )
					SetEntPropFloat( iEnt, Prop_Send, "m_flChargeLevel", 1.0 );
			}
			case TFClass_Spy: SetEntPropFloat( client, Prop_Send, "m_flCloakMeter", 100.0 );
		}
	}
	
	ReplyToCommand(client, "Setting full charge.");
	return Plugin_Handled;
}

// timers
public Action Timer_Regenerate(Handle timer, any client)
{
	if( IsPlayerAlive(client) )
		TF2_RegeneratePlayer(client);
		
	
	return Plugin_Continue
}