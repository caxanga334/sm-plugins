#pragma semicolon 1

#include <SprayManager>
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#tryinclude <spray_exploit>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#pragma newdecls required

#include "modules/functions.inc"
#include "modules/module_api.inc"
#include "modules/module_commands.inc"
#include "modules/module_cvars.inc"
#include "modules/module_menu.inc"

public Plugin myinfo =
{
	name		= "Spray Manager",
	description	= "Help manage player sprays.",
	author		= "Obus, maxime1907, .Rushaway, caxanga334",
	version		= "3.3.1",
	url			= "https://github.com/caxanga334/sm-plugins"
}

public APLRes AskPluginLoad2(Handle hThis, bool bLate, char[] err, int iErrLen)
{
	CreateNatives();
	CreateForwards();

	RegPluginLibrary("spraymanager");
	g_bLoadedLate = bLate;

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	// NSFW
	AddFileToDownloadsTable("materials/spraymanager/nsfw_1.vtf");
	AddFileToDownloadsTable("materials/spraymanager/nsfw_1.vmt");
	AddFileToDownloadsTable("materials/spraymanager/nsfw_2.vtf");
	AddFileToDownloadsTable("materials/spraymanager/nsfw_2.vmt");
	AddFileToDownloadsTable("materials/spraymanager/nsfw_3.vtf");
	AddFileToDownloadsTable("materials/spraymanager/nsfw_3.vmt");

	// Un-Hide
	AddFileToDownloadsTable("materials/spraymanager/unhide.vtf");
	AddFileToDownloadsTable("materials/spraymanager/unhide.vmt");

	// Invisible spray
	AddFileToDownloadsTable("materials/spraymanager/transparent.vtf");
	AddFileToDownloadsTable("materials/spraymanager/transparent.vmt");

	RegisterCommands();

	g_hWantsToSeeNSFWCookie = RegClientCookie("spraymanager_wanttoseensfw", "Does this client want to see NSFW sprays?", CookieAccess_Private);

	AddTempEntHook("Player Decal", HookDecal);
	AddNormalSoundHook(HookSprayer);

	TopMenu hTopMenu;

	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(hTopMenu);

	CreateConVars();

	AutoExecConfig(true);

	GetConVars();

	if (g_bLoadedLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

			OnClientPutInServer(i);
			OnClientPostAdminCheck(i);
		}
	}

	InitializeSQL();

	HookGameEvents();
}

public void OnPluginEnd()
{
	RemoveAllSprays();

	RemoveTempEntHook("Player Decal", HookDecal);
	RemoveNormalSoundHook(HookSprayer);
	UnhookConVarChange(g_cvarHookedDecalFrequency, ConVarChanged_DecalFrequency);

	if (g_hDatabase != null)
		delete g_hDatabase;

	if (g_hRoundEndTimer != null)
		delete g_hRoundEndTimer;

	g_cvarHookedDecalFrequency.IntValue = g_iOldDecalFreqVal;
}

public void OnMapStart()
{
	g_iNSFWDecalIndex[0] = PrecacheDecal("spraymanager/nsfw_1.vtf", true);
	g_iNSFWDecalIndex[1] = PrecacheDecal("spraymanager/nsfw_2.vtf", true);
	g_iNSFWDecalIndex[2] = PrecacheDecal("spraymanager/nsfw_3.vtf", true);
	g_iHiddenDecalIndex = PrecacheDecal("spraymanager/unhide.vtf", true);
	g_iTransparentDecalIndex = PrecacheDecal("spraymanager/transparent.vtf", true);
}

public void OnMapEnd()
{
	if (g_hRoundEndTimer != null)
		delete g_hRoundEndTimer;
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;

	if (QueryClientConVar(client, "r_spray_lifetime", CvarQueryFinished_SprayLifeTime) == QUERYCOOKIE_FAILED)
		g_iClientSprayLifetime[client] = 2;
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;

	char sWantsToSeeNSFW[8];
	GetClientCookie(client, g_hWantsToSeeNSFWCookie, sWantsToSeeNSFW, sizeof(sWantsToSeeNSFW));

	g_bWantsToSeeNSFWSprays[client] = view_as<bool>(StringToInt(sWantsToSeeNSFW));
}

public void CvarQueryFinished_SprayLifeTime(QueryCookie cookie, int client, ConVarQueryResult res, const char[] sCvarName, const char[] sCvarVal)
{
	if (res != ConVarQuery_Okay)
	{
		g_iClientSprayLifetime[client] = 2;
		return;
	}

	int iVal = StringToInt(sCvarVal);

	g_iClientSprayLifetime[client] = iVal <= 0 ? 1 : iVal > 1000 ? 1000 : iVal;
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;

	ClearPlayerInfo(client);
	GetPlayerDecalFile(client, g_sSprayHash[client], sizeof(g_sSprayHash[]));
	if (AreClientCookiesCached(client))
		OnClientCookiesCached(client);
	UpdatePlayerInfo(client);
	g_bSprayCheckComplete[client] = false;
	UpdateSprayHashInfo(client);
	UpdateNSFWInfo(client);

	if (g_cvarSendSpraysToConnectingClients.BoolValue)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;

			if (IsVectorZero(g_vecSprayOrigin[i]))
				continue;

			if (g_bHasNSFWSpray[i] && !g_bWantsToSeeNSFWSprays[client])
			{
				PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[i], client);
				continue;
			}

			g_bSkipDecalHook = true;
			SprayClientDecalToOne(i, client, g_iDecalEntity[i], g_vecSprayOrigin[i]);
			g_iClientToClientSprayLifetime[client][i] = 0;
			g_bSkipDecalHook = false;
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;

			if (!g_bHasSprayHidden[i][client] && g_bWantsToSeeNSFWSprays[i])
				continue;

			PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[client], i);
		}

		g_bSkipDecalHook = true;
		SprayClientDecalToAll(client, 0, ACTUAL_NULL_VECTOR);
		g_bSkipDecalHook = false;
	}

	ClearPlayerInfo(client);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnRoundEnded(10.0);
}

void OnRoundEnded(float fDelay)
{
	if (g_cvarUsePersistentSprays.BoolValue)
	{
		g_hRoundEndTimer = CreateTimer(fDelay + 0.5, Timer_ProcessPersistentSprays, _, TIMER_FLAG_NO_MAPCHANGE);

		return;
	}

	g_hRoundEndTimer = CreateTimer(fDelay, Timer_ResetOldSprays, _, TIMER_FLAG_NO_MAPCHANGE);

	return;
}

public Action CS_OnTerminateRound(float &fDelay, CSRoundEndReason &reason)
{
	OnRoundEnded(fDelay);
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	if (!impulse || impulse != 201)
		return Plugin_Continue;

	if (!g_bEnableSprays)
	{
		CPrintToChat(client, "{green}[SprayManager] {white}Sorry, all sprays are currently disabled on the server.");
		return Plugin_Continue;
	}

	if (CheckCommandAccess(client, "sm_spray", ADMFLAG_GENERIC))
	{
		if (!g_bSprayBanned[client] && !g_bSprayHashBanned[client])
		{
			//if (IsPlayerAlive(client))
				//if (TracePlayerAnglesRanged(client, 128.0))
					//return Plugin_Continue;

			ForceSpray(client, client, false);
			g_fNextSprayTime[client] = 0.0;

			impulse = 0; //wow

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action HookDecal(const char[] sTEName, const int[] iClients, int iNumClients, float fSendDelay)
{
	if (!g_bEnableSprays)
		return Plugin_Stop;

	if (g_bSkipDecalHook)
		return Plugin_Continue;

	int client = TE_ReadNum("m_nPlayer");

	if (!IsValidClient(client))
	{
		if (g_iAllowSpray == client)
			g_iAllowSpray = 0;

		return Plugin_Handled;
	}

	if (!g_bSprayCheckComplete[client])
	{
		if (g_iSprayCheckAttempts[client] >= 5)
			CPrintToChat(client, "{green}[SprayManager]{default} An error occurred while checking your spray. Please wait next map.");
		else
			CPrintToChat(client, "{green}[SprayManager]{default} Your spray is currently being checked, please wait a few seconds.");
		return Plugin_Handled;
	}

	if (g_fNextSprayTime[client] > GetGameTime())
		return Plugin_Handled;

	if (g_bSprayHashBanned[client])
	{
		CPrintToChat(client, "{green}[SprayManager]{default} Your spray is blacklisted, change it.");
		return Plugin_Handled;
	}

	if (g_iSprayUnbanTimestamp[client] != 0 && g_iSprayUnbanTimestamp[client] != -1)
	{
		if (g_iSprayUnbanTimestamp[client] < GetTime())
			SprayUnbanClient(client);
	}

	if (g_bSprayBanned[client])
	{
		char sRemainingTime[512];
		FormatRemainingTime(g_iSprayUnbanTimestamp[client], sRemainingTime, sizeof(sRemainingTime));
		CPrintToChat(client, "{green}[SprayManager]{default} You are currently spray banned. ({green}%s{default})", sRemainingTime);
		return Plugin_Handled;
	}

	float vecOrigin[3];
	TE_ReadVector("m_vecOrigin", vecOrigin);

	float AABBTemp[AABBTotalPoints];

	AABBTemp[AABBMinX] = vecOrigin[0] - 32.0;
	AABBTemp[AABBMaxX] = vecOrigin[0] + 32.0;
	AABBTemp[AABBMinY] = vecOrigin[1] - 32.0;
	AABBTemp[AABBMaxY] = vecOrigin[1] + 32.0;
	AABBTemp[AABBMinZ] = vecOrigin[2] - 32.0;
	AABBTemp[AABBMaxZ] = vecOrigin[2] + 32.0;

	if (g_iAllowSpray != client)
	{
		if (!CheckCommandAccess(client, "sm_spray", ADMFLAG_GENERIC))
		{
			if (g_cvarUseProximityCheck.BoolValue)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsValidClient(i) || i == client)
						continue;

					if (IsVectorZero(g_vecSprayOrigin[i]))
						continue;

					if (!IsPointInsideAABB(vecOrigin, g_SprayAABB[i]) && !CheckForAABBCollision(AABBTemp, g_SprayAABB[i]))
						continue;

					if (CheckCommandAccess(i, "", ADMFLAG_CUSTOM1, true) || CheckCommandAccess(i, "sm_spray", ADMFLAG_GENERIC))
					{
						CPrintToChat(client, "{green}[SprayManager]{default} Your spray is too close to {green}%N{default}'s spray.", i);
						return Plugin_Handled;
					}
				}
			}

			if (CheckCommandAccess(client, "", ADMFLAG_CUSTOM1))
				g_fNextSprayTime[client] = GetGameTime() + (g_cvarDecalFrequency.FloatValue / 2);
			else
				g_fNextSprayTime[client] = GetGameTime() + g_cvarDecalFrequency.FloatValue;
		}
	}

	int iClientCount = GetClientCount(true);

	int[] iarrValidClients = new int[iClientCount];
	int[] iarrHiddenClients = new int[iClientCount];
	int[] iarrNoNSFWClients = new int[iClientCount];
	int iCurValidIdx;
	int iCurHiddenIdx;
	int iCurNoNSFWIdx;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (g_bHasSprayHidden[i][client])
		{
			iarrHiddenClients[iCurHiddenIdx] = i;
			iCurHiddenIdx++;
			continue;
		}

		if (g_bHasNSFWSpray[client] && !g_bWantsToSeeNSFWSprays[i])
		{
			iarrNoNSFWClients[iCurNoNSFWIdx] = i;
			iCurNoNSFWIdx++;
			continue;
		}

		iarrValidClients[iCurValidIdx] = i;
		iCurValidIdx++;
	}

	if (!IsVectorZero(g_vecSprayOrigin[client]))
	{
		PaintWorldDecalToSelected(g_iTransparentDecalIndex, g_vecSprayOrigin[client], iarrNoNSFWClients, iCurNoNSFWIdx);
		PaintWorldDecalToSelected(g_iTransparentDecalIndex, g_vecSprayOrigin[client], iarrHiddenClients, iCurHiddenIdx);
	}

	PaintWorldDecalToSelected(g_iHiddenDecalIndex, vecOrigin, iarrHiddenClients, iCurHiddenIdx);
	PaintWorldDecalToSelected(GetRandomNSFWDecalIndex(), vecOrigin, iarrNoNSFWClients, iCurNoNSFWIdx);

	g_bSkipDecalHook = true;
	SprayClientDecalToSelected(client, g_iDecalEntity[client], vecOrigin, iarrValidClients, iCurValidIdx);
	g_bSkipDecalHook = false;

	g_vecSprayOrigin[client] = vecOrigin;
	g_iAllowSpray = 0;
	g_iSprayLifetime[client] = 0;
	UpdateClientToClientSprayLifeTime(client, 0);
	g_SprayAABB[client] = AABBTemp;

	ArrayList PosArray = new ArrayList(3, 0);
	PosArray.PushArray(vecOrigin, 3);
	RequestFrame(FrameAfterSpray, PosArray);

	return Plugin_Handled;
}

public void FrameAfterSpray(ArrayList Data)
{
	float vecPos[3];
	Data.GetArray(0, vecPos, 3);

	EmitSoundToAll("player/sprayer.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, _, _, _, vecPos);

	delete Data;
}

public Action HookSprayer(int iClients[MAXPLAYERS], int &iNumClients, char sSoundName[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strcmp(sSoundName, "player/sprayer.wav") == 0 && iEntity > 0)
		return Plugin_Handled;

	return Plugin_Continue;
}

public void OnGameFrame()
{
	static int iFrame = 0;
	iFrame++;

	if (iFrame % g_iFramesToSkip != 0)
		return;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client))
			continue;

		PerformPlayerTraces(client);
	}

	iFrame = 0;
}

public void PerformPlayerTraces(int client)
{
	bool bLookingatSpray = false;
	float vecPos[3];

	if (!TracePlayerAngles(client, vecPos))
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (IsPointInsideAABB(vecPos, g_SprayAABB[i]))
		{
			PrintHintText(client, "Sprayed by: %N (%s) [%s]", i, sAuthID3[i], g_bHasNSFWSpray[i] ? "NSFW" : "SFW");
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");

			g_bSprayNotified[client] = true;
			bLookingatSpray = true;

			break;
		}
	}

	if (!bLookingatSpray && g_bSprayNotified[client])
	{
		PrintHintText(client, "");
		StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
		g_bSprayNotified[client] = false;
	}
}

public Action Timer_ProcessPersistentSprays(Handle hThis)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		for (int x = 1; x <= MaxClients; x++)
		{
			if (!IsValidClient(x))
				continue;

			if (!IsVectorZero(g_vecSprayOrigin[x]))
				g_iClientToClientSprayLifetime[i][x]++;

			bool bDoNotSpray;

			if (g_bHasSprayHidden[i][x])
			{
				PaintWorldDecalToOne(g_iHiddenDecalIndex, g_vecSprayOrigin[x], i);
				bDoNotSpray = true;
			}

			if (!g_bWantsToSeeNSFWSprays[i] && g_bHasNSFWSpray[x] && !bDoNotSpray)
			{
				PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[x], i);
				bDoNotSpray = true;
			}

			if (g_iClientToClientSprayLifetime[i][x] >= g_iClientSprayLifetime[i] && !bDoNotSpray)
			{
				g_bSkipDecalHook = true;
				SprayClientDecalToOne(x, i, g_iDecalEntity[x], g_vecSprayOrigin[x]);
				g_iClientToClientSprayLifetime[i][x] = 0;
				g_bSkipDecalHook = false;
			}

			break;
		}
	}

	g_hRoundEndTimer = null;
	return Plugin_Continue;
}

public Action Timer_ResetOldSprays(Handle hThis)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (!IsVectorZero(g_vecSprayOrigin[i]))
			g_iSprayLifetime[i]++;

		if (g_iSprayLifetime[i] >= g_cvarMaxSprayLifetime.IntValue)
		{
			g_iAllowSpray = i;
			SprayClientDecalToAll(i, 0, ACTUAL_NULL_VECTOR);
			g_iSprayLifetime[i] = 0;
		}
		else
		{
			for (int x = 1; x <= MaxClients; x++)
			{
				if (!IsValidClient(x))
					continue;

				if (g_bHasSprayHidden[x][i])
				{
					PaintWorldDecalToOne(g_iHiddenDecalIndex, g_vecSprayOrigin[i], x);
					continue;
				}

				if (!g_bWantsToSeeNSFWSprays[x] && g_bHasNSFWSpray[i])
					PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[i], x);
			}
		}
	}

	g_hRoundEndTimer = null;
	return Plugin_Continue;
}

void InitializeSQL()
{
	if (g_hDatabase != null)
		delete g_hDatabase;

	g_bFullyConnected = false;

	if (SQL_CheckConfig("spraymanager"))
		SQL_TConnect(OnSQLConnected, "spraymanager");
	else
		SetFailState("Could not find \"spraymanager\" entry in databases.cfg.");
}

void HookGameEvents()
{
	/* TF2 or TF2 based mods */
	if (FindSendPropInfo("CTFPlayer", "m_vecOrigin") > 0)
	{
		HookEvent("teamplay_round_win", Event_RoundEnd);
	}
	else if (FindSendPropInfo("CDODPlayer", "m_vecOrigin") > 0)
	{
		HookEvent("dod_round_win", Event_RoundEnd);
	}
}

Transaction CreateTablesTransaction()
{
	Transaction T_CreateTables = SQL_CreateTransaction();

	if (!g_bSQLite)
	{
		char sQuery[MAX_SQL_QUERY_LENGTH];
		Format(sQuery, sizeof(sQuery), "SET NAMES \"%s\"", CHARSET);
		T_CreateTables.AddQuery(sQuery);

		Format(sQuery, sizeof(sQuery),"CREATE TABLE IF NOT EXISTS `spraymanager` (`steamid` VARCHAR(32) NOT NULL, `name` VARCHAR(32) NOT NULL, `unbantime` INT, `issuersteamid` VARCHAR(32), `issuername` VARCHAR(32) NOT NULL, `issuedtime` INT, `issuedreason` VARCHAR(64) NOT NULL, PRIMARY KEY(steamid)) CHARACTER SET %s COLLATE %s;", CHARSET, COLLATION);
		T_CreateTables.AddQuery(sQuery);

		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `sprayblacklist` (`sprayhash` VARCHAR(16) NOT NULL, `sprayer` VARCHAR(32) NOT NULL, `sprayersteamid` VARCHAR(32) NOT NULL, PRIMARY KEY(sprayhash)) CHARACTER SET %s COLLATE %s;", CHARSET, COLLATION);
		T_CreateTables.AddQuery(sQuery);

		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `spraynsfwlist` (`sprayhash` VARCHAR(16) NOT NULL, `sprayersteamid` VARCHAR(32), `setbyadmin` TINYINT, PRIMARY KEY(sprayhash)) CHARACTER SET %s COLLATE %s;", CHARSET, COLLATION);
		T_CreateTables.AddQuery(sQuery);
	}
	else
	{
		T_CreateTables.AddQuery("CREATE TABLE IF NOT EXISTS `spraymanager` (`steamid` TEXT NOT NULL, `name` TEXT DEFAULT 'unknown', `unbantime` INTEGER, `issuersteamid` TEXT, `issuername` TEXT DEFAULT 'unknown', `issuedtime` INTEGER NOT NULL, `issuedreason` TEXT DEFAULT 'none', PRIMARY KEY(steamid));");
		T_CreateTables.AddQuery("CREATE TABLE IF NOT EXISTS `sprayblacklist` (`sprayhash` TEXT NOT NULL, `sprayer` TEXT DEFAULT 'unknown', `sprayersteamid` TEXT, PRIMARY KEY(sprayhash));");
		T_CreateTables.AddQuery("CREATE TABLE IF NOT EXISTS `spraynsfwlist` (`sprayhash` TEXT NOT NULL, `sprayersteamid` TEXT, `setbyadmin` INTEGER, PRIMARY KEY(sprayhash));");
	}

	return T_CreateTables;
}

public void OnSQLConnected(Handle hParent, Handle hChild, const char[] err, any data)
{
	if (hChild == null || hParent == null || err[0])
	{
		LogError("Failed to connect to database, retrying in 10 seconds. (%s)", err);
		CreateTimer(10.0, ReconnectSQL, _, TIMER_FLAG_NO_MAPCHANGE);
		g_bFullyConnected = false;

		return;
	}

	char sDriver[16];
	g_hDatabase = CloneHandle(hChild);
	SQL_GetDriverIdent(hParent, sDriver, sizeof(sDriver));

	if (!strncmp(sDriver, "my", 2, false))
		g_bSQLite = false;
	else
		g_bSQLite = true;

	Transaction T_CreateTables = CreateTablesTransaction();
	SQL_ExecuteTransaction(g_hDatabase, T_CreateTables, OnSQLCreateTables_Success, OnSQLCreateTables_Error, _, DBPrio_High);
}

public void OnSQLCreateTables_Success(Database db, any data, int numQueries, Handle[] results, any[] queryData)
{
	if (g_bLoadedLate)
		CreateTimer(2.5, RetryUpdatingPlayerInfo, _, TIMER_FLAG_NO_MAPCHANGE);

	LogMessage("Successfully connected to %s database!", g_bSQLite ? "SQLite" : "mySQL");
	g_bFullyConnected = true;
}

public void OnSQLCreateTables_Error(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Database error while creating tables, retrying in 10 seconds. (%s)", error);
	CreateTimer(10.0, RetryTableCreation, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action RetryTableCreation(Handle hTimer)
{
	if (g_hDatabase == null)
		return Plugin_Handled;

	Transaction T_CreateTables = CreateTablesTransaction();
	SQL_ExecuteTransaction(g_hDatabase, T_CreateTables, OnSQLCreateTables_Success, OnSQLCreateTables_Error, _, DBPrio_High);
	return Plugin_Handled;
}

public Action ReconnectSQL(Handle hTimer)
{
	InitializeSQL();

	return Plugin_Handled;
}

public Action RetryUpdatingPlayerInfo(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		OnClientPostAdminCheck(i);
	}
	return Plugin_Continue;
}

public void RemoveAllSprays()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (IsVectorZero(g_vecSprayOrigin[i]))
			continue;

		g_iAllowSpray = i;
		SprayClientDecalToAll(i, 0, ACTUAL_NULL_VECTOR);
	}
}

bool SprayBanClient(int client, int target, int iBanLength, const char[] sReason)
{
	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Database is not connected.");
		return false;
	}

	if (!IsValidClient(target))
	{
		ReplyToCommand(client, "[SprayManager] Target is no longer valid.");
		return false;
	}

	if (g_bSprayBanned[target])
	{
		CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}is already spray banned.", target);
		return false;
	}

	int iTime = GetTime();
	int iDefaultBanLength = g_cvarSprayBanLength.IntValue;

	if (iDefaultBanLength < 0)
		iDefaultBanLength = 0;

	char sQuery[512];
	char sAdminName[64];
	char sTargetName[64];
	char sAdminSteamID[32];

	if (client != 0)
		GetClientName(client, sAdminName, sizeof(sAdminName));
	else
		Format(sAdminName, sizeof(sAdminName), "Console");

	GetClientName(target, sTargetName, sizeof(sTargetName));

	if (client != 0)
		Format(sAdminSteamID, sizeof(sAdminSteamID), "%s", sAuthID[client]);
	else
		Format(sAdminSteamID, sizeof(sAdminSteamID), "STEAM_ID_SERVER");

	char[] sSafeAdminName = new char[2 * strlen(sAdminName) + 1];
	char[] sSafeTargetName = new char[2 * strlen(sTargetName) + 1];
	char[] sSafeReason = new char[2 * strlen(sReason) + 1];
	SQL_EscapeString(g_hDatabase, sAdminName, sSafeAdminName, 2 * strlen(sAdminName) + 1);
	SQL_EscapeString(g_hDatabase, sTargetName, sSafeTargetName, 2 * strlen(sTargetName) + 1);
	SQL_EscapeString(g_hDatabase, sReason, sSafeReason, 2 * strlen(sReason) + 1);

	if (g_bSQLite)
	{
		FormatEx(
			sQuery,
			sizeof(sQuery),
			"INSERT OR REPLACE INTO `spraymanager` (`steamid`, `name`, `unbantime`, `issuersteamid`, `issuername`, `issuedtime`, `issuedreason`) VALUES ('%s', '%s', '%d', '%s', '%s', '%d', '%s');",
			sAuthID[target], sSafeTargetName, iBanLength ? (iTime + (iBanLength * 60)) : (iDefaultBanLength * 60), sAdminSteamID, sSafeAdminName, iTime, strlen(sSafeReason) > 1 ? sSafeReason : "none"
		);
	}
	else
	{
		FormatEx(
			sQuery,
			sizeof(sQuery),
			"INSERT INTO `spraymanager` (`steamid`, `name`, `unbantime`, `issuersteamid`, `issuername`, `issuedtime`, `issuedreason`) VALUES ('%s', '%s', '%d', '%s', '%s', '%d', '%s') \
			ON DUPLICATE KEY UPDATE `name` = '%s', `unbantime` = '%d', `issuersteamid` = '%s', `issuername` = '%s', `issuedtime` = '%d', `issuedreason` = '%s';",
			sAuthID[target], sSafeTargetName, iBanLength ? (iTime + (iBanLength * 60)) : (iDefaultBanLength * 60), sAdminSteamID, sSafeAdminName, iTime, strlen(sSafeReason) > 1 ? sSafeReason : "none",
			sSafeTargetName, iBanLength ? (iTime + (iBanLength * 60)) : 0, sAdminSteamID, sSafeAdminName, iTime, strlen(sSafeReason) > 1 ? sSafeReason : "none"
		);
	}

	SQL_TQuery(g_hDatabase, DummyCallback, sQuery);

	strcopy(g_sBanIssuer[target], sizeof(g_sBanIssuer[]), sAdminName);
	strcopy(g_sBanIssuerSID[target], sizeof(g_sBanIssuerSID[]), sAdminSteamID);
	strcopy(g_sBanReason[target], sizeof(g_sBanReason[]), strlen(sReason) ? sReason : "none");
	g_bSprayBanned[target] = true;
	g_iSprayBanTimestamp[target] = iTime;
	g_iSprayUnbanTimestamp[target] = iBanLength ? (iTime + (iBanLength * 60)) : 0;
	g_fNextSprayTime[target] = 0.0;

	g_iAllowSpray = target;
	SprayClientDecalToAll(target, 0, ACTUAL_NULL_VECTOR);
	Call_OnClientSprayBanned(client, target, iBanLength, sReason);

	return true;
}

bool SprayUnbanClient(int target, int client=-1)
{
	if (g_hDatabase == null || !g_bFullyConnected)
	{
		if (client != -1)
			CReplyToCommand(client, "{green}[SprayManager]{default} Database is not connected.");
		return false;
	}

	if (!IsValidClient(target))
	{
		if (client != -1)
			CReplyToCommand(client, "{green}[SprayManager]{default} Target is no longer valid.");
		return false;
	}

	if (!g_bSprayBanned[target])
	{
		if (client != -1)
			CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}is not spray banned.", target);
		return false;
	}

	char sQuery[128];
	Format(sQuery, sizeof(sQuery), "DELETE FROM `spraymanager` WHERE steamid = '%s';", sAuthID[target]);

	SQL_TQuery(g_hDatabase, DummyCallback, sQuery);

	strcopy(g_sBanIssuer[target], sizeof(g_sBanIssuer[]), "");
	strcopy(g_sBanIssuerSID[target], sizeof(g_sBanIssuerSID[]), "");
	strcopy(g_sBanReason[target], sizeof(g_sBanReason[]), "");
	g_bSprayBanned[target] = false;
	g_iSprayLifetime[target] = 0;
	UpdateClientToClientSprayLifeTime(target, 0);
	g_iSprayBanTimestamp[target] = 0;
	g_iSprayUnbanTimestamp[target] = -1;
	g_fNextSprayTime[target] = 0.0;
	Call_OnClientSprayUnbanned(client, target);

	return true;
}

bool BanClientSpray(int client, int target)
{
	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Database is not connected.");
		return false;
	}

	if (!IsValidClient(target))
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Target is no longer valid.");
		return false;
	}

	if (!g_sSprayHash[target][0])
	{
		CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}does not have a valid spray hash.", target);
		return false;
	}

	if (g_bSprayHashBanned[target])
	{
		CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}is already hash banned.", target);
		return false;
	}

	if (IsDefaultGameSprayHash(g_sSprayHash[target]))
	{
		CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}has a default game spray.", target);
		return false;
	}

	char sQuery[256];
	char sTargetName[64];

	GetClientName(target, sTargetName, sizeof(sTargetName));

	char[] sSafeTargetName = new char[2 * strlen(sTargetName) + 1];
	SQL_EscapeString(g_hDatabase, sTargetName, sSafeTargetName, 2 * strlen(sTargetName) + 1);

	if (g_bSQLite)
	{
		FormatEx(
			sQuery,
			sizeof(sQuery),
			"INSERT OR REPLACE INTO `sprayblacklist` (`sprayhash`, `sprayer`, `sprayersteamid`) VALUES ('%s', '%s', '%s');",
			g_sSprayHash[target], sSafeTargetName, sAuthID[target]
		);
	}
	else
	{
		FormatEx(
			sQuery,
			sizeof(sQuery),
			"INSERT INTO `sprayblacklist` (`sprayhash`, `sprayer`, `sprayersteamid`) VALUES ('%s', '%s', '%s') \
			ON DUPLICATE KEY UPDATE `sprayer` = '%s', `sprayersteamid` = '%s';",
			g_sSprayHash[target], sSafeTargetName, sAuthID[target],
			sSafeTargetName, sAuthID[target]
		);
	}

	SQL_TQuery(g_hDatabase, DummyCallback, sQuery);

	g_bSprayHashBanned[target] = true;

	g_iAllowSpray = target;
	SprayClientDecalToAll(target, 0, ACTUAL_NULL_VECTOR);
	Call_OnClientSprayHashBanned(client, target);

	return true;
}

bool UnbanClientSpray(int client, int target)
{
	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Database is not connected.");
		return false;
	}

	if (!IsValidClient(target))
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Target is no longer valid.");
		return false;
	}

	if (!g_bSprayHashBanned[target])
	{
		CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}is not hash banned.", target);
		return false;
	}

	char sQuery[128];
	Format(sQuery, sizeof(sQuery), "DELETE FROM `sprayblacklist` WHERE `sprayhash` = '%s';", g_sSprayHash[target]);

	SQL_TQuery(g_hDatabase, DummyCallback, sQuery);

	g_bSprayHashBanned[target] = false;
	Call_OnClientSprayHashUnbanned(client, target);

	return true;
}

bool AdminForceSprayNSFW(int client, int target)
{
	if (!IsValidClient(target))
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Target is no longer valid.");
		return false;
	}

	if (IsDefaultGameSprayHash(g_sSprayHash[target]))
	{
		CReplyToCommand(client, "{green}[SprayManager]{olive} %N {default}has a default game spray.", target);
		return false;
	}

	DB_UpdateSprayNSFWStatus(target, true);

	g_bHasNSFWSpray[target] = true;
	g_bMarkedNSFWByAdmin[target] = true;

	UpdateSprayVisibilityForAllClients(target);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		for (int x = 1; x <= MaxClients; x++)
		{
			if (!IsValidClient(x))
				continue;

			if (g_bHasSprayHidden[i][x])
				continue;

			if (g_bWantsToSeeNSFWSprays[i])
				continue;

			PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[x], i);
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(x, i, 0, ACTUAL_NULL_VECTOR);
			g_bSkipDecalHook = false;
			break;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} Marked {green}%N{default}'s spray as NSFW.", target);
	LogAction(client, target, "[SprayManager] %L Marked %L spray as NSFW.", client, target);
	NotifyAdmins(client, target, "{default}spray was marked as {green}NSFW");

	return true;
}

void AdminForceSpraySFW(int admin, int target)
{
	DB_DeleteSprayNSFWStatus(target);

	g_bHasNSFWSpray[target] = false;
	g_bMarkedNSFWByAdmin[target] = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		for (int x = 1; x <= MaxClients; x++)
		{
			if (!IsValidClient(x))
				continue;

			if (g_bHasSprayHidden[i][x])
				continue;

			PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[x], i);
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(x, i, g_iDecalEntity[x], g_vecSprayOrigin[x]);
			g_iClientToClientSprayLifetime[i][x] = 0;
			g_bSkipDecalHook = false;
			break;
		}
	}
	Call_OnClientSprayMarkedSFW(admin, target);
}

void UpdatePlayerInfo(int client)
{
	if (!IsValidClient(client))
		return;

	if (g_cvarDefaultBehavior.IntValue != 1)
	{
		// We consider client as banned by default, so we can check if the player is banned or not.
		// This is a safety measure to prevent any client to use spray exploit if the database is not connected.
		// On the next queries, we will update the client's information.

		g_bSprayBanned[client] = true;
		g_bSprayHashBanned[client] = true;
		g_iSprayUnbanTimestamp[client] = -1;
		g_iSprayBanTimestamp[client] = -1;
		strcopy(g_sBanIssuerSID[client], sizeof(g_sBanIssuerSID[]), "Console");
		strcopy(g_sBanIssuer[client], sizeof(g_sBanIssuer[]), "Server");
		strcopy(g_sBanReason[client], sizeof(g_sBanReason[]), "Retrieving data, please wait");
	}

	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID), false);
	FormatEx(sAuthID[client], sizeof(sAuthID[]), "%s", sSteamID);

	GetClientAuthId(client, AuthId_Steam3, sSteamID, sizeof(sSteamID), false);
	ReplaceString(sSteamID, sizeof(sSteamID), "[", "", false);
	ReplaceString(sSteamID, sizeof(sSteamID), "]", "", false);
	FormatEx(sAuthID3[client], sizeof(sAuthID3[]), "%s", sSteamID);

	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CreateTimer(10.0, RetryPlayerInfoUpdate, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT `unbantime`, `issuersteamid`, `issuername`, `issuedtime`, `issuedreason` FROM `spraymanager` WHERE `steamid` = '%s';", sAuthID[client]);

	SQL_TQuery(g_hDatabase, OnSQLCheckBanQuery, sQuery, client, DBPrio_High);
}

void UpdateSprayHashInfo(int client)
{
	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CreateTimer(10.0, RetrySprayHashUpdate, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (!IsValidClient(client))
		return;

	char sSprayQuery[128];
	Format(sSprayQuery, sizeof(sSprayQuery), "SELECT 1 FROM `sprayblacklist` WHERE `sprayhash` = '%s' LIMIT 1;", g_sSprayHash[client]);

	SQL_TQuery(g_hDatabase, OnSQLCheckSprayHashBanQuery, sSprayQuery, client, DBPrio_Normal);
}

void UpdateNSFWInfo(int client)
{
	if (g_hDatabase == null || !g_bFullyConnected)
		return;

	if (!IsValidClient(client))
		return;

	char sSprayQuery[128];
	Format(sSprayQuery, sizeof(sSprayQuery), "SELECT `setbyadmin` FROM `spraynsfwlist` WHERE `sprayhash` = '%s';", g_sSprayHash[client]);

	SQL_TQuery(g_hDatabase, OnSQLCheckNSFWSprayHashQuery, sSprayQuery, client);
}

void NotifyAdmins(int iParam1, int target, const char[] sReason)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "sm_spray", ADMFLAG_GENERIC))
			CPrintToChat(i, "{green}[SM]{olive} %N %s {default}by {olive}%N{default}.", target, sReason, iParam1);
	}
}

public void DummyCallback(Handle hOwner, Handle hChild, const char[] err, any data)
{
	if (hOwner == null || hChild == null)
		LogError("Query error. (%s)", err);
}

public void OnSQLCheckBanQuery(Handle hParent, Handle hChild, const char[] err, any client)
{
	if (!IsValidClient(client))
		return;

	if (hChild == null || hParent == null || err[0])
	{
		LogError("An error occurred while querying the database for a user ban, retrying in 10 seconds. (%s)", err);
		CreateTimer(10.0, RetryPlayerInfoUpdate, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (SQL_FetchRow(hChild))
	{
		g_bSprayBanned[client] = true;

		g_iSprayUnbanTimestamp[client] = SQL_FetchInt(hChild, 0);
		SQL_FetchString(hChild, 1, g_sBanIssuerSID[client], sizeof(g_sBanIssuerSID[]));
		SQL_FetchString(hChild, 2, g_sBanIssuer[client], sizeof(g_sBanIssuer[]));
		g_iSprayBanTimestamp[client] = SQL_FetchInt(hChild, 3);
		SQL_FetchString(hChild, 4, g_sBanReason[client], sizeof(g_sBanReason[]));
	}
	else
	{
		g_bSprayBanned[client] = false;
		g_iSprayUnbanTimestamp[client] = -1;
		g_iSprayBanTimestamp[client] = -1;
		strcopy(g_sBanIssuerSID[client], sizeof(g_sBanIssuerSID[]), "");
		strcopy(g_sBanIssuer[client], sizeof(g_sBanIssuer[]), "");
		strcopy(g_sBanReason[client], sizeof(g_sBanReason[]), "");
	}
}

public void OnSQLCheckSprayHashBanQuery(Handle hParent, Handle hChild, const char[] err, any client)
{
	if (!IsValidClient(client))
		return;

	if (hChild == null || hParent == null || err[0])
	{
		g_iSprayCheckAttempts[client]++;
		LogError("An error occurred while querying the database for a spray ban, retrying in 10 seconds. (%s)", err);
		CreateTimer(10.0, RetrySprayHashUpdate, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	g_bSprayHashBanned[client] = SQL_FetchRow(hChild);
	g_bSprayCheckComplete[client] = true;
	g_iSprayCheckAttempts[client] = 0;
}

public void OnSQLCheckNSFWSprayHashQuery(Handle hParent, Handle hChild, const char[] err, any client)
{
	if (!IsValidClient(client))
		return;

	if (hChild == null || hParent == null || err[0])
	{
		LogError("An error occurred while querying the NSFW database for a spray, retrying in 10 seconds. (%s)", err);
		CreateTimer(10.0, RetryNSFWSprayLookup, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (SQL_FetchRow(hChild))
	{
		g_bHasNSFWSpray[client] = true;

		char sSetByAdmin[8];
		SQL_FetchString(hChild, 0, sSetByAdmin, sizeof(sSetByAdmin));

		g_bMarkedNSFWByAdmin[client] = view_as<bool>(StringToInt(sSetByAdmin));
	}
}

public Action RetryPlayerInfoUpdate(Handle timer, any serialClient)
{
	int client = GetClientFromSerial(serialClient);
	if (client == 0 || IsFakeClient(client))
		return Plugin_Stop;

	UpdatePlayerInfo(client);
	return Plugin_Stop;
}

public Action RetrySprayHashUpdate(Handle timer, any serialClient)
{
	int client = GetClientFromSerial(serialClient);
	if (client == 0 || IsFakeClient(client))
		return Plugin_Stop;

	UpdateSprayHashInfo(client);
	return Plugin_Stop;
}

public Action RetryNSFWSprayLookup(Handle timer, any serialClient)
{
	int client = GetClientFromSerial(serialClient);
	if (client == 0 || IsFakeClient(client))
		return Plugin_Stop;

	UpdateNSFWInfo(client);
	return Plugin_Stop;
}

stock bool ForceSpray(int client, int target, bool bPlaySound=true)
{
	if (!IsValidClient(target))
		return false;

	if (!g_bEnableSprays)
	{
		bool bAuthorized = false;
		for (int i = 0; i < sizeof(g_iAuthorizedFlags); i++)
		{
			for (int j = 0; j < sizeof(g_iAdminFlags); j++)
			{
				if (g_iAuthorizedFlags[i] == g_iAdminFlags[j][0] && (GetUserFlagBits(client) & (g_iAdminFlags[j][1]) == (g_iAdminFlags[j][1])))
				{
					bAuthorized = true;
					break;
				}
			}
			if (bAuthorized || g_iAuthorizedFlags[i] == -1)
				break;
		}
		if (!bAuthorized)
		{
			CPrintToChat(client, "{green}[SprayManager] {white}Sorry, all sprays are currently disabled on the server.");
			return false;
		}
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		SprayClientDecalToAll(target, g_iDecalEntity[client], vecEndPos);

		if (bPlaySound)
			EmitSoundToAll("player/sprayer.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, _, _, _, vecEndPos);

		return true;
	}

	CPrintToChat(client, "{green}[SprayManager]{default} Could not spray here, try somewhere else.");

	return false;
}

stock void ClearPlayerInfo(int client)
{
	strcopy(g_sBanIssuer[client], sizeof(g_sBanIssuer[]), "");
	strcopy(g_sBanIssuerSID[client], sizeof(g_sBanIssuerSID[]), "");
	strcopy(g_sBanReason[client], sizeof(g_sBanReason[]), "");
	strcopy(g_sSprayHash[client], sizeof(g_sSprayHash[]), "");
	strcopy(sAuthID[client], sizeof(sAuthID[]), "");
	strcopy(sAuthID3[client], sizeof(sAuthID3[]), "");
	g_bSprayBanned[client] = false;
	g_bSprayHashBanned[client] = false;
	g_bSprayCheckComplete[client] = false;
	g_iClientSprayLifetime[client] = 2;
	g_iSprayLifetime[client] = 0;
	ResetClientToClientSprayLifeTime(client);
	ResetHiddenSprayArray(client);
	g_iDecalEntity[client] = 0;
	g_iSprayBanTimestamp[client] = 0;
	g_iSprayUnbanTimestamp[client] = -1;
	g_fNextSprayTime[client] = 0.0;
	g_vecSprayOrigin[client] = ACTUAL_NULL_VECTOR;
	g_SprayAABB[client] = view_as<float>({ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }); //???
	g_bHasNSFWSpray[client] = false;
	g_bMarkedNSFWByAdmin[client] = false;
	g_bWantsToSeeNSFWSprays[client] = false;
	g_iSprayCheckAttempts[client] = 0;
}

#if defined _spray_exploit_included
public void OnSprayExploit(int client, int index, int value)
{
	if (index != 24 && index != 34)
		return;

	if (!IsValidClient(client))
		return;

	SprayExploitFixer_LogCustom("Spray exploit detected for %L. Index: %d, Value: %d", client, index, value);

	if (!g_bSprayHashBanned[client])
	{
		if (!BanClientSpray(0, client))
			LogAction(-1, -1, "[SprayManager] Failed to ban spray hash (%s) for %L for spray exploit.", g_sSprayHash[client], client);
		else
			LogAction(-1, -1, "[SprayManager] %L was spray hash banned (%s) for spray exploit.", client, g_sSprayHash[client]);
	}

	if (g_bSprayBanned[client])
	{
		LogMessage("[SprayManager] %L attempted spray exploit while already banned. Hash: %s", client, g_sSprayHash[client]);
		return;
	}

	int iBanLength = g_cvarSprayBanLength.IntValue;
	if (iBanLength < 0)
		return;

	if (!SprayBanClient(0, client, iBanLength, "Spray exploit detected"))
		LogAction(-1, -1, "[SprayManager] Failed to spray ban %L for %d minutes with the following reason: Spray exploit detected.", client, iBanLength);
	else
		LogAction(-1, -1, "[SprayManager] %L was spray banned for %d minutes. Reason: Attempt to use spray exploit.", client, iBanLength);
}
#endif

void UpdateNSFWSprayVisibilityForClient(int client, bool wantToSee)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (!g_bHasNSFWSpray[i])
			continue;

		if (g_bHasSprayHidden[client][i])
			continue;

		// Replace the NSFW decal with the original spray or vice versa
		PaintWorldDecalToOne(wantToSee ? g_iTransparentDecalIndex : GetRandomNSFWDecalIndex(), g_vecSprayOrigin[i], client);

		// Update client-to-client spray
		g_bSkipDecalHook = true;
		SprayClientDecalToOne(i, client, wantToSee ? g_iDecalEntity[i] : 0, wantToSee ? g_vecSprayOrigin[i] : ACTUAL_NULL_VECTOR);
		g_iClientToClientSprayLifetime[client][i] = wantToSee ? 0 : g_iClientToClientSprayLifetime[client][i];
		g_bSkipDecalHook = false;
	}
}

void UpdateSprayVisibilityForAllClients(int sprayOwner)
{
	if (!IsValidClient(sprayOwner) || IsVectorZero(g_vecSprayOrigin[sprayOwner]))
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (g_bHasSprayHidden[i][sprayOwner])
			continue;

		// If the spray is NSFW and the client does not want to see NSFW sprays
		if (g_bHasNSFWSpray[sprayOwner] && !g_bWantsToSeeNSFWSprays[i])
		{
			// Display the NSFW decal
			PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[sprayOwner], i);
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(sprayOwner, i, 0, ACTUAL_NULL_VECTOR);
			g_bSkipDecalHook = false;
		}
		else // If the spray is SFW or if the client wants to see NSFW sprays
		{
			// First clear any existing decal
			PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[sprayOwner], i);

			// Then display the normal spray
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(sprayOwner, i, g_iDecalEntity[sprayOwner], g_vecSprayOrigin[sprayOwner]);
			g_iClientToClientSprayLifetime[i][sprayOwner] = 0;
			g_bSkipDecalHook = false;
		}
	}
}

stock void DB_UpdateSprayNSFWStatus(int target, bool bSetByAdmin) 
{
	int iSetByAdmin = bSetByAdmin ? 1 : 0;

	char sQuery[256];
	if (g_bSQLite)
	{
		FormatEx(sQuery,sizeof(sQuery),
			"INSERT OR REPLACE INTO `spraynsfwlist` (`sprayhash`, `sprayersteamid`, `setbyadmin`) VALUES ('%s', '%s', '%d');",
			g_sSprayHash[target], sAuthID[target], iSetByAdmin);
	}
	else
	{
		FormatEx(sQuery,sizeof(sQuery),
			"INSERT INTO `spraynsfwlist` (`sprayhash`, `sprayersteamid`, `setbyadmin`) VALUES ('%s', '%s', '%d') \
			ON DUPLICATE KEY UPDATE `sprayersteamid` = '%s', `setbyadmin` = '%d';",
			g_sSprayHash[target], sAuthID[target], iSetByAdmin,
			sAuthID[target], iSetByAdmin);
	}
	SQL_TQuery(g_hDatabase, DummyCallback, sQuery);
}

stock void DB_DeleteSprayNSFWStatus(int target)
{
	char sQuery[256];

	Format(sQuery, sizeof(sQuery), "DELETE FROM `spraynsfwlist` WHERE `sprayhash` = '%s';", g_sSprayHash[target]);
	SQL_TQuery(g_hDatabase, DummyCallback, sQuery);
}
