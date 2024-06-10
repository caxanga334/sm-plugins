

stock bool IsWebhookURLValid(const char[] url)
{
	if (StrContains(url, "discord.com/api/webhooks/") == -1)
	{
		return false;
	}

	return true;
}

/**
 * 
 * --- Adds space between two embed fields
 * 
 */
stock void AddSpacer(Embed &embed)
{
	EmbedField fieldspacer = new EmbedField("\n_ _", "\n_ _", false);
	embed.AddField(fieldspacer);
}

void FormatMessage_L4D_NativeVote(const char[] issue, const char[] option, char[] outissue, int outissue_max, char[] outoption, int outoption_max)
{
	if (strcmp(issue, "ChangeDifficulty", false) == 0)
	{
		strcopy(outissue, outissue_max, "Change Difficulty");
		strcopy(outoption, outoption_max, option);
	}
	else if (strcmp(issue, "ChangeMission", false) == 0)
	{
		strcopy(outissue, outissue_max, "Change Mission");
		strcopy(outoption, outoption_max, option);
	}
	else if (strcmp(issue, "ChangeChapter", false) == 0)
	{
		strcopy(outissue, outissue_max, "Change Chapter");
		strcopy(outoption, outoption_max, option);
	}
	else if (strcmp(issue, "Kick", false) == 0)
	{
		strcopy(outissue, outissue_max, "Kick Player");

		int userid = StringToInt(option);

		if (userid > 0)
		{
			int target = GetClientOfUserId(userid);

			if (target > 0 && IsClientInGame(target))
			{
				char SID[MAX_AUTHID_LENGTH];
				
				if (!GetClientAuthId(target, AuthId_SteamID64, SID, sizeof(SID)))
				{
					SID = "";
				}

				FormatEx(outoption, outoption_max, "Target: %N (%s)", target, SID);
			}
		}
		else
		{
			FormatEx(outoption, outoption_max, "UserID: %s", option);
		}
	}
	else if (strcmp(issue, "RestartGame", false) == 0)
	{
		strcopy(outissue, outissue_max, "Restart Game");
		strcopy(outoption, outoption_max, "");
	}
	else if (strcmp(issue, "ReturnToLobby", false) == 0)
	{
		strcopy(outissue, outissue_max, "Return to Lobby");
		strcopy(outoption, outoption_max, "");
	}
	else if (strcmp(issue, "ChangeAllTalk", false) == 0)
	{
		strcopy(outissue, outissue_max, "Change All Talk");
		strcopy(outoption, outoption_max, "");
	}
	else
	{
		LogError("Unhandled vote issue: %s option: %s", issue, option);
	}
}

FormatMessage_Time(const int time, char[] out, const int size)
{
    int days = time / 1440;
    int hours = time / 60;
    hours = hours % 24;
    int minutes = time - (days * 1440) - (hours * 60);

	FormatEx(out, size, "%i Days, %i Hours and %i Minutes.", days, hours, minutes);
}