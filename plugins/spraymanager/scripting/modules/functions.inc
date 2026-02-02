#define CHARSET "utf8mb4"
#define COLLATION "utf8mb4_unicode_ci"
#define MAX_SQL_QUERY_LENGTH 1024

enum
{
	AABBMinX = 0,
	AABBMaxX = 1,
	AABBMinY = 2,
	AABBMaxY = 3,
	AABBMinZ = 4,
	AABBMaxZ = 5,
	AABBTotalPoints = 6
}

GlobalForward g_hForward_OnClientSprayBanned;
GlobalForward g_hForward_OnClientSprayUnbanned;
GlobalForward g_hForward_OnClientSprayHashBanned;
GlobalForward g_hForward_OnClientSprayHashUnbanned;
GlobalForward g_hForward_OnClientSprayMarkedNSFW;
GlobalForward g_hForward_OnClientSprayMarkedSFW;

Handle g_hDatabase = null;
Handle g_hRoundEndTimer = null;
Handle g_hTopMenu = null;
Handle g_hWantsToSeeNSFWCookie = null;

ConVar g_cvarHookedDecalFrequency = null;
ConVar g_cvarDecalFrequency = null;
ConVar g_cvarUseProximityCheck = null;
ConVar g_cvarSendSpraysToConnectingClients = null;
ConVar g_cvarUsePersistentSprays = null;
ConVar g_cvarMaxSprayLifetime = null;
ConVar g_cvarEnableSprays = null;
ConVar g_cvarAuthorizedFlags = null;
ConVar g_cvarSprayBanLength = null;
ConVar g_cvarDefaultBehavior = null;
ConVar g_cvarFramesToSkip = null;

int g_iNSFWDecalIndex[3];
int g_iHiddenDecalIndex;
int g_iTransparentDecalIndex;
int g_iOldDecalFreqVal;
int g_iAllowSpray;
int g_iFramesToSkip;

bool g_bLoadedLate;
bool g_bSQLite;
bool g_bFullyConnected;
bool g_bSkipDecalHook;

char sAuthID[MAXPLAYERS + 1][64];
char sAuthID3[MAXPLAYERS + 1][32];
char g_sBanIssuer[MAXPLAYERS + 1][64];
char g_sBanIssuerSID[MAXPLAYERS + 1][32];
char g_sBanReason[MAXPLAYERS + 1][32];
char g_sSprayHash[MAXPLAYERS + 1][16];

// Add hash from others game later
char g_sDefaultGameHash[][] = { 
	"882ab71a" // Counter-Strike: Source
};

int g_iClientToClientSprayLifetime[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iClientSprayLifetime[MAXPLAYERS + 1] = { 2, ... };
int g_iSprayLifetime[MAXPLAYERS + 1];
int g_iSprayBanTimestamp[MAXPLAYERS + 1];
int g_iSprayUnbanTimestamp[MAXPLAYERS + 1] = { -1, ... };
int g_iSprayBanTarget[MAXPLAYERS + 1];
int g_iSprayUnbanTarget[MAXPLAYERS + 1];
int g_iSprayTraceTarget[MAXPLAYERS + 1];
int g_iBanTarget[MAXPLAYERS + 1];
int g_iDecalEntity[MAXPLAYERS + 1];
int g_iAuthorizedFlags[32] = { -1, ...};
int g_iSprayCheckAttempts[MAXPLAYERS + 1];

bool g_bEnableSprays = true;
bool g_bSprayCheckComplete[MAXPLAYERS + 1];
bool g_bWantsToSeeNSFWSprays[MAXPLAYERS + 1];
bool g_bHasNSFWSpray[MAXPLAYERS + 1];
bool g_bMarkedNSFWByAdmin[MAXPLAYERS + 1];
bool g_bSprayBanned[MAXPLAYERS + 1];
bool g_bSprayHashBanned[MAXPLAYERS + 1];
bool g_bInvokedThroughTopMenu[MAXPLAYERS + 1];
bool g_bInvokedThroughListMenu[MAXPLAYERS + 1];
bool g_bHasSprayHidden[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bSprayNotified[MAXPLAYERS + 1] = { false, ... };

float ACTUAL_NULL_VECTOR[3] = { 16384.0, ... }; //durr
float g_fNextSprayTime[MAXPLAYERS + 1];
float g_vecSprayOrigin[MAXPLAYERS + 1][3];
float g_SprayAABB[MAXPLAYERS + 1][AABBTotalPoints];

int g_iAdminFlags[6][2] = {
	{'b', ADMFLAG_GENERIC},
	{'o', ADMFLAG_CUSTOM1},
	{'p', ADMFLAG_CUSTOM2},
	{'h', ADMFLAG_CONVARS},
	{'m', ADMFLAG_RCON},
	{'z', ADMFLAG_ROOT}
};

stock int GetRandomNSFWDecalIndex()
{
	return g_iNSFWDecalIndex[GetRandomInt(0, 2)];
}

stock bool SprayClientDecalToAll(int client, int iEntity, const float vecOrigin[3])
{
	if (!IsValidClient(client))
		return false;

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nEntity", iEntity);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToAll();

	return true;
}

stock bool SprayClientDecalToSelected(int client, int iEntity, const float vecOrigin[3], int[] iClients, int iNumClients)
{
	if (!IsValidClient(client))
		return false;

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nEntity", iEntity);
	TE_WriteNum("m_nPlayer", client);
	TE_Send(iClients, iNumClients);

	return true;
}

stock bool SprayClientDecalToOne(int client, int target, int iEntity, const float vecOrigin[3])
{
	if (!IsValidClient(client))
		return false;

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nEntity", iEntity);
	TE_WriteNum("m_nPlayer", client);
	TE_SendToClient(target);

	return true;
}

stock void PaintWorldDecalToSelected(int iDecalIndex, const float vecOrigin[3], int[] iClients, int iNumClients)
{
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nIndex", iDecalIndex);
	TE_Send(iClients, iNumClients);
}

stock void PaintWorldDecalToOne(int iDecalIndex, const float vecOrigin[3], int target)
{
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nIndex", iDecalIndex);
	TE_SendToClient(target);
}

stock bool TracePlayerAngles(int client, float vecResult[3])
{
	if (!IsValidClient(client))
		return false;

	float vecEyeAngles[3];
	float vecEyeOrigin[3];

	GetClientEyeAngles(client, vecEyeAngles);
	GetClientEyePosition(client, vecEyeOrigin);

	g_iDecalEntity[client] = 0;

	Handle hTraceRay = TR_TraceRayFilterEx(vecEyeOrigin, vecEyeAngles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilter_FilterPlayers);

	if (TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(vecResult, hTraceRay);

		int iEntity;

		if ((iEntity = TR_GetEntityIndex(hTraceRay)) >= 0)
			g_iDecalEntity[client] = iEntity;

		delete hTraceRay;

		return true;
	}

	delete hTraceRay;

	return false;
}

stock bool TracePlayerAnglesRanged(int client, float fMaxDistance)
{
	if (!IsValidClient(client))
		return false;

	float vecEyeAngles[3];
	float vecEyeOrigin[3];
	float vecDirection[3];
	float vecEndPos[3];

	GetClientEyeAngles(client, vecEyeAngles);
	GetClientEyePosition(client, vecEyeOrigin);
	GetAngleVectors(vecEyeAngles, vecDirection, NULL_VECTOR, NULL_VECTOR);

	vecEndPos[0] = vecEyeOrigin[0] + (vecDirection[0] * fMaxDistance);
	vecEndPos[1] = vecEyeOrigin[1] + (vecDirection[1] * fMaxDistance);
	vecEndPos[2] = vecEyeOrigin[2] + (vecDirection[2] * fMaxDistance);

	g_iDecalEntity[client] = 0;

	Handle hTraceRay = TR_TraceRayFilterEx(vecEyeOrigin, vecEndPos, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilter_FilterPlayers);

	if (TR_DidHit(hTraceRay))
	{
		delete hTraceRay;

		return true;
	}

	delete hTraceRay;

	return false;
}

stock void UpdateClientToClientSprayLifeTime(int client, int iLifeTime)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iClientToClientSprayLifetime[i][client] = iLifeTime;
	}
}

stock void ResetClientToClientSprayLifeTime(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iClientToClientSprayLifetime[i][client] = 0;
		g_iClientToClientSprayLifetime[client][i] = 0;
	}
}

stock void ResetHiddenSprayArray(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bHasSprayHidden[i][client] = false;
		g_bHasSprayHidden[client][i] = false;
	}
}

stock void FormatRemainingTime(int iTimestamp, char[] sBuffer, int iBuffSize)
{
	if (iTimestamp == 0)
	{
		Format(sBuffer, iBuffSize, "Permanent");
		return;
	}

	if (iTimestamp < 0)
	{
		Format(sBuffer, iBuffSize, "Temporary");
		return;
	}

	int tstamp = (iTimestamp - GetTime());

	int days = (tstamp / 86400);
	int hours = ((tstamp / 3600) % 24);
	int minutes = ((tstamp / 60) % 60);
	int seconds = (tstamp % 60);

	if (tstamp > 86400)
	{
		Format(sBuffer, iBuffSize, "%d %s, %d %s, %d %s, %d %s", days, SingularOrMultiple(days) ? "Days" : "Day",
			hours, SingularOrMultiple(hours) ? "Hours" : "Hour", minutes, SingularOrMultiple(minutes) ? "Minutes" : "Minute",
			seconds, SingularOrMultiple(seconds)?"Seconds":"Second");
	}
	else if (tstamp > 3600)
	{
		Format(sBuffer, iBuffSize, "%d %s, %d %s, %d %s", hours, SingularOrMultiple(hours) ? "Hours" : "Hour",
			minutes, SingularOrMultiple(minutes) ? "Minutes" : "Minute", seconds, SingularOrMultiple(seconds) ? "Seconds" : "Second");
	}
	else if (tstamp > 60)
	{
		Format(sBuffer, iBuffSize, "%d %s, %d %s", minutes, SingularOrMultiple(minutes) ? "Minutes" : "Minute",
			seconds, SingularOrMultiple(seconds) ? "Seconds" : "Second");
	}
	else
		Format(sBuffer, iBuffSize, "%d %s", seconds, SingularOrMultiple(seconds) ? "Seconds":"Second");
}

stock bool IsPointInsideAABB(float vecPoint[3], float AABB[6])
{
	if (vecPoint[0] >= AABB[AABBMinX] && vecPoint[0] <= AABB[AABBMaxX] &&
		vecPoint[1] >= AABB[AABBMinY] && vecPoint[1] <= AABB[AABBMaxY] &&
		vecPoint[2] >= AABB[AABBMinZ] && vecPoint[2] <= AABB[AABBMaxZ])
	{
		return true;
	}

	return false;
}

stock bool CheckForAABBCollision(float AABB1[6], float AABB2[6])
{
	if (AABB1[AABBMinX] > AABB2[AABBMaxX]) return false;
	if (AABB1[AABBMinY] > AABB2[AABBMaxY]) return false;
	if (AABB1[AABBMinZ] > AABB2[AABBMaxZ]) return false;
	if (AABB1[AABBMaxX] < AABB2[AABBMinX]) return false;
	if (AABB1[AABBMaxY] < AABB2[AABBMinY]) return false;
	if (AABB1[AABBMaxZ] < AABB2[AABBMinZ]) return false;

	return true;
}

stock bool IsVectorZero(float vecPos[3])
{
	return ((vecPos[0] == 0.0) && (vecPos[1] == 0.0) && (vecPos[2] == 0.0));
}

stock bool SingularOrMultiple(int num)
{
	if (!num || num > 1)
		return true;

	return false;
}

stock bool TraceEntityFilter_FilterPlayers(int entity, int contentsMask)
{
	return entity > MaxClients;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return false;

	return IsClientAuthorized(client);
}

stock bool IsDefaultGameSprayHash(const char[] string)
{
	for (int i = 0; i < sizeof(g_sDefaultGameHash); i++)
	{
		if(StrContains(string, g_sDefaultGameHash[i], false) != -1)
			return true;
	}

	return false;
}