#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[TF2C] Simple Vote Kick Immunity",
	author = "caxanga334",
	description = "Allow clients to become immune to vote kicks.",
	version = "1.0.0",
	url = "github.com/caxanga334"
};

public void OnClientPostAdminCheck(int client)
{
	RequestFrame(Frame_DisableAutoKick, view_as<any>(GetClientSerial(client)));
}

void Frame_DisableAutoKick(any data)
{
	int client = GetClientFromSerial(view_as<int>(data));

	if (client != 0)
	{
		if (CheckCommandAccess(client, "sm_native_autokick_immunity", ADMFLAG_KICK))
		{
			ServerCommand("mp_disable_autokick %i", GetClientUserId(client));
			LogMessage("Disabled auto-kick for admin %L.", client);
		}
	}
}