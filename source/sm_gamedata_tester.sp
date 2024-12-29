#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

int g_counter;
Handle g_hSDKCallGetEncryptionKey = null;

public Plugin myinfo =
{
	name = "Sourcemod First-Party Gamedata Tester",
	author = "caxanga334",
	description = "Tests first-party gamedata.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins/"
};


public void OnPluginStart()
{
	g_counter = 0;

	RegAdminCmd("sm_dev_fullammo", Command_FullAmmo, ADMFLAG_ROOT, "Tests giveammo gamedata.");
	RegAdminCmd("sm_dev_clienthooks", Command_ClientHooks, ADMFLAG_ROOT, "Test client hooks.");
	RegAdminCmd("sm_dev_report_engine", Command_ReportEngineVersion, ADMFLAG_ROOT, "Reports the engine version.");
	RegAdminCmd("sm_dev_fireoutput", Command_FireOutput, ADMFLAG_ROOT, "Test SDKTools FireOutput.");
	RegAdminCmd("sm_dev_findattachment", Command_LookUpAttachment, ADMFLAG_ROOT, "Test SDKTools LookUpEntityAttachment.");
	RegAdminCmd("sm_dev_test_gamerules_sdkcall", Command_GRSDKCall, ADMFLAG_ROOT, "Test SDKTools GameRules SDKCall.");
	RegAdminCmd("sm_dev_stripme", Command_StripMe, ADMFLAG_ROOT, "Removes your weapons.");
	RegAdminCmd("sm_dev_gimme", Command_Gimme, ADMFLAG_ROOT, "Gives you items.");
	RegAdminCmd("sm_dev_sdktools", Command_GenericSDKToolsTests, ADMFLAG_ROOT, "Generic SDKTools tests.");
	RegAdminCmd("sm_dev_burnme", Command_IgniteSelf, ADMFLAG_ROOT, "Test the ignite gamedata.");
}

void Hook_ClientSpawnPost(int entity)
{
	LogMessage("SpawnPost: %L", entity);
}

void Hook_ClientGroundEntChanged(int entity)
{
	int groundent = GetEntPropEnt(entity, Prop_Send, "m_hGroundEntity");
	PrintToChatAll("[%i]: Ground ent changed! <%i>", entity, groundent);
}

void Hook_WeaponEquipPost(int client, int weapon)
{
	PrintToChatAll("Weapon Equip %N %i", client, weapon);
}

void Hook_WeaponCanUse(int client, int weapon)
{
	PrintToChatAll("Weapon Can Use %N %i", client, weapon);
}

void Hook_WeaponSwitch(int client, int weapon)
{
	PrintToChatAll("Weapon Switch %N %i", client, weapon);
}

void Hook_WeaponCanSwitch(int client, int weapon)
{
	PrintToChatAll("Weapon Can Switch %N %i", client, weapon);
}

void Hook_ClientPreThink(int client)
{
	g_counter++;
	PrintToChatAll("Pre Think: %N", client);

	if (g_counter > 9)
	{
		SDKUnhook(client, SDKHook_PreThinkPost, Hook_ClientPreThink);
	}
}

void Hook_ClientPostThink(int client)
{
	g_counter++;
	PrintToChatAll("Post Think: %N", client);

	if (g_counter > 9)
	{
		SDKUnhook(client, SDKHook_PostThinkPost, Hook_ClientPostThink);
	}
}

void Hook_StartTouch(int entity, int other)
{
	PrintToChatAll("Start Touch: %N %i", entity, other);
}

void Hook_EndTouch(int entity, int other)
{
	PrintToChatAll("End Touch: %N %i", entity, other);
}

void Hook_Blocked(int entity, int other)
{
	PrintToChatAll("Blocked: %N %i", entity, other);
}

void Hook_TraceAttack(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
	PrintToChatAll("Trace Attack: victim %i attacker %i inflictor %i damage %f damagetype %i ammotype %i hitbox %i hitgroup %i ", victim, attacker, inflictor, damage, damagetype, ammotype, hitbox, hitgroup);
}

void Hook_TakeDamage(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	PrintToChatAll("Take Damage: victim %i attacker %i inflictor %i damage %f damagetype %i weapon %i", victim, attacker, inflictor, damage, damagetype, weapon);
}

void Hook_TakeDamageAlive(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	PrintToChatAll("Take Damage Alive: victim %i attacker %i inflictor %i damage %f damagetype %i weapon %i", victim, attacker, inflictor, damage, damagetype, weapon);
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	static bool ok = false;

	if (ok)
	{
		return;
	}

	if (IsClientInGame(client))
	{
		LogMessage("OnPlayerRunCmdPre %L", client);
		ok = true;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static bool ok = false;

	if (ok)
	{
		return Plugin_Continue;
	}

	if (IsClientInGame(client))
	{
		LogMessage("OnPlayerRunCmd %L", client);
		ok = true;
	}

	return Plugin_Continue;
}

Action Command_FullAmmo(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	int size = GetEntPropArraySize(client, Prop_Send, "m_iAmmo");

	for (int i = 0; i < size; i++)
	{
		GivePlayerAmmo(client, 255, i);
	}

	return Plugin_Handled;
}

Action Command_ClientHooks(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	g_counter = 0;
	SDKHook(client, SDKHook_SpawnPost, Hook_ClientSpawnPost);
	SDKHook(client, SDKHook_GroundEntChangedPost, Hook_ClientGroundEntChanged);
	SDKHook(client, SDKHook_WeaponCanUsePost, Hook_WeaponCanUse);
	SDKHook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);
	SDKHook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitch);
	SDKHook(client, SDKHook_WeaponCanSwitchToPost, Hook_WeaponCanSwitch);
	SDKHook(client, SDKHook_PreThinkPost, Hook_ClientPreThink);
	SDKHook(client, SDKHook_PostThinkPost, Hook_ClientPostThink);
	SDKHook(client, SDKHook_StartTouchPost, Hook_StartTouch);
	SDKHook(client, SDKHook_EndTouchPost, Hook_EndTouch);
	SDKHook(client, SDKHook_BlockedPost, Hook_Blocked);
	SDKHook(client, SDKHook_TraceAttackPost, Hook_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamagePost, Hook_TakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_TakeDamageAlive);

	return Plugin_Handled;
}

Action Command_ReportEngineVersion(int client, int args)
{
	EngineVersion ev = GetEngineVersion();
	
	switch (ev)
	{
		case Engine_Unknown:
		{
			ReplyToCommand(client, "Could not determine the engine version");
		}
		case Engine_Original:
		{
			ReplyToCommand(client, "Engine: Original Source Engine (used by The Ship)");
		}
		case Engine_SourceSDK2006:
		{
			ReplyToCommand(client, "Engine: Episode 1 Source Engine (second major SDK)");
		}
		case Engine_SourceSDK2007:
		{
			ReplyToCommand(client, "Engine: Orange Box Source Engine (third major SDK)");
		}
		case Engine_Left4Dead:
		{
			ReplyToCommand(client, "Engine: Left 4 Dead");
		}
		case Engine_DarkMessiah:
		{
			ReplyToCommand(client, "Engine: Dark Messiah Multiplayer");
		}
		case Engine_Left4Dead2:
		{
			ReplyToCommand(client, "Engine: Left 4 Dead 2");
		}
		case Engine_AlienSwarm:
		{
			ReplyToCommand(client, "Engine: Alien Swarm (and Alien Swarm SDK) ");
		}
		case Engine_BloodyGoodTime:
		{
			ReplyToCommand(client, "Engine: Bloody Good Time");
		}
		case Engine_EYE:
		{
			ReplyToCommand(client, "Engine: E.Y.E Divine Cybermancy");
		}
		case Engine_Portal2:
		{
			ReplyToCommand(client, "Engine: Portal 2");
		}
		case Engine_CSGO:
		{
			ReplyToCommand(client, "Engine: Counter-Strike: Global Offensive");
		}
		case Engine_CSS:
		{
			ReplyToCommand(client, "Engine: Counter-Strike: Source");
		}
		case Engine_DOTA:
		{
			ReplyToCommand(client, "Engine: DOTA 2");
		}
		case Engine_HL2DM:
		{
			ReplyToCommand(client, "Engine: Half-Life 2: Deathmatch");
		}
		case Engine_DODS:
		{
			ReplyToCommand(client, "Engine: Day of Defeat: Source");
		}
		case Engine_TF2:
		{
			ReplyToCommand(client, "Engine: Team Fortress 2");
		}
		case Engine_NuclearDawn:
		{
			ReplyToCommand(client, "Engine: Nuclear Dawn");
		}
		case Engine_SDK2013:
		{
			ReplyToCommand(client, "Engine: Source SDK 2013");
		}
		case Engine_Blade:
		{
			ReplyToCommand(client, "Engine: Blade Symphony");
		}
		case Engine_Insurgency:
		{
			ReplyToCommand(client, "Engine: Insurgency (2013 Retail version)");
		}
		case Engine_Contagion:
		{
			ReplyToCommand(client, "Engine: Contagion");
		}
		case Engine_BlackMesa:
		{
			ReplyToCommand(client, "Engine: Black Mesa Multiplayer");
		}
		case Engine_DOI:
		{
			ReplyToCommand(client, "Engine: Day of Infamy");
		}
#if SOURCEMOD_V_MINOR >= 12
		case Engine_PVKII:
		{
			ReplyToCommand(client, "Engine: Pirates, Vikings, and Knights II");
		}
		case Engine_MCV:
		{
			ReplyToCommand(client, "Engine: Military Conflict: Vietnam");
		}
#endif
		default:
		{
			ReplyToCommand(client, "Engine: Unknown (Out of Bounds)");
		}
	}

	return Plugin_Handled;
}

Action Command_FireOutput(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dev_fireoutput <target entity index> <output name>");
		return Plugin_Handled;
	}

	int entity = GetCmdArgInt(1);

	if (!IsValidEntity(entity))
	{
		ReplyToCommand(client, "Invalid entity %i", entity);
		return Plugin_Handled;
	}

	int caller = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			caller = i;
			break;
		}
	}

	char output[256];
	GetCmdArg(2, output, sizeof(output));

	FireEntityOutput(entity, output, caller);
	ReplyToCommand(client, "Fired output \"%s\"!", output);

	return Plugin_Handled;
}

Action Command_LookUpAttachment(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dev_findattachment <target entity index> <attachment name>");
		return Plugin_Handled;
	}

	int entity = GetCmdArgInt(1);

	if (!IsValidEntity(entity))
	{
		ReplyToCommand(client, "Invalid entity %i", entity);
		return Plugin_Handled;
	}

	char buffer[256];
	GetCmdArg(2, buffer, sizeof(buffer));

	int attachment = LookupEntityAttachment(entity, buffer);

	if (attachment == 0)
	{
		ReplyToCommand(client, "Failed to look up attachment or attachment is unused.");
	}
	else
	{
		ReplyToCommand(client, "Found attachment index %i", attachment);
	}

	return Plugin_Handled;
}

Action Command_GRSDKCall(int client, int args)
{
	if (g_hSDKCallGetEncryptionKey == null)
	{
		GameData gd = new GameData("sm-gamedata-tester.games");

		int offset = gd.GetOffset("CGameRules_GetDamageMultiplier");

		if (offset == -1)
		{
			LogError("Failed to get offset for CGameRules::GetDamageMultiplier from sm-gamedata-tester.games!");
			delete gd;
			return Plugin_Handled;
		}

		StartPrepSDKCall(SDKCall_GameRules);
		PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "CGameRules_GetDamageMultiplier");
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
		g_hSDKCallGetEncryptionKey = EndPrepSDKCall();

		if (g_hSDKCallGetEncryptionKey == null)
		{
			delete gd;
			ThrowError("Failed to setup SDK Call!");
		}

		delete gd;
	}

	float result = SDKCall(g_hSDKCallGetEncryptionKey);

	PrintToServer("SDKCall Result: %f", result);
	PrintToChatAll("SDKCall Result: %f", result);

	return Plugin_Handled;
}

Action Command_StripMe(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	for (int element = 0; element < size; element++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", element);

		if (IsValidEntity(weapon))
		{
			if (RemovePlayerItem(client, weapon))
			{
				char classname[64];
				GetEntityClassname(weapon, classname, sizeof(classname));

				ReplyToCommand(client, "Removing [%i]: %s", weapon, classname);
				RemoveEntity(weapon);
			}
			else
			{
				ReplyToCommand(client, "RemovePlayerItem failed for %i", weapon);
			}
		}
	}

	return Plugin_Handled;
}

Action Command_Gimme(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dev_gimme <classname>");
		return Plugin_Handled;
	}

	char classname[256];
	GetCmdArg(1, classname, sizeof(classname));

	int item = GivePlayerItem(client, classname);

	if (item == -1)
	{
		ReplyToCommand(client, "GivePlayerItem for \"%s\" failed.", classname);
	}
	else
	{
		ReplyToCommand(client, "GivePlayerItem ok!");
	}

	return Plugin_Handled;
}

Action Command_GenericSDKToolsTests(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	float eyeangles[3];

	if (GetClientEyeAngles(client, eyeangles))
	{
		ReplyToCommand(client, "Eye Angles: %f %f %f", eyeangles[0], eyeangles[1], eyeangles[2]);
	}
	else
	{
		ReplyToCommand(client, "Eye Angles failed!");
	}

	float pos[3];
	GetClientAbsOrigin(client, pos);

	if (GetRandomInt(0, 1) == 1)
	{
		pos[0] = pos[0] + 64.0;
	}
	else
	{
		pos[0] = pos[0] - 64.0;
	}

	if (GetRandomInt(0, 1) == 1)
	{
		pos[1] = pos[1] + 64.0;
	}
	else
	{
		pos[1] = pos[1] - 64.0;
	}

	if (GetRandomInt(0, 1) == 1)
	{
		pos[2] = pos[2] + 64.0;
	}
	else
	{
		pos[2] = pos[2] - 64.0;
	}

	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Handled;
}

void Timer_Extinguish(Handle timer, any data)
{
	int entity = EntRefToEntIndex(view_as<int>(data));

	if (IsValidEntity(entity))
	{
		ExtinguishEntity(entity);
		PrintToChatAll("ExtinguishEntity: %i", entity);
	}
}

Action Command_IgniteSelf(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}

	IgniteEntity(client, 10.0);

	CreateTimer(2.0, Timer_Extinguish, view_as<any>(EntIndexToEntRef(client)));

	ReplyToCommand(client, "Burning you!");

	return Plugin_Handled;
}

