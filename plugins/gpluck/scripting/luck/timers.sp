

void Timer_RunBotLogic(Handle timer)
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient) && IsFakeClient(iClient) && !IsClientSourceTV(iClient) && !IsClientReplay(iClient))
        {
            LuckClient lc = LuckClient(iClient);

            if (lc.CanRoll() && GetURandomFloat() <= 0.7)
            {
                lc.AutoRoll();
                break;
            }
        }
    }
}