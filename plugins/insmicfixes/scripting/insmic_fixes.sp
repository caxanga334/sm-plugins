#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[INSMIC] Bug Fixes",
	author = "caxanga334",
	description = "Provides general bug fixes for INSURGENCY: Modern Infantry Combat.",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins"
};

#define ENTITY_CACHE_SIZE 64

enum struct ObjectiveEntityCache
{
	int ref;
	int mapid;

	void Clear()
	{
		this.ref = INVALID_ENT_REFERENCE;
		this.mapid = -1;
	}

	void Assign(int entity)
	{
		this.ref = EntIndexToEntRef(entity);
		this.mapid = GetEntProp(entity, Prop_Data, "m_iID");
	}

	bool IsEmpty()
	{
		return this.ref == INVALID_ENT_REFERENCE;
	}

	bool IsEntity(int entity)
	{
		int other = EntRefToEntIndex(this.ref);
		if (other == INVALID_ENT_REFERENCE) { return false; }
		return other == entity;
	}

	bool IDMatches(int otherID)
	{
		return this.mapid == otherID;
	}
}

ObjectiveEntityCache g_objectiveCache[ENTITY_CACHE_SIZE];
int g_objectiveCount;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// CINSCombineBall only exists in Insurgency MIC
	if (FindSendPropInfo("CINSCombineBall", "m_flRadius") <= 0)
	{
		strcopy(error, err_max, "This plugin is for INSURGENCY: Modern Infantry Combat only!");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("round_reset", OnRoundResetPost, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	ClearCache();
	RequestFrame(BuildCache);
}

void OnRoundResetPost(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(CheckAndRemoveDuplicateObjectives);
}

void ClearCache()
{
	for (int i = 0; i < ENTITY_CACHE_SIZE; i++)
	{
		g_objectiveCache[i].Clear();
	}
}

void BuildCache()
{
	int entity = INVALID_ENT_REFERENCE;
	int c = 0;

	while ((entity = FindEntityByClassname(entity, "ins_objective")) != INVALID_ENT_REFERENCE)
	{
		g_objectiveCache[c].Assign(entity);
		c++;
	}

	g_objectiveCount = c;
}

void CheckAndRemoveDuplicateObjectives()
{
	int remove[512];
	int entity = INVALID_ENT_REFERENCE;
	int c = 0;

	while ((entity = FindEntityByClassname(entity, "ins_objective")) != INVALID_ENT_REFERENCE)
	{
		for (int i = 0; i < g_objectiveCount; i++)
		{
			if (!g_objectiveCache[i].IsEmpty())
			{
				// found in cache, ignore
				if (g_objectiveCache[i].IsEntity(entity))
				{
					break;
				}

				int id = GetEntProp(entity, Prop_Data, "m_iID");

				if (g_objectiveCache[i].IDMatches(id))
				{
					// duplicate objective found
					remove[c] = entity;
					c++;
					break;
				}
			}
		}
	}

	if (c > 0)
	{
		for (int i = 0; i < c; i++)
		{
			PrintToServer("[SM] Removing duplicate objective entity of index %i!", remove[i]);
			RemoveEntity(remove[i]);
		}
	}
}