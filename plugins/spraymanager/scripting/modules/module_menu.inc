public void OnAdminMenuReady(Handle hAdminMenu)
{
	if (hAdminMenu == g_hTopMenu)
		return;

	g_hTopMenu = CloneHandle(hAdminMenu);

	TopMenuObject hMenuObj = AddToTopMenu(g_hTopMenu, "SprayManagerCommands", TopMenuObject_Category, TopMenu_Main_Handler, INVALID_TOPMENUOBJECT);

	if (hMenuObj == INVALID_TOPMENUOBJECT)
		return;

	AddToTopMenu(g_hTopMenu, "SprayManager_Spraybanlist", TopMenuObject_Item, Handler_SprayBanList, hMenuObj, "sm_banspray", ADMFLAG_GENERIC);
	AddToTopMenu(g_hTopMenu, "SprayManager_Tracespray", TopMenuObject_Item, Handler_TraceSpray, hMenuObj, "sm_tracespray", ADMFLAG_GENERIC);
	AddToTopMenu(g_hTopMenu, "SprayManager_Spray", TopMenuObject_Item, Handler_Spray, hMenuObj, "sm_spray", ADMFLAG_GENERIC);
	AddToTopMenu(g_hTopMenu, "SprayManager_Sprayban", TopMenuObject_Item, Handler_SprayBan, hMenuObj, "sm_sprayban", ADMFLAG_GENERIC);
	AddToTopMenu(g_hTopMenu, "SprayManager_Banspray", TopMenuObject_Item, Handler_BanSpray, hMenuObj, "sm_banspray", ADMFLAG_GENERIC);
	AddToTopMenu(g_hTopMenu, "SprayManager_Unban", TopMenuObject_Item, Handler_UnbanSpray, hMenuObj, "sm_unbanspray", ADMFLAG_GENERIC);
}

public void OnLibraryRemoved(const char[] sLibraryName)
{
	if (strcmp(sLibraryName, "adminmenu") == 0)
		delete g_hTopMenu;
}

public void TopMenu_Main_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	if (hAction == TopMenuAction_DisplayOption)
		Format(sBuffer, iBufflen, "%s", "SprayManager Commands");
	else if (hAction == TopMenuAction_DisplayTitle)
		Format(sBuffer, iBufflen, "%s", "SprayManager Commands:");
}

public void Handler_SprayBanList(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	bool bHasAcces = CheckCommandAccess(iParam1, "sm_slap", ADMFLAG_GENERIC);

	if (hAction == TopMenuAction_DisplayOption)
		Format(sBuffer, iBufflen, "%s", "List Spray Banned Clients");
	else if (hAction == TopMenuAction_SelectOption)
		Menu_ListBans(iParam1);
	else if (hAction == TopMenuAction_DrawOption)
		sBuffer[0] = bHasAcces ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
}

public void Handler_TraceSpray(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	bool bHasAcces = CheckCommandAccess(iParam1, "sm_tracespray", ADMFLAG_GENERIC);

	if (hAction == TopMenuAction_DisplayOption)
	{
		Format(sBuffer, iBufflen, "%s", "Trace a Spray");
	}
	else if (hAction == TopMenuAction_SelectOption)
	{
		float vecEndPos[3];

		if (TracePlayerAngles(iParam1, vecEndPos))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsPointInsideAABB(vecEndPos, g_SprayAABB[i]))
				{
					g_bInvokedThroughTopMenu[iParam1] = true;
					Menu_Trace(iParam1, i);

					return;
				}
			}
		}

		CPrintToChat(iParam1, "{green}[SprayManager]{default} Trace did not hit any sprays.");

		if (g_hTopMenu != null)
			DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
	}
	else if (hAction == TopMenuAction_DrawOption)
		sBuffer[0] = bHasAcces ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
}

public void Handler_Spray(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	bool bHasAcces = CheckCommandAccess(iParam1, "sm_spray", ADMFLAG_GENERIC);

	if (hAction == TopMenuAction_DisplayOption)
		Format(sBuffer, iBufflen, "%s", "Spray a Client's Spray");
	else if (hAction == TopMenuAction_SelectOption)
		Menu_Spray(iParam1);
	else if (hAction == TopMenuAction_DrawOption)
		sBuffer[0] = bHasAcces ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
}

public void Handler_SprayBan(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	bool bHasAcces = CheckCommandAccess(iParam1, "sm_sprayban", ADMFLAG_GENERIC);

	if (hAction == TopMenuAction_DisplayOption)
		Format(sBuffer, iBufflen, "%s", "Spray Ban a Client");
	else if (hAction == TopMenuAction_SelectOption)
		Menu_SprayBan(iParam1);
	else if (hAction == TopMenuAction_DrawOption)
		sBuffer[0] = bHasAcces ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
}

public void Handler_BanSpray(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	bool bHasAcces = CheckCommandAccess(iParam1, "sm_banspray", ADMFLAG_GENERIC);

	if (hAction == TopMenuAction_DisplayOption)
		Format(sBuffer, iBufflen, "%s", "Ban a Client's Hash Spray");
	else if (hAction == TopMenuAction_SelectOption)
		Menu_BanSpray(iParam1);
	else if (hAction == TopMenuAction_DrawOption)
		sBuffer[0] = bHasAcces ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
}

public void Handler_UnbanSpray(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iBufflen)
{
	bool bHasAcces = CheckCommandAccess(iParam1, "sm_unbanspray", ADMFLAG_GENERIC);

	if (hAction == TopMenuAction_DisplayOption)
		Format(sBuffer, iBufflen, "%s", "Unban a Client");
	else if (hAction == TopMenuAction_SelectOption)
		Menu_Unban(iParam1);
	else if (hAction == TopMenuAction_DrawOption)
		sBuffer[0] = bHasAcces ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
}

void Menu_ListBans(int client)
{
	if (!IsValidClient(client))
		return;

	int iBannedClients;

	Menu ListMenu = new Menu(MenuHandler_Menu_ListBans);
	ListMenu.SetTitle("[SprayManager] Banned Clients:");
	ListMenu.ExitBackButton =  true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (g_bSprayBanned[i] || g_bSprayHashBanned[i])
		{
			char sUserID[16];
			char sBuff[64];
			int iUserID = GetClientUserId(i);

			Format(sBuff, sizeof(sBuff), "%N (#%d)", i, iUserID);
			Format(sUserID, sizeof(sUserID), "%d", iUserID);

			ListMenu.AddItem(sUserID, sBuff);
			iBannedClients++;
		}
	}

	if (!iBannedClients)
		ListMenu.AddItem("", "No Banned Clients.", ITEMDRAW_DISABLED);

	ListMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_ListBans(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu != null)
				DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = GetClientOfUserId(StringToInt(sOption));

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				g_bInvokedThroughListMenu[iParam1] = true;
				Menu_ListBans_Target(iParam1, target);
			}
		}
	}
	return 0;
}

void Menu_Trace(int client, int target)
{
	Menu TraceMenu = new Menu(MenuHandler_Menu_Trace);
	TraceMenu.SetTitle("Sprayed by: %N (%s)", target, sAuthID3[target]);

	if (g_bInvokedThroughTopMenu[client])
		TraceMenu.ExitBackButton = true;

	TraceMenu.AddItem("1", "Warn Client");
	if (g_bHasNSFWSpray[target])
		TraceMenu.AddItem("2", "Mark as SFW", (CheckCommandAccess(client, "sm_forcesfw", ADMFLAG_GENERIC))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	else
		TraceMenu.AddItem("2", "Mark as NSFW", (CheckCommandAccess(client, "sm_forcensfw", ADMFLAG_GENERIC))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	TraceMenu.AddItem("3", "Kick Client", (CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	TraceMenu.AddItem("4", "Spray Ban Client", (CheckCommandAccess(client, "sm_sprayban", ADMFLAG_GENERIC))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	TraceMenu.AddItem("5", "Ban Clients Spray Hash", (CheckCommandAccess(client, "sm_banspray", ADMFLAG_GENERIC))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	TraceMenu.AddItem("", "", ITEMDRAW_SPACER);
	TraceMenu.AddItem("6", "Ban Client", (CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

	g_iSprayTraceTarget[client] = target;

	TraceMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_Trace(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu != null)
				DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[2];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = g_iSprayTraceTarget[iParam1];

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				g_bInvokedThroughTopMenu[iParam1] = false;

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				switch (StringToInt(sOption))
				{
					case 1:
					{
						CPrintToChat(target, "{green}[SprayManager]{default} Your spray is not allowed, change it.");
						LogAction(target, iParam1, "[SprayManager] \"%L\" has been warned for his spray by \"%L\"", target, iParam1);
						NotifyAdmins(iParam1, target, "{default}has been {green}warned {default}for his spray");
						Menu_Trace(iParam1, target);
					}

					case 2:
					{
						if (!g_bHasNSFWSpray[target])
							AdminForceSprayNSFW(iParam1, target);
						else
							AdminForceSpraySFW(iParam1, target);

						Menu_Trace(iParam1, target);
					}

					case 3:
					{
						g_bInvokedThroughTopMenu[iParam1] = false;
						KickClient(target, "Your spray is not allowed, change it"); 
						CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Kicked {olive}%N{default}'s for his spray", target);
						LogAction(target, iParam1, "[SprayManager] \"%L\" has been kicked for his spray by \"%L\"", target, iParam1);
					}

					case 4:
					{
						Menu TraceSpraySprayBan = new Menu(MenuHandler_Menu_Trace_SprayBan);
						TraceSpraySprayBan.SetTitle("[SprayManager] Select a Spray Ban Length for %N (#%d)", target, GetClientUserId(target));
						TraceSpraySprayBan.ExitBackButton = true;

						TraceSpraySprayBan.AddItem("10", "10 Minutes");
						TraceSpraySprayBan.AddItem("30", "30 Minutes");
						TraceSpraySprayBan.AddItem("60", "1 Hour");
						TraceSpraySprayBan.AddItem("240", "4 Hours");
						TraceSpraySprayBan.AddItem("480", "8 Hours");
						TraceSpraySprayBan.AddItem("720", "12 Hours");
						TraceSpraySprayBan.AddItem("1440", "1 Day");
						TraceSpraySprayBan.AddItem("2880", "2 Days");
						TraceSpraySprayBan.AddItem("4320", "3 Days");
						TraceSpraySprayBan.AddItem("10080", "1 Week");
						TraceSpraySprayBan.AddItem("20160", "2 Weeks");
						TraceSpraySprayBan.AddItem("40320", "1 Month");
						TraceSpraySprayBan.AddItem("0", "Permanent");

						g_iSprayBanTarget[iParam1] = target;

						TraceSpraySprayBan.Display(iParam1, MENU_TIME_FOREVER);
					}

					case 5:
					{
						if (BanClientSpray(iParam1, target))
						{
							CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Banned {green}%N{default}'s spray.", target);
							LogAction(iParam1, target, "\"%L\" banned \"%L\"'s spray (Hash: \"%s\")", iParam1, target, g_sSprayHash[target]);
						}
					}

					case 6:
					{
						Menu TraceSprayBan = new Menu(MenuHandler_Menu_Trace_Ban);
						TraceSprayBan.SetTitle("[SprayManager] Select a Ban Length for %N (#%d)", target, GetClientUserId(target));
						TraceSprayBan.ExitBackButton = true;

						TraceSprayBan.AddItem("10", "10 Minutes");
						TraceSprayBan.AddItem("30", "30 Minutes");
						TraceSprayBan.AddItem("60", "1 Hour");
						TraceSprayBan.AddItem("240", "4 Hours");
						TraceSprayBan.AddItem("480", "8 Hours");
						TraceSprayBan.AddItem("720", "12 Hours");
						TraceSprayBan.AddItem("1440", "1 Day");
						TraceSprayBan.AddItem("2880", "2 Days");
						TraceSprayBan.AddItem("4320", "3 Days");
						TraceSprayBan.AddItem("10080", "1 Week");
						TraceSprayBan.AddItem("20160", "2 Weeks");
						TraceSprayBan.AddItem("40320", "1 Month");
						TraceSprayBan.AddItem("0", "Permanent");

						g_iBanTarget[iParam1] = target;

						TraceSprayBan.Display(iParam1, MENU_TIME_FOREVER);
					}
				}
			}
		}
	}
	return 0;
}

int MenuHandler_Menu_Trace_SprayBan(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
			{
				if (IsValidClient(g_iSprayBanTarget[iParam1]))
				{
					Menu_Trace(iParam1, g_iSprayBanTarget[iParam1]);
				}
				else if (g_hTopMenu != null)
				{
					g_bInvokedThroughTopMenu[iParam1] = false;
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				}
				else
				{
					g_bInvokedThroughTopMenu[iParam1] = false;
					delete hMenu;
				}
			}
		}

		case MenuAction_Select:
		{
			char sOption[8];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = g_iSprayBanTarget[iParam1];

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				g_iSprayBanTarget[iParam1] = 0;
				g_bInvokedThroughTopMenu[iParam1] = false;

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				if (SprayBanClient(iParam1, target, StringToInt(sOption), "Inappropriate Spray"))
				{
					CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Spray banned {olive}%N{default}.", target);
					LogAction(iParam1, target, "\"%L\" spray banned \"%L\" (Hash: \"%s\")", iParam1, target, g_sSprayHash[target]);
				}

				g_iSprayBanTarget[iParam1] = 0;
				g_bInvokedThroughTopMenu[iParam1] = false;
			}
		}
	}
	return 0;
}

int MenuHandler_Menu_Trace_Ban(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
			{
				if (IsValidClient(g_iBanTarget[iParam1]))
				{
					Menu_Trace(iParam1, g_iBanTarget[iParam1]);
				}
				else if (g_hTopMenu != null)
				{
					g_bInvokedThroughTopMenu[iParam1] = false;
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				}
				else
				{
					g_bInvokedThroughTopMenu[iParam1] = false;
					delete hMenu;
				}
			}
		}

		case MenuAction_Select:
		{
			char sOption[8];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = g_iBanTarget[iParam1];

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				g_iBanTarget[iParam1] = 0;
				g_bInvokedThroughTopMenu[iParam1] = false;

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				FakeClientCommandEx(iParam1, "sm_ban \"#%d\" \"%s\" \"Inappropriate spray\"", GetClientUserId(g_iBanTarget[iParam1]), sOption);
				g_iBanTarget[iParam1] = 0;
				g_bInvokedThroughTopMenu[iParam1] = false;
			}
		}
	}
	return 0;
}

void Menu_Spray(int client)
{
	if (!IsValidClient(client))
		return;

	Menu SprayMenu = new Menu(MenuHandler_Menu_Spray);
	SprayMenu.SetTitle("[SprayManager] Select a Client to Force Spray:");
	SprayMenu.ExitBackButton =  true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		char sUserID[16];
		char sBuff[64];
		int iUserID = GetClientUserId(i);

		Format(sUserID, sizeof(sUserID), "%d", iUserID);

		if (g_bSprayBanned[i] && g_bSprayHashBanned[i])
		{
			Format(sBuff, sizeof(sBuff), "%N (#%d) [Spray & Hash Banned]", i, iUserID);

			SprayMenu.AddItem(sUserID, sBuff);
		}
		else if (g_bSprayBanned[i])
		{
			Format(sBuff, sizeof(sBuff), "%N (#%d) [Spray Banned]", i, iUserID);

			SprayMenu.AddItem(sUserID, sBuff);
		}
		else if (g_bSprayHashBanned[i])
		{
			Format(sBuff, sizeof(sBuff), "%N (#%d) [Hash Banned]", i, iUserID);

			SprayMenu.AddItem(sUserID, sBuff);
		}
		else
		{
			Format(sBuff, sizeof(sBuff), "%N (#%d)", i, iUserID);

			SprayMenu.AddItem(sUserID, sBuff);
		}
	}

	SprayMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_Spray(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu != null)
				DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[8];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = GetClientOfUserId(StringToInt(sOption));

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				g_iAllowSpray = target;
				ForceSpray(iParam1, target);

				CPrintToChat(iParam1, "{green}[SprayManager]{default} Sprayed {green}%N{default}'s spray(s).", target);

				Menu_Spray(iParam1);
			}
		}
	}
	return 0;
}

void Menu_SprayBan(int client)
{
	if (!IsValidClient(client))
		return;

	int iClientsToDisplay;

	Menu SprayBanMenu = new Menu(MenuHandler_Menu_SprayBan);
	SprayBanMenu.SetTitle("[SprayManager] Select a Client to Spray Ban:");
	SprayBanMenu.ExitBackButton = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (g_bSprayBanned[i])
			continue;

		char sUserID[16];
		char sBuff[64];
		int iUserID = GetClientUserId(i);

		Format(sBuff, sizeof(sBuff), "%N (#%d)", i, iUserID);
		Format(sUserID, sizeof(sUserID), "%d", iUserID);

		SprayBanMenu.AddItem(sUserID, sBuff);
		iClientsToDisplay++;
	}

	if (!iClientsToDisplay)
		SprayBanMenu.AddItem("", "No eligible Clients found.", ITEMDRAW_DISABLED);

	SprayBanMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_SprayBan(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu != null)
				DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = GetClientOfUserId(StringToInt(sOption));

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				Menu SprayBanLengthMenu = new Menu(MenuHandler_Menu_SprayBan_Length);
				SprayBanLengthMenu.SetTitle("[SprayManager] Choose a Spray Ban Length for %N (#%d)", target, GetClientUserId(target));
				SprayBanLengthMenu.ExitBackButton = true;

				SprayBanLengthMenu.AddItem("10", "10 Minutes");
				SprayBanLengthMenu.AddItem("30", "30 Minutes");
				SprayBanLengthMenu.AddItem("60", "1 Hour");
				SprayBanLengthMenu.AddItem("240", "4 Hours");
				SprayBanLengthMenu.AddItem("480", "8 Hours");
				SprayBanLengthMenu.AddItem("720", "12 Hours");
				SprayBanLengthMenu.AddItem("1440", "1 Day");
				SprayBanLengthMenu.AddItem("2880", "2 Days");
				SprayBanLengthMenu.AddItem("4320", "3 Days");
				SprayBanLengthMenu.AddItem("10080", "1 Week");
				SprayBanLengthMenu.AddItem("20160", "2 Weeks");
				SprayBanLengthMenu.AddItem("40320", "1 Month");
				SprayBanLengthMenu.AddItem("0", "Permanent");

				g_iSprayBanTarget[iParam1] = target;

				SprayBanLengthMenu.Display(iParam1, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

int MenuHandler_Menu_SprayBan_Length(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
				Menu_SprayBan(iParam1);
		}

		case MenuAction_Select:
		{
			char sOption[8];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = g_iSprayBanTarget[iParam1];

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				g_iSprayBanTarget[iParam1] = 0;

				Menu_SprayBan(iParam1);
			}
			else
			{
				if (SprayBanClient(iParam1, target, StringToInt(sOption), "Inappropriate Spray"))
				{
					CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Spray banned {olive}%N", target);
					LogAction(iParam1, target, "\"%L\" spray banned \"%L\" (Hash: \"%s\")", iParam1, target, g_sSprayHash[target]);
				}

				g_iSprayBanTarget[iParam1] = 0;
			}
		}
	}
	return 0;
}

void Menu_BanSpray(int client)
{
	if (!IsValidClient(client))
		return;

	int iClientsToDisplay;

	Menu BanSprayMenu = new Menu(MenuHandler_Menu_BanSpray);
	BanSprayMenu.SetTitle("[SprayManager] Select a Client to Ban their Spray:");
	BanSprayMenu.ExitBackButton =  true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (g_bSprayHashBanned[i])
			continue;

		char sUserID[16];
		char sBuff[64];
		int iUserID = GetClientUserId(i);

		Format(sBuff, sizeof(sBuff), "%N (#%d)", i, iUserID);
		Format(sUserID, sizeof(sUserID), "%d", iUserID);

		BanSprayMenu.AddItem(sUserID, sBuff);
		iClientsToDisplay++;
	}

	if (!iClientsToDisplay)
		BanSprayMenu.AddItem("", "No eligible Clients found.", ITEMDRAW_DISABLED);

	BanSprayMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_BanSpray(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu != null)
				DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = GetClientOfUserId(StringToInt(sOption));

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				Menu_BanSpray(iParam1);
			}
			else
			{
				if (BanClientSpray(iParam1, target))
				{
					CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Banned {olive}%N{default}'s spray", target);
					LogAction(iParam1, target, "\"%L\" banned \"%L\"'s spray (Hash: \"%s\")", iParam1, target, g_sSprayHash[target]);
				}
			}
		}
	}
	return 0;
}

void Menu_Unban(int client)
{
	if (!IsValidClient(client))
		return;

	int iBannedClients;

	Menu UnbanSprayMenu = new Menu(MenuHandler_Menu_UnbanSpray);
	UnbanSprayMenu.SetTitle("[SprayManager] Select a Client for more information:");
	UnbanSprayMenu.ExitBackButton =  true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		if (!g_bSprayHashBanned[i] && !g_bSprayBanned[i])
			continue;

		char sUserID[16];
		char sBuff[64];
		int iUserID = GetClientUserId(i);

		Format(sBuff, sizeof(sBuff), "%N (#%d)", i, iUserID);
		Format(sUserID, sizeof(sUserID), "%d", iUserID);

		UnbanSprayMenu.AddItem(sUserID, sBuff);
		iBannedClients++;
	}

	if (!iBannedClients)
		UnbanSprayMenu.AddItem("", "No Banned Clients.", ITEMDRAW_DISABLED);

	UnbanSprayMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_UnbanSpray(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu != null)
				DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = GetClientOfUserId(StringToInt(sOption));

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				Menu_Unban(iParam1);
			}
			else
			{
				g_bInvokedThroughListMenu[iParam1] = false;
				Menu_ListBans_Target(iParam1, target);
			}
		}
	}
	return 0;
}

void Menu_ListBans_Target(int client, int target)
{
	Menu ListTargetMenu = new Menu(MenuHandler_Menu_ListBans_Target);
	ListTargetMenu.SetTitle("[SprayManager] Banned Client: %N (#%d)", target, GetClientUserId(target));
	ListTargetMenu.ExitBackButton = true;

	char sBanType[32];
	char sUserID[32];
	int iUserID = GetClientUserId(target);

	Format(sUserID, sizeof(sUserID), "%d", iUserID);

	if (g_bSprayHashBanned[target] && !g_bSprayBanned[target])
	{
		strcopy(sBanType, sizeof(sBanType), "Type: Hash");

		ListTargetMenu.AddItem("", sBanType, ITEMDRAW_DISABLED);
		ListTargetMenu.AddItem("", "", ITEMDRAW_SPACER);

		ListTargetMenu.AddItem(sUserID, "Unban Client?");

		ListTargetMenu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	char sBanExpiryDate[64];
	char sBanIssuedDate[64];
	char sBanDuration[64];
	char sBannedBy[128];
	char sBanReason[64];
	int iBanExpiryDate = g_iSprayUnbanTimestamp[target];
	int iBanIssuedDate = g_iSprayBanTimestamp[target];
	int iBanDuration = iBanExpiryDate ? ((iBanExpiryDate - iBanIssuedDate) / 60) : 0;

	if (iBanExpiryDate)
	{
		FormatTime(sBanExpiryDate, sizeof(sBanExpiryDate), NULL_STRING, iBanExpiryDate);
		Format(sBanDuration, sizeof(sBanDuration), "%d %s", iBanDuration, SingularOrMultiple(iBanDuration) ? "Minutes" : "Minute");
	}
	else
	{
		strcopy(sBanExpiryDate, sizeof(sBanExpiryDate), "Never");
		strcopy(sBanDuration, sizeof(sBanDuration), "Permanent");
	}

	FormatTime(sBanIssuedDate, sizeof(sBanIssuedDate), NULL_STRING, iBanIssuedDate);
	Format(sBannedBy, sizeof(sBannedBy), "Banned by: %s (%s)", g_sBanIssuer[target], g_sBanIssuerSID[target]);
	Format(sBanDuration, sizeof(sBanDuration), "Duration: %s", sBanDuration);
	Format(sBanExpiryDate, sizeof(sBanExpiryDate), "Expires: %s", sBanExpiryDate);
	Format(sBanIssuedDate, sizeof(sBanIssuedDate), "Issued on: %s", sBanIssuedDate);
	Format(sBanReason, sizeof(sBanReason), "Reason: %s", g_sBanReason[target]);

	if (g_bSprayBanned[target] && g_bSprayHashBanned[target])
		strcopy(sBanType, sizeof(sBanType), "Type: Spray & Hash");
	else if (g_bSprayBanned[target])
		strcopy(sBanType, sizeof(sBanType), "Type: Spray");

	ListTargetMenu.AddItem("", sBanType, ITEMDRAW_DISABLED);
	ListTargetMenu.AddItem("", sBannedBy, ITEMDRAW_DISABLED);
	ListTargetMenu.AddItem("", sBanIssuedDate, ITEMDRAW_DISABLED);
	ListTargetMenu.AddItem("", sBanExpiryDate, ITEMDRAW_DISABLED);
	ListTargetMenu.AddItem("", sBanDuration, ITEMDRAW_DISABLED);
	ListTargetMenu.AddItem("", sBanReason, ITEMDRAW_DISABLED);

	ListTargetMenu.AddItem(sUserID, "Unban Client?");

	ListTargetMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Menu_ListBans_Target(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
			{
				if (g_bInvokedThroughListMenu[iParam1])
					Menu_ListBans(iParam1);
				else
					Menu_Unban(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int target = GetClientOfUserId(StringToInt(sOption));

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");
				Menu_ListBans(iParam1);
			}
			else
			{
				if (g_bSprayBanned[target] && g_bSprayHashBanned[target])
				{
					Menu MenuUnbanMode = new Menu(MenuHandler_Menu_UnbanMode);
					MenuUnbanMode.SetTitle("[SprayManager] Unban %N?", target);
					MenuUnbanMode.ExitBackButton = true;

					MenuUnbanMode.AddItem("H", "Remove Hash Ban.");
					MenuUnbanMode.AddItem("S", "Remove Spray Ban.");
					MenuUnbanMode.AddItem("B", "Remove Both.");

					g_iSprayUnbanTarget[iParam1] = target;

					MenuUnbanMode.Display(iParam1, MENU_TIME_FOREVER);

					return 0;
				}

				Menu MenuConfirmUnban = new Menu(MenuHandler_Menu_ConfirmUnban);
				MenuConfirmUnban.SetTitle("[SprayManager] Unban %N?", target);
				MenuConfirmUnban.ExitBackButton = true;

				MenuConfirmUnban.AddItem("Y", "Yes.");
				MenuConfirmUnban.AddItem("N", "No.");

				g_iSprayUnbanTarget[iParam1] = target;

				MenuConfirmUnban.Display(iParam1, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

int MenuHandler_Menu_UnbanMode(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
			{
				if (IsValidClient(g_iSprayUnbanTarget[iParam1]))
					Menu_ListBans_Target(iParam1, g_iSprayUnbanTarget[iParam1]);
				else if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
		}

		case MenuAction_Select:
		{
			char sOption[2];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = g_iSprayUnbanTarget[iParam1];

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				g_iSprayUnbanTarget[iParam1] = 0;

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				if (sOption[0] == 'H')
				{
					if (UnbanClientSpray(iParam1, target))
					{
						CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Unbanned {olive}%N{default}'s spray", target);
						LogAction(iParam1, target, "\"%L\" unbanned \"%L\"'s spray", iParam1, target);
					}
				}
				else if (sOption[0] == 'S')
				{
					if (SprayUnbanClient(target, iParam1))
					{
						CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Spray unbanned {olive}%N", target);
						LogAction(iParam1, target, "\"%L\" spray unbanned \"%L\"", iParam1, target);
					}
				}
				else if (sOption[0] == 'B')
				{
					if (SprayUnbanClient(target, iParam1) && UnbanClientSpray(iParam1, target))
					{
						CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Spray unbanned {olive}%N", target);
						LogAction(iParam1, target, "\"%L\" spray unbanned \"%L\"", iParam1, target);
					}
				}

				g_iSprayUnbanTarget[iParam1] = 0;
			}
		}
	}
	return 0;
}

int MenuHandler_Menu_ConfirmUnban(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch (action)
	{
		case MenuAction_End:
			delete hMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
			{
				if (IsValidClient(g_iSprayUnbanTarget[iParam1]))
					Menu_ListBans_Target(iParam1, g_iSprayUnbanTarget[iParam1]);
				else if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
		}

		case MenuAction_Select:
		{
			char sOption[2];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));

			int target = g_iSprayUnbanTarget[iParam1];

			if (!IsValidClient(target))
			{
				CPrintToChat(iParam1, "{green}[SprayManager]{default} Target no longer available.");

				g_iSprayUnbanTarget[iParam1] = 0;

				if (g_hTopMenu != null)
					DisplayTopMenu(g_hTopMenu, iParam1, TopMenuPosition_LastCategory);
				else
					delete hMenu;
			}
			else
			{
				if (sOption[0] == 'Y')
				{
					if (g_bSprayHashBanned[target] && g_bSprayBanned[target])
					{
						if (SprayUnbanClient(target, iParam1) && UnbanClientSpray(iParam1, target))
						{
							CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Spray unbanned {olive}%N", target);
							LogAction(iParam1, target, "\"%L\" spray unbanned \"%L\"", iParam1, target);
						}
					}
					else if (g_bSprayBanned[target])
					{
						if (SprayUnbanClient(target, iParam1))
						{
							CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Spray unbanned {olive}%N", target);
							LogAction(iParam1, target, "\"%L\" spray unbanned \"%L\"", iParam1, target);
						}
					}
					else if (g_bSprayHashBanned[target])
					{
						if (UnbanClientSpray(iParam1, target))
						{
							CShowActivity2(iParam1, "{green}[SprayManager]{olive} ", "{default}Unbanned {olive}%N{default}'s spray", target);
							LogAction(iParam1, target, "\"%L\" unbanned \"%L\"'s spray", iParam1, target);
						}
					}

					g_iSprayUnbanTarget[iParam1] = 0;
				}
				else if (sOption[0] == 'N')
				{
					Menu_ListBans_Target(iParam1, g_iSprayUnbanTarget[iParam1]);
					g_iSprayUnbanTarget[iParam1] = 0;
				}
			}
		}
	}
	return 0;
}