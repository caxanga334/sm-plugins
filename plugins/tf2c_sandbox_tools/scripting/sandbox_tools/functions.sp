
enum SandboxAction
{
	SANDBOX_ACTION_REGENERATE = 0,
	SANDBOX_ACTION_NOCLIP,
	SANDBOX_ACTION_SIZE,
	SANDBOX_ACTION_RESPAWN,
	MAX_SANDBOX_ACTIONS
}

static char s_SBActionsDisplay[][] = {
	"SBA_Regenerate",
	"SBA_Noclip",
	"SBA_Size",
	"SBA_Respawn",
};

void Vscript_Regenerate(int client)
{
	SetVariantString("self.Regenerate(true)");
	AcceptEntityInput(client, "RunScriptCode", client, client);
}

void Vscript_Respawn(int client)
{
	SetVariantString("self.ForceRegenerateAndRespawn()");
	AcceptEntityInput(client, "RunScriptCode", client, client);
}

void Frame_Respawn(any data)
{
	int client = GetClientFromSerial(view_as<int>(data));

	if (client != 0)
	{
		Vscript_Respawn(client);
	}
}

void Vscript_ToggleNoclip(int client)
{
	MoveType mt = GetEntityMoveType(client);

	if (mt != MOVETYPE_NOCLIP)
	{
		SetVariantString("self.SetMoveType(Constants.EMoveType.MOVETYPE_NOCLIP,0)");
		AcceptEntityInput(client, "RunScriptCode", client, client);
		return;
	}

	SetVariantString("self.SetMoveType(Constants.EMoveType.MOVETYPE_WALK,0)");
	AcceptEntityInput(client, "RunScriptCode", client, client);
}

void Vscript_GiveInvul(int client)
{
	SetVariantString("self.AddCondEx(Constants.ETFCond.TF_COND_INVULNERABLE,10.0,null)");
	AcceptEntityInput(client, "RunScriptCode", client, client);
}

void Entity_ToggleSmall(int client)
{
	float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");

	if (scale >= 0.99)
	{
		SetVariantFloat(0.65);
		AcceptEntityInput(client, "SetModelScale", client, client);
		return
	}

	SetVariantFloat(1.0);
	AcceptEntityInput(client, "SetModelScale", client, client);
}

void DoSandboxAction(int client, SandboxAction action)
{
	switch(action)
	{
	case SANDBOX_ACTION_REGENERATE:
	{
		Vscript_Regenerate(client);
	}
	case SANDBOX_ACTION_NOCLIP:
	{
		Vscript_ToggleNoclip(client);
	}
	case SANDBOX_ACTION_SIZE:
	{
		Entity_ToggleSmall(client);
	}
	case SANDBOX_ACTION_RESPAWN:
	{
		Vscript_Respawn(client);
	}
	}
}

int MenuHandler_SandboxMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
	case MenuAction_End:
	{
		if (param1 == view_as<int>(MenuEnd_Selected))
		{
			return 0;
		}

		delete menu;
		return 0;
	}
	case MenuAction_Display:
	{
		char buffer[255];
		FormatEx(buffer, sizeof(buffer), "%T", "SandboxMenuTitle", param1);

		Panel panel = view_as<Panel>(param2);
		panel.SetTitle(buffer);
		return 0;
	}
	case MenuAction_DisplayItem:
	{
		char display[64];
		char info[8];
		
		if (menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display)))
		{
			char item[128];
			FormatEx(item, sizeof(item), "%T", display, param1);
			return RedrawMenuItem(item);
		}

		return 0;
	}
	case MenuAction_Select:
	{
		char info[8];

		if (menu.GetItem(param2, info, sizeof(info)))
		{
			SandboxAction sba = view_as<SandboxAction>(StringToInt(info));
			DoSandboxAction(param1, sba);
			menu.Display(param1, 30);
			return 0;
		}

		LogError("Sandbox Menu: menu.GetItem failed!");
		menu.Display(param1, 30);
		return 0;
	}
	}

	return 0;
}

void SendSandboxMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SandboxMenu, MENU_ACTIONS_ALL);
	menu.ExitBackButton = true;
	
	for (int i = 0; i < view_as<int>(MAX_SANDBOX_ACTIONS); i++)
	{
		char info[8];
		FormatEx(info, sizeof(info), "%i", i);

		menu.AddItem(info, s_SBActionsDisplay[i]);
	}

	menu.Display(client, 30);
}