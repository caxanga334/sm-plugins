#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "[TF2] MvM Visible Max Players",
	author = "FlaminSarge, caxanga334",
	description = "Spams console about 6-player MvM, but sets sv_visiblemaxplayers to other values",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

ConVar cvarCount;
ConVar sv_visiblemaxplayers;
int count =  -1;

public void OnPluginStart()
{
	CreateConVar("mvm_vismaxp_version", PLUGIN_VERSION, "[TF2] MvM Visible Max Players", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarCount = CreateConVar("mvm_visiblemaxplayers", "-1", "Set above 0 to set sv_visiblemaxplayers for MvM", FCVAR_NONE, true, -1.0, true, 32.0);
	count = GetConVarInt(cvarCount);
	HookConVarChange(cvarCount, cvarChange_cvarCount);
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	HookConVarChange(sv_visiblemaxplayers, cvarChange_sv_visiblemaxplayers);

	AutoExecConfig(true, "plugin.mvmvisiblemaxplayers");
}

public void OnMapStart()
{
	IsMvM(true);
}

void cvarChange_cvarCount(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (IsMvM())
	{
		count = convar.IntValue;
		if (sv_visiblemaxplayers != INVALID_HANDLE) SetConVarInt(sv_visiblemaxplayers, count > 0 ? count : -1);
	}
}

void cvarChange_sv_visiblemaxplayers(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (IsMvM())
	{
		if (count > 0 && convar.IntValue != count) SetConVarInt(convar, count);
	}
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
