#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[HL1MP] General Fixes",
	author = "caxanga334",
	description = "Provides general bug fixes for HL1MP.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

Handle g_hSDKCallWorldSpaceCenter = null;

public void OnPluginStart()
{
	GameData gd = new GameData("hl1mpfixes.games");

	if (gd == null) { SetFailState("Failed to open hl1mpfixes.games.txt gamedata file!"); }

	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter")) { SetFailState("Failed to get offset for CBaseEntity::WorldSpaceCenter!"); }
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	g_hSDKCallWorldSpaceCenter = EndPrepSDKCall();

	if (g_hSDKCallWorldSpaceCenter == null) { SetFailState("Failed to setup SDKCall to CBaseEntity::WorldSpaceCenter!"); }

	delete gd;
}

public void OnMapStart()
{
	CreateTimer(2.0, Timer_DeleteDuplicateChargers, .flags = TIMER_FLAG_NO_MAPCHANGE);
}

void GetWorldSpaceCenter(int entity, float vec[3])
{
	SDKCall(g_hSDKCallWorldSpaceCenter, entity, vec);
}

int HashVector(float vec[3])
{
	const float cellSize = 16.0;

	// crappy vector to int hash
	int hash = 0;
	hash += RoundToFloor(vec[0] / cellSize);
	hash += RoundToFloor(vec[1] / cellSize);
	hash += RoundToFloor(vec[2] / cellSize);
	return hash;
}

void RemoveDuplicatedEntities(const char[] classname)
{
	IntMap map = new IntMap();
	int entity = INVALID_ENT_REFERENCE;
	while((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
	{
		float pos[3];
		GetWorldSpaceCenter(entity, pos);
		int hash = HashVector(pos);

		if (map.ContainsKey(hash))
		{
			RemoveEntity(entity);
		}
		else
		{
			map.SetValue(hash, 0);
			continue;
		}
	}

	delete map;
}

void Timer_DeleteDuplicateChargers(Handle timer)
{
	RemoveDuplicatedEntities("func_healthcharger");
	RemoveDuplicatedEntities("func_recharge");
}