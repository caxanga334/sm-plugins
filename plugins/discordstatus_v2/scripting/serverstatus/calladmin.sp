
#if defined _calladmin_included

public void CallAdmin_OnReportPost(int client, int target, const char[] reason)
{
	if (!cfg_CallAdmin.enabled)
		return;

	SendMessage_OnCallAdminReport(client, target, reason);
}

public void CallAdmin_OnReportHandled(int client, int id)
{
	if (!cfg_CallAdmin.enabled)
		return;

	SendMessage_OnCallAdminReportHandled(client, id);
}

#endif