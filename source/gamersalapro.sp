#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

public Plugin myinfo = {
	name = "Gamers ala Pro",
	author = "caxanga334",
	description = "Gamers ala Pro Server Plugin.",
	version = "1.0.0",
	url = "https://www.gamersalapro.com"
}

public void OnPluginStart() {
	RegAdminCmd( "sm_add_attribute", Command_AddAttrb, ADMFLAG_CHEATS, "Adds attribute to a player.");
	RegAdminCmd( "sm_regen", Command_Regen, ADMFLAG_CHEATS, "Regenerates ammo and health." );
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
	
