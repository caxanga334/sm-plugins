
static char s_default_avatar_url[WEBHOOK_URL_MAX_SIZE];

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

void OnDefaultWebHookAvatarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    strcopy(s_default_avatar_url, sizeof(s_default_avatar_url), newValue);
    LogMessage("Webhook Avatar URL changed to %s", newValue);
}

Webhook Init_Webhook(const char[] contents = "", const char[] username = "Server Status", const char[] avatarURL = "")
{
    Webhook wh = new Webhook(contents);
    wh.SetUsername(username);

    if (strlen(avatarURL) > 5)
    {
        wh.SetAvatarURL(avatarURL);
    }
    else if (strlen(s_default_avatar_url) > 5)
    {
        wh.SetAvatarURL(s_default_avatar_url);
    }

    return wh;
}