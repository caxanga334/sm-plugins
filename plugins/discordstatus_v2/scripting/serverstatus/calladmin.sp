
public void CallAdmin_OnReportPost(int client, int target, const char[] reason)
{
    SendMessage_OnCallAdminReport(client, target, reason);
}

public void CallAdmin_OnReportHandled(int client, int id)
{
    SendMessage_OnCallAdminReportHandled(client, id);
}