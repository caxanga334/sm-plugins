public void RegisterCommands()
{
	RegConsoleCmd("sm_marknsfw", Command_MarkNSFW, "Marks your spray as NSFW");
	RegConsoleCmd("sm_marksfw", Command_MarkSFW, "Marks your spray as SFW");
	RegConsoleCmd("sm_nsfw", Command_NSFW, "Opt-in or out of seeing NSFW sprays");
	RegConsoleCmd("sm_hs", Command_HideSpray, "Hides a players spray");
	RegConsoleCmd("sm_us", Command_UnhideSpray, "Unhides a players spray");

	RegAdminCmd("sm_spray", Command_AdminSpray, ADMFLAG_GENERIC, "Spray a clients spray");
	RegAdminCmd("sm_sprayban", Command_SprayBan, ADMFLAG_GENERIC, "Ban a client from spraying");
	RegAdminCmd("sm_sprayunban", Command_SprayUnban, ADMFLAG_GENERIC, "Unban a client and allow them to spray");
	RegAdminCmd("sm_banspray", Command_BanSpray, ADMFLAG_GENERIC, "Ban a clients spray from being sprayed (Note: This will not spray-ban the client, it will only ban the spray which they are currently using)");
	RegAdminCmd("sm_unbanspray", Command_UnbanSpray, ADMFLAG_GENERIC, "Unban a clients spray (Note: This will not spray-unban the client, it will only unban the spray which they are currently using)");
	RegAdminCmd("sm_tracespray", Command_TraceSpray, ADMFLAG_GENERIC, "Finds a spray under your crosshair");
	RegAdminCmd("sm_spraytrace", Command_TraceSpray, ADMFLAG_GENERIC, "Finds a spray under your crosshair");
	RegAdminCmd("sm_removespray", Command_RemoveSpray, ADMFLAG_GENERIC, "Finds and removes a spray under your crosshair");
	RegAdminCmd("sm_forcensfw", Command_ForceNSFW, ADMFLAG_GENERIC, "Forces a spray to be marked NSFW");
	RegAdminCmd("sm_forcesfw", Command_ForceSFW, ADMFLAG_GENERIC, "Forces a spray to be marked SFW");
	RegAdminCmd("sm_spraymanagerupdatedb", Command_SprayManager_UpdateInfo, ADMFLAG_CHEATS, "Updates all clients info");
	RegAdminCmd("sm_spraymanagerrefreshdb", Command_SprayManager_UpdateInfo, ADMFLAG_CHEATS, "Updates all clients info");
	RegAdminCmd("sm_spraymanagerreloaddb", Command_SprayManager_UpdateInfo, ADMFLAG_CHEATS, "Updates all clients info");   
}

public Action Command_MarkNSFW(int client, int argc)
{
	if (!client)
	{
		PrintToServer("[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Unable to update status, please wait a few seconds and try again.");
		return Plugin_Handled;
	}

	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SprayManager] Unable to update status, please wait a few seconds and try again.");
		return Plugin_Handled;
	}

	if (g_bMarkedNSFWByAdmin[client] || g_bHasNSFWSpray[client])
	{
		CPrintToChat(client, "{green}[SprayManager]{default} Your spray is already marked as NSFW.");
		return Plugin_Handled;
	}

	g_bHasNSFWSpray[client] = true;

	DB_UpdateSprayNSFWStatus(client, false);
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

			PaintWorldDecalToOne(g_bHasNSFWSpray[x] ? GetRandomNSFWDecalIndex() : g_iTransparentDecalIndex, g_vecSprayOrigin[x], i);
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(x, i, g_bHasNSFWSpray[x] ? 0 : g_iDecalEntity[x], g_bHasNSFWSpray[x] ? ACTUAL_NULL_VECTOR : g_vecSprayOrigin[x]);
			g_iClientToClientSprayLifetime[i][x] = g_bHasNSFWSpray[x] ? g_iClientToClientSprayLifetime[i][x] : 0;
			g_bSkipDecalHook = false;
			break;
		}
	}
	Call_OnClientSprayMarkedNSFW(0, client);

	CPrintToChat(client, "{green}[SprayManager]{default} Your spray is now marked as NSFW.");

	return Plugin_Continue;
}

public Action Command_MarkSFW(int client, int argc)
{
	if (!client)
	{
		PrintToServer("[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (g_hDatabase == null || !g_bFullyConnected)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Unable to update status, please wait a few seconds and try again.");
		return Plugin_Handled;
	}

	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SprayManager] Unable to update status, please wait a few seconds and try again.");
		return Plugin_Handled;
	}

	if (g_bMarkedNSFWByAdmin[client])
	{
		CPrintToChat(client, "{green}[SprayManager]{default} Your spray has been marked as NSFW by an admin, you cannot change this.");
		return Plugin_Handled;
	}

	if (!g_bHasNSFWSpray[client])
	{
		CPrintToChat(client, "{green}[SprayManager]{default} Your spray is already marked as SFW.");
		return Plugin_Handled;
	}

	g_bHasNSFWSpray[client] = false;

	DB_DeleteSprayNSFWStatus(client);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (g_bHasSprayHidden[i][client])
			continue;

		if (g_bWantsToSeeNSFWSprays[i])
			continue;

		PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[client], i);
		g_bSkipDecalHook = true;
		SprayClientDecalToOne(client, i, g_iDecalEntity[client], g_vecSprayOrigin[client]);
		g_iClientToClientSprayLifetime[i][client] = 0;
		g_bSkipDecalHook = false;
	}

	Call_OnClientSprayMarkedSFW(0, client);
	CPrintToChat(client, "{green}[SprayManager]{default} Your spray is now marked as SFW.");

	return Plugin_Continue;
}

public Action Command_NSFW(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (!AreClientCookiesCached(client))
	{
		CPrintToChat(client, "{green}[SprayManager]{default} Could not update status, please wait a few seconds and try again.");
		return Plugin_Handled;
	}

	g_bWantsToSeeNSFWSprays[client] = !g_bWantsToSeeNSFWSprays[client];

	SetClientCookie(client, g_hWantsToSeeNSFWCookie, g_bWantsToSeeNSFWSprays[client] ? "1" : "0");

	CPrintToChat(client, "{green}[SprayManager]{default} You can %s", g_bWantsToSeeNSFWSprays[client] ? "now see {purple}NSFW{default} sprays." : "no longer see {purple}NSFW{default} sprays.");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (!g_bHasNSFWSpray[i])
			continue;

		if (g_bHasSprayHidden[client][i])
			continue;

		PaintWorldDecalToOne(g_bWantsToSeeNSFWSprays[client] ? g_iTransparentDecalIndex : GetRandomNSFWDecalIndex(), g_vecSprayOrigin[i], client);
		g_bSkipDecalHook = true;
		SprayClientDecalToOne(i, client, g_bWantsToSeeNSFWSprays[client] ? g_iDecalEntity[i] : 0, g_bWantsToSeeNSFWSprays[client] ? g_vecSprayOrigin[i] : ACTUAL_NULL_VECTOR);
		g_iClientToClientSprayLifetime[client][i] = g_bWantsToSeeNSFWSprays[client] ? 0 : g_iClientToClientSprayLifetime[client][i];
		g_bSkipDecalHook = false;
	}

	return Plugin_Handled;
}

public Action Command_HideSpray(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		int iTarget;
		char sArg[64];

		GetCmdArg(1, sArg, sizeof(sArg));

		if ((iTarget = FindTarget(client, sArg, false, false)) <= 0)
			return Plugin_Handled;

		g_bHasSprayHidden[client][iTarget] = true;
		CPrintToChat(client, "{green}[SprayManager]{default} You have hidden {green}%N{default}'s spray.", iTarget);

		PaintWorldDecalToOne(g_iHiddenDecalIndex, g_vecSprayOrigin[iTarget], client);
		g_bSkipDecalHook = true;
		SprayClientDecalToOne(iTarget, client, 0, ACTUAL_NULL_VECTOR);
		g_bSkipDecalHook = false;

		return Plugin_Handled;
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			g_bHasSprayHidden[client][i] = true;
			CPrintToChat(client, "{green}[SprayManager]{default} You have hidden {green}%N{default}'s spray.", i);

			PaintWorldDecalToOne(g_iHiddenDecalIndex, g_vecSprayOrigin[i], client);
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(i, client, 0, ACTUAL_NULL_VECTOR);
			g_bSkipDecalHook = false;

			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} No spray could be found.");

	return Plugin_Handled;
}

public Action Command_UnhideSpray(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		int iTarget;
		char sArg[64];

		GetCmdArg(1, sArg, sizeof(sArg));

		if ((iTarget = FindTarget(client, sArg, false, false)) <= 0)
			return Plugin_Handled;

		g_bHasSprayHidden[client][iTarget] = false;
		CPrintToChat(client, "{green}[SprayManager]{default} You have unhidden {green}%N{default}'s spray.", iTarget);

		PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[iTarget], client);

		if (!g_bWantsToSeeNSFWSprays[client] && g_bHasNSFWSpray[iTarget])
		{
			PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[iTarget], client);
			return Plugin_Handled;
		}

		g_bSkipDecalHook = true;
		SprayClientDecalToOne(iTarget, client, g_iDecalEntity[iTarget], g_vecSprayOrigin[iTarget]);
		g_iClientToClientSprayLifetime[client][iTarget] = 0;
		g_bSkipDecalHook = false;

		return Plugin_Handled;
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			g_bHasSprayHidden[client][i] = false;
			CPrintToChat(client, "{green}[SprayManager]{default} You have unhidden {green}%N{default}'s spray.", i);

			PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[i], client);

			if (!g_bWantsToSeeNSFWSprays[client] && g_bHasNSFWSpray[i])
			{
				PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[i], client);
				return Plugin_Handled;
			}

			g_bSkipDecalHook = true;
			SprayClientDecalToOne(i, client, g_iDecalEntity[i], g_vecSprayOrigin[i]);
			g_iClientToClientSprayLifetime[client][i] = 0;
			g_bSkipDecalHook = false;

			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} No spray could be found.");

	return Plugin_Handled;
}

public Action Command_AdminSpray(int client, int argc)
{
	if (!client)
	{
		PrintToServer("[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		char sArgs[64];
		char sTargetName[MAX_TARGET_LENGTH];
		int iTargets[MAXPLAYERS];
		int iTargetCount;
		bool bIsML;

		GetCmdArg(1, sArgs, sizeof(sArgs));

		if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
		{
			ReplyToTargetError(client, iTargetCount);
			return Plugin_Handled;
		}

		for (int i = 0; i < iTargetCount; i++)
		{
			g_iAllowSpray = iTargets[i];
			ForceSpray(client, iTargets[i], false);
		}

		CPrintToChat(client, "{green}[SprayManager]{default} Sprayed {green}%s{default}'s spray(s).", sTargetName);

		return Plugin_Handled;
	}

	g_iAllowSpray = client;
	ForceSpray(client, client, false);

	CPrintToChat(client, "{green}[SprayManager]{default} Sprayed your own spray.");

	return Plugin_Handled;
}

public Action Command_SprayBan(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Usage: sm_sprayban <target> <time> <reason:optional>");
		return Plugin_Handled;
	}

	int iTarget;
	char sTarget[32];
	char sLength[32];
	char sReason[32];

	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sLength, sizeof(sLength));

	if (argc > 2)
		GetCmdArg(3, sReason, sizeof(sReason));

	if ((iTarget = FindTarget(client, sTarget)) <= 0)
		return Plugin_Handled;

	if (!SprayBanClient(client, iTarget, StringToInt(sLength), sReason))
		return Plugin_Handled;

	CShowActivity2(client, "{green}[SprayManager]{olive} ", "{default}Spray banned {olive}%N", iTarget);
	LogAction(client, iTarget, "\"%L\" spray banned \"%L\" (Hash: \"%s\")", client, iTarget, g_sSprayHash[iTarget]);

	return Plugin_Handled;
}

public Action Command_SprayUnban(int client, int argc)
{
	if (argc < 1)
	{
		ReplyToCommand(client, "[SprayManager] Usage: sm_sprayunban <target>");
		return Plugin_Handled;
	}

	int iTarget;
	char sTarget[32];

	GetCmdArg(1, sTarget, sizeof(sTarget));

	if ((iTarget = FindTarget(client, sTarget)) <= 0)
		return Plugin_Handled;

	if (!SprayUnbanClient(iTarget, client))
		return Plugin_Handled;

	CShowActivity2(client, "{green}[SprayManager]{olive} ", "{default}Spray unbanned {olive}%N", iTarget);
	LogAction(client, iTarget, "\"%L\" spray unbanned \"%L\"", client, iTarget);

	return Plugin_Handled;
}

public Action Command_BanSpray(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Usage: sm_banspray <target>");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		int iTarget;
		char sTarget[32];

		GetCmdArg(1, sTarget, sizeof(sTarget));

		if ((iTarget = FindTarget(client, sTarget)) <= 0)
			return Plugin_Handled;

		if (!BanClientSpray(client, iTarget))
			return Plugin_Handled;

		CShowActivity2(client, "{green}[SprayManager] ", "{default}Banned {green}%N{default}'s spray", iTarget);
		LogAction(client, iTarget, "\"%L\" banned \"%L\"'s spray (Hash: \"%s\")", client, iTarget, g_sSprayHash[iTarget]);

		return Plugin_Handled;
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			if (!BanClientSpray(client, i))
				return Plugin_Handled;

			CShowActivity2(client, "{green}[SprayManager]{olive} ", "{default}Banned {olive}%N{default}'s spray", i);
			LogAction(client, i, "\"%L\" banned \"%L\"'s spray", client, i);
			LogAction(client, i, "\"%L\" banned \"%L\"'s spray (Hash: \"%s\")", client, i, g_sSprayHash[i]);

			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} No spray could be found.");

	return Plugin_Handled;
}

public Action Command_UnbanSpray(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[SprayManager]{default} Usage: sm_unbanspray <target>");
		return Plugin_Handled;
	}

	int iTarget;
	char sTarget[32];

	GetCmdArg(1, sTarget, sizeof(sTarget));

	if ((iTarget = FindTarget(client, sTarget)) <= 0)
		return Plugin_Handled;

	if (!UnbanClientSpray(client, iTarget))
		return Plugin_Handled;

	CShowActivity2(client, "{green}[SprayManager]{olive} ", "{default}Unbanned {olive}%N{default}'s spray", iTarget);
	LogAction(client, iTarget, "\"%L\" unbanned \"%L\"'s spray", client, iTarget);

	return Plugin_Handled;
}

public Action Command_TraceSpray(int client, int argc)
{
	if (!client)
	{
		PrintToServer("[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	float vecEndPos[3];
	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			g_bInvokedThroughTopMenu[client] = false;
			Menu_Trace(client, i);

			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} Trace did not hit any sprays.");

	return Plugin_Handled;
}

public Action Command_RemoveSpray(int client, int argc)
{
	if (!client)
	{
		PrintToServer("[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		char sArgs[64];
		char sTargetName[MAX_TARGET_LENGTH];
		int iTargets[MAXPLAYERS];
		int iTargetCount;
		bool bIsML;

		GetCmdArg(1, sArgs, sizeof(sArgs));

		if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
		{
			ReplyToTargetError(client, iTargetCount);
			return Plugin_Handled;
		}

		for (int i = 0; i < iTargetCount; i++)
		{
			g_iAllowSpray = iTargets[i];
			SprayClientDecalToAll(iTargets[i], 0, ACTUAL_NULL_VECTOR);
		}

		CPrintToChat(client, "{green}[SprayManager]{default} Removed {green}%s{default}'s spray(s).", sTargetName);

		return Plugin_Handled;
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			g_iAllowSpray = i;
			SprayClientDecalToAll(i, 0, ACTUAL_NULL_VECTOR);

			CPrintToChat(client, "{green}[SprayManager]{default} Removed {green}%N{default}'s spray.", i);

			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} No spray could be found.");

	return Plugin_Handled;
}

public Action Command_ForceNSFW(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		int iTarget;
		char sTarget[32];

		GetCmdArg(1, sTarget, sizeof(sTarget));

		if ((iTarget = FindTarget(client, sTarget)) <= 0)
			return Plugin_Handled;

		AdminForceSprayNSFW(client, iTarget);
		return Plugin_Handled;
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			AdminForceSprayNSFW(client, i);
			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} No spray could be found.");

	return Plugin_Handled;
}

public Action Command_ForceSFW(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SprayManager] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if (argc > 0)
	{
		int iTarget;
		char sTarget[32];

		GetCmdArg(1, sTarget, sizeof(sTarget));

		if ((iTarget = FindTarget(client, sTarget)) <= 0)
			return Plugin_Handled;

		AdminForceSpraySFW(client, iTarget);
		CPrintToChat(client, "{green}[SprayManager]{default} Marked {green}%N{default}'s spray as SFW.", iTarget);
		LogAction(client, iTarget, "[SprayManager] %L Marked %L spray as SFW.", client, iTarget);
		NotifyAdmins(client, iTarget, "{default}spray was marked as {green}SFW");

		return Plugin_Handled;
	}

	float vecEndPos[3];

	if (TracePlayerAngles(client, vecEndPos))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				continue;

			AdminForceSpraySFW(client, i);
			CPrintToChat(client, "{green}[SprayManager]{default} Marked {green}%N{default}'s spray as SFW.", i);
			LogAction(client, i, "[SprayManager] %L Marked %L spray as SFW.", client, i);
			NotifyAdmins(client, i, "{default}spray was marked as {green}SFW");

			return Plugin_Handled;
		}
	}

	CPrintToChat(client, "{green}[SprayManager]{default} No spray could be found.");

	return Plugin_Handled;
}

public Action Command_SprayManager_UpdateInfo(int client, int argc)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		ClearPlayerInfo(i);
		UpdatePlayerInfo(i);
		UpdateSprayHashInfo(i);
		UpdateNSFWInfo(i);
	}

	CReplyToCommand(client, "{green}[SprayManager]{default} Refreshed database.");
	return Plugin_Handled;
}