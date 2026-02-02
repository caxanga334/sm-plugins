public void CreateNatives()
{
    CreateNative("SprayManager_IsClientSprayBanned", Native_IsClientSprayBanned);
	CreateNative("SprayManager_IsClientSprayHashBanned", Native_IsClientSprayHashBanned);
	CreateNative("SprayManager_IsClientSprayNSFW", Native_IsClientSprayNSFW);
	CreateNative("SprayManager_BanClientSpray", Native_BanClientSpray);
	CreateNative("SprayManager_UnbanClientSpray", Native_UnbanClientSpray);
	CreateNative("SprayManager_BanClientSprayHash", Native_BanClientSprayHash);
	CreateNative("SprayManager_UnbanClientSprayHash", Native_UnbanClientSprayHash);
	CreateNative("SprayManager_ForceSpray", Native_ForceSpray);
	CreateNative("SprayManager_MarkSprayAsNSFW", Native_MarkSprayAsNSFW);
	CreateNative("SprayManager_MarkSprayAsSFW", Native_MarkSprayAsSFW);
	CreateNative("SprayManager_GetClientSprayHash", Native_GetClientSprayHash);
	CreateNative("SprayManager_ClientWantsToSeeNSFW", Native_ClientWantsToSeeNSFW);
	CreateNative("SprayManager_SetClientWantsToSeeNSFW", Native_SetClientWantsToSeeNSFW);
	CreateNative("SprayManager_HasClientHiddenSpray", Native_HasClientHiddenSpray);
	CreateNative("SprayManager_SetClientSprayHidden", Native_SetClientSprayHidden);
}

public void CreateForwards()
{
    g_hForward_OnClientSprayBanned = CreateGlobalForward("SprayManager_OnClientSprayBanned", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hForward_OnClientSprayUnbanned = CreateGlobalForward("SprayManager_OnClientSprayUnbanned", ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_OnClientSprayHashBanned = CreateGlobalForward("SprayManager_OnClientSprayHashBanned", ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_OnClientSprayHashUnbanned = CreateGlobalForward("SprayManager_OnClientSprayHashUnbanned", ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_OnClientSprayMarkedNSFW = CreateGlobalForward("SprayManager_OnClientSprayMarkedNSFW", ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_OnClientSprayMarkedSFW = CreateGlobalForward("SprayManager_OnClientSprayMarkedSFW", ET_Ignore, Param_Cell, Param_Cell);
}

stock void Call_OnClientSprayBanned(int admin, int target, int length, const char[] reason)
{
	Call_StartForward(g_hForward_OnClientSprayBanned);
	Call_PushCell(admin);
	Call_PushCell(target);
	Call_PushCell(length);
	Call_PushString(reason);
	Call_Finish();
}

stock void Call_OnClientSprayUnbanned(int admin, int target)
{
	Call_StartForward(g_hForward_OnClientSprayUnbanned);
	Call_PushCell(admin);
	Call_PushCell(target);
	Call_Finish();
}

stock void Call_OnClientSprayHashBanned(int admin, int target)
{
	Call_StartForward(g_hForward_OnClientSprayHashBanned);
	Call_PushCell(admin);
	Call_PushCell(target);
	Call_Finish();
}

stock void Call_OnClientSprayHashUnbanned(int admin, int target)
{
	Call_StartForward(g_hForward_OnClientSprayHashUnbanned);
	Call_PushCell(admin);
	Call_PushCell(target);
	Call_Finish();
}

stock void Call_OnClientSprayMarkedNSFW(int admin, int target)
{
	Call_StartForward(g_hForward_OnClientSprayMarkedNSFW);
	Call_PushCell(admin);
	Call_PushCell(target);
	Call_Finish();
}

stock void Call_OnClientSprayMarkedSFW(int admin, int target)
{
	Call_StartForward(g_hForward_OnClientSprayMarkedSFW);
	Call_PushCell(admin);
	Call_PushCell(target);
	Call_Finish();
}

public int Native_IsClientSprayBanned(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	return g_bSprayBanned[client];
}

public int Native_IsClientSprayHashBanned(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	return g_bSprayHashBanned[client];
}

public int Native_IsClientSprayNSFW(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	return g_bHasNSFWSpray[client];
}

public int Native_BanClientSpray(Handle plugin, int numParams)
{
	int admin = GetNativeCell(1);
	int target = GetNativeCell(2);
	int length = GetNativeCell(3);

	char reason[64];
	GetNativeString(4, reason, sizeof(reason));

	return SprayBanClient(admin, target, length, reason);
}

public int Native_UnbanClientSpray(Handle plugin, int numParams)
{
	int target = GetNativeCell(1);
	int admin = GetNativeCell(2);

	return SprayUnbanClient(target, admin);
}

public int Native_BanClientSprayHash(Handle plugin, int numParams)
{
	int admin = GetNativeCell(1);
	int target = GetNativeCell(2);

	return BanClientSpray(admin, target);
}

public int Native_UnbanClientSprayHash(Handle plugin, int numParams)
{
	int admin = GetNativeCell(1);
	int target = GetNativeCell(2);

	return UnbanClientSpray(admin, target);
}

public int Native_ForceSpray(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);
	bool bPlaySound = GetNativeCell(3);

	return ForceSpray(client, target, bPlaySound);
}

public int Native_MarkSprayAsNSFW(Handle plugin, int numParams)
{
	int admin = GetNativeCell(1);
	int target = GetNativeCell(2);

	if (!IsValidClient(target))
		return false;

	if (admin == 0)
	{
		// Self-marking
		if (g_bMarkedNSFWByAdmin[target] || g_bHasNSFWSpray[target])
			return false;

		g_bHasNSFWSpray[target] = true;

		DB_UpdateSprayNSFWStatus(target, false);
		UpdateSprayVisibilityForAllClients(target);
		Call_OnClientSprayMarkedNSFW(0, target);
		return true;
	}
	else
	{
		// Admin marking
		if (g_bHasNSFWSpray[target] && g_bMarkedNSFWByAdmin[target])
			return false;

		return AdminForceSprayNSFW(admin, target);
	}
}

public int Native_MarkSprayAsSFW(Handle plugin, int numParams)
{
	int admin = GetNativeCell(1);
	int target = GetNativeCell(2);

	if (!IsValidClient(target))
		return false;

	if (admin == 0)
	{
		// Self-marking
		if (g_bMarkedNSFWByAdmin[target])
			return false;

		if (!g_bHasNSFWSpray[target])
			return false;

		g_bHasNSFWSpray[target] = false;

		DB_DeleteSprayNSFWStatus(target);
		UpdateSprayVisibilityForAllClients(target);
		Call_OnClientSprayMarkedSFW(0, target);
	}
	else
	{
		// Admin marking
		if (!g_bHasNSFWSpray[target])
			return false;

		AdminForceSpraySFW(admin, target);
	}

	return true;
}

public int Native_GetClientSprayHash(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	int maxlen = GetNativeCell(3);
	SetNativeString(2, g_sSprayHash[client], maxlen);

	return true;
}

public int Native_ClientWantsToSeeNSFW(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	return g_bWantsToSeeNSFWSprays[client];
}

public int Native_SetClientWantsToSeeNSFW(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool bWantToSee = GetNativeCell(2);

	if (!IsValidClient(client))
		return false;

	if (!AreClientCookiesCached(client))
		return false;

	g_bWantsToSeeNSFWSprays[client] = bWantToSee;
	SetClientCookie(client, g_hWantsToSeeNSFWCookie, bWantToSee ? "1" : "0");

	UpdateNSFWSprayVisibilityForClient(client, bWantToSee);

	return true;
}

public int Native_HasClientHiddenSpray(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);

	if (!IsValidClient(client) || !IsValidClient(target))
		return false;

	return g_bHasSprayHidden[client][target];
}

public int Native_SetClientSprayHidden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);
	bool bHide = GetNativeCell(3);

	if (!IsValidClient(client) || !IsValidClient(target))
		return false;

	g_bHasSprayHidden[client][target] = bHide;

	if (bHide)
	{
		PaintWorldDecalToOne(g_iHiddenDecalIndex, g_vecSprayOrigin[target], client);
		g_bSkipDecalHook = true;
		SprayClientDecalToOne(target, client, 0, ACTUAL_NULL_VECTOR);
		g_bSkipDecalHook = false;
	}
	else
	{
		PaintWorldDecalToOne(g_iTransparentDecalIndex, g_vecSprayOrigin[target], client);

		if (!g_bWantsToSeeNSFWSprays[client] && g_bHasNSFWSpray[target])
		{
			PaintWorldDecalToOne(GetRandomNSFWDecalIndex(), g_vecSprayOrigin[target], client);
		}
		else
		{
			g_bSkipDecalHook = true;
			SprayClientDecalToOne(target, client, g_iDecalEntity[target], g_vecSprayOrigin[target]);
			g_iClientToClientSprayLifetime[client][target] = 0;
			g_bSkipDecalHook = false;
		}
	}

	return true;
}

public int Native_GetClientSprayPosition(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	if (IsVectorZero(g_vecSprayOrigin[client]))
		return false;

	SetNativeArray(2, g_vecSprayOrigin[client], 3);
	
	return true;
}

public int Native_AreSpraysEnabled(Handle plugin, int numParams)
{
	return g_bEnableSprays;
}

public int Native_SetSpraysEnabled(Handle plugin, int numParams)
{
	bool bEnable = GetNativeCell(1);

	g_bEnableSprays = bEnable;
	g_cvarEnableSprays.BoolValue = bEnable;

	if (!bEnable)
		RemoveAllSprays();
	
	return true;
}

public int Native_GetClientNextSprayTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return view_as<int>(0.0);

	float nextTime = g_fNextSprayTime[client] - GetGameTime();
	return view_as<int>(nextTime > 0.0 ? nextTime : 0.0);
}

public int Native_SetClientNextSprayTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	float fTime = GetNativeCell(2);

	if (!IsValidClient(client))
		return false;

	g_fNextSprayTime[client] = GetGameTime() + fTime;

	return true;
}

public int Native_GetClientUnbanTimestamp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return -1;

	if (!g_bSprayBanned[client])
		return -1;

	return g_iSprayUnbanTimestamp[client];
}

public int Native_GetClientBanReason(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	if (!g_bSprayBanned[client])
		return false;

	int maxlen = GetNativeCell(3);
	SetNativeString(2, g_sBanReason[client], maxlen);

	return true;
}

public int Native_GetClientBanIssuer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
		return false;

	if (!g_bSprayBanned[client])
		return false;

	int maxlen = GetNativeCell(3);
	SetNativeString(2, g_sBanIssuer[client], maxlen);

	return true;
}

public int Native_RemoveAllSprays(Handle plugin, int numParams)
{
	RemoveAllSprays();
	return true;
}
