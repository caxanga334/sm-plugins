#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

enum PropertyType
{
	Property_Integer = 0,
	Property_Float,
	Property_Entity,
	Property_String,
	Property_Vector,

	MAX_PROPERTY_TYPES
}

public Plugin myinfo =
{
	name = "[DEV] Gamerules Props",
	author = "caxanga334",
	description = "Plugins for reading gamerules properties.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_gamerules_getprop", Command_GetPropInt, ADMFLAG_RCON, "Reads an integer property of gamerules.");
	RegAdminCmd("sm_gamerules_getpropfloat", Command_GetPropFloat, ADMFLAG_RCON, "Reads an integer property of gamerules.");
	RegAdminCmd("sm_gamerules_getpropent", Command_GetPropEnt, ADMFLAG_RCON, "Reads an integer property of gamerules.");
	RegAdminCmd("sm_gamerules_getpropvector", Command_GetPropVector, ADMFLAG_RCON, "Reads an integer property of gamerules.");
	RegAdminCmd("sm_gamerules_getpropstring", Command_GetPropString, ADMFLAG_RCON, "Reads an integer property of gamerules.");
}

Action Command_GetPropInt(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gamerules_getprop <property name> <optional: array element index>");
		return Plugin_Handled;
	}

	char arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));
	int element = 0;

	if (args >= 2)
	{
		element = GetCmdArgInt(2);
	}

	GameRules_PrintProperty(client, arg1, Property_Integer, element);
	return Plugin_Handled;
}

Action Command_GetPropFloat(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gamerules_getpropfloat <property name> <optional: array element index>");
		return Plugin_Handled;
	}

	char arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));
	int element = 0;

	if (args >= 2)
	{
		element = GetCmdArgInt(2);
	}

	GameRules_PrintProperty(client, arg1, Property_Float, element);
	return Plugin_Handled;
}

Action Command_GetPropEnt(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gamerules_getpropent <property name> <optional: array element index>");
		return Plugin_Handled;
	}

	char arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));
	int element = 0;

	if (args >= 2)
	{
		element = GetCmdArgInt(2);
	}

	GameRules_PrintProperty(client, arg1, Property_Entity, element);
	return Plugin_Handled;
}

Action Command_GetPropVector(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gamerules_getpropvector <property name> <optional: array element index>");
		return Plugin_Handled;
	}

	char arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));
	int element = 0;

	if (args >= 2)
	{
		element = GetCmdArgInt(2);
	}

	GameRules_PrintProperty(client, arg1, Property_Vector, element);
	return Plugin_Handled;
}

Action Command_GetPropString(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gamerules_getpropstring <property name> <optional: array element index>");
		return Plugin_Handled;
	}

	char arg1[512];
	GetCmdArg(1, arg1, sizeof(arg1));
	int element = 0;

	if (args >= 2)
	{
		element = GetCmdArgInt(2);
	}

	GameRules_PrintProperty(client, arg1, Property_String, element);
	return Plugin_Handled;
}

void GameRules_PrintProperty(int client, const char[] prop, PropertyType type, int element = 0)
{
	switch (type)
	{
	case Property_Integer:
	{
		int value = GameRules_GetProp(prop, .element = element);
		ReplyToCommand(client, "GameRules property \"%s\" has a value of %i", prop, value);
	}
	case Property_Float:
	{
		float value = GameRules_GetPropFloat(prop, .element = element);
		ReplyToCommand(client, "GameRules property \"%s\" has a value of %f", prop, value);
	}
	case Property_Entity:
	{
		int value = GameRules_GetPropEnt(prop, .element = element);
		ReplyToCommand(client, "GameRules property \"%s\" has a value of %i", prop, value);

		if (IsValidEntity(value))
		{
			char classname[256];
			GetEntityClassname(value, classname, sizeof(classname));
			ReplyToCommand(client, "Entity: %s", classname);
		}
	}
	case Property_String:
	{
		char buffer[4096];
		GameRules_GetPropString(prop, buffer, sizeof(buffer), element);
		ReplyToCommand(client, "GameRules property \"%s\" has a value of \"%s\"", prop, buffer);
	}
	case Property_Vector:
	{
		float vec[3];
		GameRules_GetPropVector(prop, vec, .element = element);
		ReplyToCommand(client, "GameRules property \"%s\" has a value of %f %f %f", prop, vec[0], vec[1], vec[2]);
	}
	}
}