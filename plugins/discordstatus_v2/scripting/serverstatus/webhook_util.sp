

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

Webhook Init_Webhook(const char[] contents = "", const char[] username = "Server Status")
{
	Webhook wh = new Webhook(contents);
	wh.SetUsername(username);
	return wh;
}