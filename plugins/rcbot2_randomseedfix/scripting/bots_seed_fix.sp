#include <sourcemod>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

int g_offsetof_random_seed;
int g_offsetof_server_random_seed;
DynamicHook g_playerruncommandhook;

public Plugin myinfo =
{
	name = "Bots Random Seed Fix",
	author = "caxanga334",
	description = "Fixes third-party bots not getting a proper server random seed set for their user commands.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

public void OnPluginStart()
{
	g_offsetof_random_seed = -1;
	g_offsetof_server_random_seed = -1;
	g_playerruncommandhook = null;

	if (!GetUserCommandOffsets())
	{
		SetFailState("Gamedata errors.");
	}

	GameData gd = new GameData("sdktools.games");

	g_playerruncommandhook = DHookCreate(0, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);

	if (g_playerruncommandhook == null)
	{
		SetFailState("Failed to create dynamic hook!");
	}

	if (!DHookSetFromConf(g_playerruncommandhook, gd, SDKConf_Virtual, "PlayerRunCmd"))
	{
		SetFailState("Failed to get offset of CBasePlayer::PlayerRunCommand(CUserCmd*, IMoveHelper*) from SDK Tools!");
	}

	DHookAddParam(g_playerruncommandhook, HookParamType_ObjectPtr); // CUserCmd*
	DHookAddParam(g_playerruncommandhook, HookParamType_ObjectPtr); // IMoveHelper*

	delete gd;
}

bool GetUserCommandOffsets()
{
	GameData gd = new GameData("bots_seed_fix.games");

	if (gd == null)
	{
		LogError("Failed to open gamedata file \"bots_seed_fix.games.txt\"!");
		return false;
	}

	g_offsetof_random_seed = gd.GetOffset("CUserCmd::random_seed");
	g_offsetof_server_random_seed = gd.GetOffset("CUserCmd::server_random_seed");

	delete gd;
	
	if (g_offsetof_random_seed == -1)
	{
		LogError("Failed to get offset of CUserCmd::random_seed from bots_seed_fix.games.txt");
	}

	if (g_offsetof_server_random_seed == -1)
	{
		LogError("Failed to get offset of CUserCmd::server_random_seed from bots_seed_fix.games.txt");
	}

	return g_offsetof_random_seed != -1 && g_offsetof_server_random_seed != -1;
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		g_playerruncommandhook.HookEntity(Hook_Pre, client, Hook_PlayerRunCommand_Pre);
		g_playerruncommandhook.HookEntity(Hook_Post, client, Hook_PlayerRunCommand_Post);
	}
}

MRESReturn Hook_PlayerRunCommand_Pre(Address pThis, DHookParam hParams)
{
	Address pUserCmd = DHookGetParamAddress(hParams, 1);
	Address addr_rnseed = pUserCmd + view_as<Address>(g_offsetof_random_seed);
	Address addr_svrnseed = pUserCmd + view_as<Address>(g_offsetof_server_random_seed);

	int random_seed = LoadFromAddress(addr_rnseed, NumberType_Int32);
	int server_random_seed = LoadFromAddress(addr_svrnseed, NumberType_Int32);

	// PrintToServer("[PRE] Random Seed: %i -- Server Random Seed: %i", random_seed, server_random_seed);

	if (random_seed == 0 || server_random_seed == 0)
	{
		int seed1 = GetRandomInt(0, 0x7fffffff);
		int seed2 = GetRandomInt(0, 0x7fffffff);
		StoreToAddress(addr_rnseed, view_as<any>(seed1), NumberType_Int32);
		StoreToAddress(addr_svrnseed, view_as<any>(seed2), NumberType_Int32);
	}

	return MRES_Ignored;
}

MRESReturn Hook_PlayerRunCommand_Post(Address pThis, DHookParam hParams)
{
	/*

	Address pUserCmd = DHookGetParamAddress(hParams, 1);
	Address addr_rnseed = pUserCmd + view_as<Address>(g_offsetof_random_seed);
	Address addr_svrnseed = pUserCmd + view_as<Address>(g_offsetof_server_random_seed);

	int random_seed = LoadFromAddress(addr_rnseed, NumberType_Int32);
	int server_random_seed = LoadFromAddress(addr_svrnseed, NumberType_Int32);

	PrintToServer("[POST] Random Seed: %i -- Server Random Seed: %i", random_seed, server_random_seed);

	*/

	return MRES_Ignored;
}