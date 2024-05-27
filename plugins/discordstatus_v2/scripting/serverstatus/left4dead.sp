// Left 4 Dead/2 Specific notifications

#if defined _l4dh_included

float g_delay_l4d_gamemode; // Prevent spam
float g_delay_l4d_generic; // generic timer for l4d2

public void L4D_OnGameModeChange(int gamemode)
{
    if(g_delay_l4d_gamemode <= GetGameTime() && g_hasconfigs)
    {
        g_delay_l4d_gamemode = GetGameTime() + 75.0;
        SendMessage_L4D_OnGameMode(gamemode);
    }
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
    if(g_delay_l4d_generic <= GetGameTime() && g_hasconfigs)
    {
        g_delay_l4d_generic = GetGameTime() + 20.0;
        SendMessage_L4D_OnRoundStart();
    }
}

#endif