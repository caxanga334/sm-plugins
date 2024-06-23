
/**
 * prefix - message before the translation token
 * token - translation token
 */
void Action_WarnAdmins(const char[] prefix, const char[] token)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && CheckCommandAccess(i, "sm_ban", ADMFLAG_BAN))
		{
			PrintToChat(i, "[SM] %s %t", prefix, token);
		}
	}
}

/**
 * prefix - message before the translation token
 * token - translation token
 */
void Action_PublicNotice(const char[] prefix, const char[] token)
{
	PrintToChatAll("[SM] %s %t", prefix, token);
}

void Action_KillClient(int client, const char[] logmsg)
{
	SDKHooks_TakeDamage(client, 0, 0, 50000.0, DMG_FALL, -1);
	LogAction(0, client, "%L was killed for %s.", client, logmsg);
}

void Action_KickClient(int client, const char[] logmsg, const char[] kickmsg)
{
	KickClient(client, kickmsg);
	LogAction(0, client, "%L was kicked for %s.", client, logmsg);
}

void Action_LocalBanClient(int client, int length, const char[] logmsg, const char[] banreason)
{
	BanClient(client, length, BANFLAG_AUTO, banreason, banreason, "l4d_automod");
	LogAction(0, client, "%L was banned for %s.", client, logmsg);
}

void Action_BanClient(int client, int length, const char[] logmsg, const char[] banreason)
{
#if defined _sourcebanspp_included
	if (g_sourcebans)
	{
		// SB++ is available
		SBPP_BanPlayer(0, client, length, banreason);
		LogAction(0, client, "%L was banned for %s.", client, logmsg);
	}
	else
	{
		// SB++ not available
		Action_LocalBanClient(client, length, logmsg, banreason);
		return;
	}
#else
	// Plugin was not compiled with sourcebans++
	Action_LocalBanClient(client, length, logmsg, banreason);
#endif
}

void Action_TakeFriendlyFireAction(Player attacker, Player victim)
{
	attacker.OnFriendlyFireActionTaken();

	Logger_LogFriendlyFire(attacker.index, victim.index);

	if (g_cfg.ff_action == ACTION_LOGONLY)
	{
		return;
	}

	if (g_cfg.ff_action == ACTION_WARN_ADMINS)
	{
		char prefix[MAX_NAME_LENGTH];
		FormatEx(prefix, sizeof(prefix), "%N", attacker.index);
		Action_WarnAdmins(prefix, "Notice_FriendlyFire");
		return;
	}

	if (g_cfg.ff_action == ACTION_PUBLIC_NOTICE)
	{
		char prefix[MAX_NAME_LENGTH];
		FormatEx(prefix, sizeof(prefix), "%N", attacker.index);
		Action_PublicNotice(prefix, "Notice_FriendlyFire");
		return;
	}

	if (g_cfg.ff_action == ACTION_KILL)
	{
		Action_KillClient(attacker.index, "excessive friendly fire damage.")
		return;
	}

	if (g_cfg.ff_action == ACTION_KICK)
	{
		Action_KickClient(attacker.index, "excessive friendly fire damage.", "Excessive friendly fire.");
		return;
	}

	if (g_cfg.ff_action == ACTION_LOCALBAN)
	{
		Action_LocalBanClient(attacker.index, g_cfg.default_ban_length, "excessive friendly fire damage.", "Excessive friendly fire.");
		return;
	}

	if (g_cfg.ff_action == ACTION_BAN)
	{
		Action_BanClient(attacker.index, g_cfg.default_ban_length, "excessive friendly fire damage.", "Excessive friendly fire.");
		return;
	}
}

void Action_OnFriendlyFire(Player attacker, Player victim)
{
	if (attacker.GetAccumulatedFriendlyFireDamage() > g_cfg.max_ff_damage)
	{
		Action_TakeFriendlyFireAction(attacker, victim);
	}
}