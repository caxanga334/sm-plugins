#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[ZPS-Dev] Entity Info",
	author = "caxanga334",
	description = "Dumps information about ZPS entities.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/navbot-plugins"
};


public void OnPluginStart()
{
	RegAdminCmd("sm_dev_info_beacon", Command_DumpInfoBeacon, ADMFLAG_CHEATS, "Dumps info_beacon data.");
	RegAdminCmd("sm_dev_trigger_useable", Command_DumpTriggerUseable, ADMFLAG_CHEATS, "Dumps trigger_useable data.");
	RegAdminCmd("sm_dev_item_deliver", Command_DumpItemDeliver, ADMFLAG_CHEATS, "Dumps item_deliver data.");
}

Action Command_DumpInfoBeacon(int client, int args)
{
	DumpInfoBeacons(client);
	return Plugin_Handled;
}

Action Command_DumpTriggerUseable(int client, int args)
{
	DumpAllTriggerUseable(client);
	return Plugin_Handled;
}

Action Command_DumpItemDeliver(int client, int args)
{
	DumpAllItemDeliver(client);
	return Plugin_Handled;
}

void DumpInfoBeacons(int client)
{
	int entity = INVALID_ENT_REFERENCE;

	while ((entity = FindEntityByClassname(entity, "info_beacon")) != INVALID_ENT_REFERENCE)
	{
		DumpInfoBeacon(entity, client);
	}
}

void DumpInfoBeacon(int entity, int client)
{
	int type = GetEntProp(entity, Prop_Send, "m_iType");
	int teamNum = GetEntProp(entity, Prop_Send, "m_nTeamNumber");
	int entFollow = GetEntProp(entity, Prop_Send, "m_iEntFollow");
	int on = GetEntProp(entity, Prop_Send, "m_bIsOn");
	float distance = GetEntPropFloat(entity, Prop_Send, "m_flDistance");
	float x = GetEntPropFloat(entity, Prop_Send, "m_flCordX");
	float y = GetEntPropFloat(entity, Prop_Send, "m_flCordY");
	float z = GetEntPropFloat(entity, Prop_Send, "m_flCordZ");
	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	ReplyToCommand(client, "info_beacon [%i] <%f %f %f>: Type %i Team %i Follow Entity %i Is On %i distance %f <%f %f %f>", 
	entity, origin[0], origin[1], origin[2], type, teamNum, entFollow, 
	on, distance, x, y, z);

	char iconzombie[64];
	char iconhuman[64];
	char labelzombie[64];
	char labelhuman[64];

	GetEntPropString(entity, Prop_Send, "m_strIconHuman", iconhuman, sizeof(iconhuman));
	GetEntPropString(entity, Prop_Send, "m_strIconZombie", iconzombie, sizeof(iconzombie));
	GetEntPropString(entity, Prop_Send, "m_strSurvivorLabel", labelhuman, sizeof(labelhuman));
	GetEntPropString(entity, Prop_Send, "m_strZombieLabel", labelzombie, sizeof(labelzombie));

	ReplyToCommand(client, "- Icon (H) \"%s\" Label (H) \"%s\"", iconhuman, labelhuman);
	ReplyToCommand(client, "- Icon (Z) \"%s\" Label (Z) \"%s\"", iconzombie, labelzombie);
}

void DumpAllTriggerUseable(int client)
{
	int entity = INVALID_ENT_REFERENCE;

	while ((entity = FindEntityByClassname(entity, "trigger_useable")) != INVALID_ENT_REFERENCE)
	{
		DumpTriggerUseable(client, entity);
	}
}

void DumpTriggerUseable(int client, int entity)
{
	char itemname[64];
	GetEntPropString(entity, Prop_Data, "m_iItemname", itemname, sizeof(itemname));
	char hint[128];
	GetEntPropString(entity, Prop_Data, "m_stTutor", hint, sizeof(hint));
	int disabled = GetEntProp(entity, Prop_Data, "m_bDisabled");

	ReplyToCommand(client, "trigger_useable [%i]: Disabled %i Item Name %s Tutor Hint %s", entity, disabled, itemname, hint);
}

void DumpAllItemDeliver(int client)
{
	int entity = INVALID_ENT_REFERENCE;

	while ((entity = FindEntityByClassname(entity, "item_deliver")) != INVALID_ENT_REFERENCE)
	{
		DumpItemDeliver(client, entity);
	}
}

void DumpItemDeliver(int client, int entity)
{
	int removeOnUse = GetEntProp(entity, Prop_Send, "m_bRemoveOnUse");
	int itemState = GetEntProp(entity, Prop_Send, "m_iItemState");
	int carryState = GetEntProp(entity, Prop_Send, "m_iCarryState");
	int food = GetEntProp(entity, Prop_Data, "m_iFoodValue");
	char itemid[64];
	GetEntPropString(entity, Prop_Data, "m_strItemID", itemid, sizeof(itemid));
	int important = GetEntProp(entity, Prop_Data, "m_bIsImportant");
	int ignorevvis = GetEntProp(entity, Prop_Data, "m_bIgnoreVvis");
	char printname[64];
	GetEntPropString(entity, Prop_Data, "m_strPrintName", printname, sizeof(printname));
	float removeTimer = GetEntPropFloat(entity, Prop_Data, "m_flRemoveTimer");
	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	ReplyToCommand(client, "item_deliver [%i] <%f %f %f>: Remove on Use %i Item State %i Carry State %i Food Value %i", 
		entity, origin[0], origin[1], origin[2], removeOnUse, itemState, carryState, food);
	ReplyToCommand(client, "- Item ID %s Important %i Ignore Vis %i Print Name %s Remove Timer %f", 
		itemid, important, ignorevvis, printname, removeTimer);
}