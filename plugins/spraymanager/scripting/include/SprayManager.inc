#if defined _spraymanager_included
  #endinput
#endif
#define _spraymanager_included

/**
 * @section Forwards
 */

/**
 * Called when a player is banned from using sprays.
 *
 * @param admin         Index of the admin who performed the ban.
 * @param target        Index of the client who was banned.
 * @param length        Duration of the ban in minutes.
 * @param reason        Reason for the ban.
 */
forward void SprayManager_OnClientSprayBanned(int admin, int target, int length, const char[] reason);

/**
 * Called when a player is unbanned from using sprays.
 *
 * @param admin         Index of the admin who performed the unban.
 * @param target        Index of the client who was unbanned.
 */
forward void SprayManager_OnClientSprayUnbanned(int admin, int target);

/**
 * Called when a player's spray is banned.
 *
 * @param admin         Index of the admin who performed the ban.
 * @param target        Index of the client whose spray was banned.
 */
forward void SprayManager_OnClientSprayHashBanned(int admin, int target);

/**
 * Called when a player's spray is unbanned.
 *
 * @param admin         Index of the admin who performed the unban.
 * @param target        Index of the client whose spray was unbanned.
 */
forward void SprayManager_OnClientSprayHashUnbanned(int admin, int target);

/**
 * Called when a player's spray is marked as NSFW.
 *
 * @param admin         Index of the admin who marked the spray (0 if self-marked).
 * @param target        Index of the client whose spray was marked.
 */
forward void SprayManager_OnClientSprayMarkedNSFW(int admin, int target);

/**
 * Called when a player's spray is marked as SFW.
 *
 * @param admin         Index of the admin who marked the spray (0 if self-marked).
 * @param target        Index of the client whose spray was marked.
 */
forward void SprayManager_OnClientSprayMarkedSFW(int admin, int target);

/**
 * @section Natives
 */

/**
 * Checks if a player is currently banned from using sprays.
 *
 * @param client        Client index to check.
 * @return              true if the player is banned, false otherwise.
 */
native bool SprayManager_IsClientSprayBanned(int client);

/**
 * Checks if a player's spray is currently banned.
 *
 * @param client        Client index to check.
 * @return              true if the player's spray is banned, false otherwise.
 */
native bool SprayManager_IsClientSprayHashBanned(int client);

/**
 * Checks if a player's spray is marked as NSFW.
 *
 * @param client        Client index to check.
 * @return              true if the spray is NSFW, false otherwise.
 */
native bool SprayManager_IsClientSprayNSFW(int client);

/**
 * Bans a player from using sprays.
 *
 * @param admin         Admin index who is performing the ban (0 for console).
 * @param target        Client index to ban.
 * @param length        Duration of the ban in minutes (0 for permanent).
 * @param reason        Reason for the ban.
 * @return              true if the ban was successful, false otherwise.
 */
native bool SprayManager_BanClientSpray(int admin, int target, int length, const char[] reason);

/**
 * Unbans a player from using sprays.
 *
 * @param target        Client index to unban.
 * @param admin         Admin index who is performing the unban (0 for console).
 * @return              true if the unban was successful, false otherwise.
 */
native bool SprayManager_UnbanClientSpray(int target, int admin = 0);

/**
 * Bans a player's current spray.
 *
 * @param admin         Admin index who is performing the ban (0 for console).
 * @param target        Client index whose spray should be banned.
 * @return              true if the ban was successful, false otherwise.
 */
native bool SprayManager_BanClientSprayHash(int admin, int target);

/**
 * Unbans a player's current spray.
 *
 * @param admin         Admin index who is performing the unban (0 for console).
 * @param target        Client index whose spray should be unbanned.
 * @return              true if the unban was successful, false otherwise.
 */
native bool SprayManager_UnbanClientSprayHash(int admin, int target);

/**
 * Forces a player to use their spray at a specific location.
 *
 * @param client        Client index who is forcing the spray.
 * @param target        Client index whose spray should be used.
 * @param playSound     Play the spray sound (default true).
 * @return              true if the spray was successful, false otherwise.
 */
native bool SprayManager_ForceSpray(int client, int target, bool playSound = true);

/**
 * Marks a player's spray as NSFW.
 *
 * @param admin         Admin index who is marking the spray (0 for self-marking).
 * @param target        Client index whose spray should be marked.
 * @return              true if the marking was successful, false otherwise.
 */
native bool SprayManager_MarkSprayAsNSFW(int admin, int target);

/**
 * Marks a player's spray as SFW.
 *
 * @param admin         Admin index who is marking the spray (0 for self-marking).
 * @param target        Client index whose spray should be marked.
 * @return              true if the marking was successful, false otherwise.
 */
native bool SprayManager_MarkSprayAsSFW(int admin, int target);

/**
 * Gets a player's spray hash.
 *
 * @param client        Client index.
 * @param buffer        Buffer to store the hash.
 * @param maxlen        Maximum length of the buffer.
 * @return              true if the hash was retrieved, false otherwise.
 */
native bool SprayManager_GetClientSprayHash(int client, char[] buffer, int maxlen);

/**
 * Checks if a player wants to see NSFW sprays.
 *
 * @param client        Client index to check.
 * @return              true if the player wants to see NSFW sprays, false otherwise.
 */
native bool SprayManager_ClientWantsToSeeNSFW(int client);

/**
 * Sets whether a player wants to see NSFW sprays.
 *
 * @param client        Client index.
 * @param wantToSee     true to see NSFW sprays, false otherwise.
 * @return              true if the setting was applied, false otherwise.
 */
native bool SprayManager_SetClientWantsToSeeNSFW(int client, bool wantToSee);

/**
 * Checks if a player has hidden another player's spray.
 *
 * @param client        Client index who potentially hid the spray.
 * @param target        Client index whose spray was potentially hidden.
 * @return              true if the spray is hidden, false otherwise.
 */
native bool SprayManager_HasClientHiddenSpray(int client, int target);

/**
 * Hides or shows a player's spray for another player.
 *
 * @param client        Client index who is hiding/showing the spray.
 * @param target        Client index whose spray is being hidden/shown.
 * @param hide          true to hide the spray, false to show it.
 * @return              true if the operation was successful, false otherwise.
 */
native bool SprayManager_SetClientSprayHidden(int client, int target, bool hide);

/**
 * Gets a player's spray position.
 *
 * @param client        Client index.
 * @param buffer        Buffer to store the spray coordinates.
 * @return              true if the coordinates were retrieved, false otherwise.
 */
native bool SprayManager_GetClientSprayPosition(int client, float buffer[3]);

/**
 * Checks if sprays are currently enabled on the server.
 *
 * @return              true if sprays are enabled, false otherwise.
 */
native bool SprayManager_AreSpraysEnabled();

/**
 * Enables or disables sprays on the server.
 *
 * @param enable        true to enable sprays, false to disable them.
 * @return              true if the operation was successful, false otherwise.
 */
native bool SprayManager_SetSpraysEnabled(bool enable);

/**
 * Gets the remaining time before a player can use their spray again.
 *
 * @param client        Client index.
 * @return              Remaining time in seconds, 0 if the player can use their spray.
 */
native float SprayManager_GetClientNextSprayTime(int client);

/**
 * Sets the time before a player can use their spray again.
 *
 * @param client        Client index.
 * @param time          Time in seconds.
 * @return              true if the operation was successful, false otherwise.
 */
native bool SprayManager_SetClientNextSprayTime(int client, float time);

/**
 * Gets a player's spray ban expiration date.
 *
 * @param client        Client index.
 * @return              Unix timestamp of the expiration date, 0 if permanent, -1 if not banned.
 */
native int SprayManager_GetClientUnbanTimestamp(int client);

/**
 * Gets a player's spray ban reason.
 *
 * @param client        Client index.
 * @param buffer        Buffer to store the reason.
 * @param maxlen        Maximum length of the buffer.
 * @return              true if the reason was retrieved, false otherwise.
 */
native bool SprayManager_GetClientBanReason(int client, char[] buffer, int maxlen);

/**
 * Gets the name of the admin who banned a player.
 *
 * @param client        Client index.
 * @param buffer        Buffer to store the name.
 * @param maxlen        Maximum length of the buffer.
 * @return              true if the name was retrieved, false otherwise.
 */
native bool SprayManager_GetClientBanIssuer(int client, char[] buffer, int maxlen);

/**
 * Removes all currently visible sprays on the server.
 *
 * @return              true if the operation was successful, false otherwise.
 */
native bool SprayManager_RemoveAllSprays();

public SharedPlugin __pl_spraymanager = 
{
    name = "spraymanager",
    file = "SprayManager.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_spraymanager_SetNTVOptional()
{
    MarkNativeAsOptional("SprayManager_IsClientSprayBanned");
    MarkNativeAsOptional("SprayManager_IsClientSprayHashBanned");
    MarkNativeAsOptional("SprayManager_IsClientSprayNSFW");
    MarkNativeAsOptional("SprayManager_BanClientSpray");
    MarkNativeAsOptional("SprayManager_UnbanClientSpray");
    MarkNativeAsOptional("SprayManager_BanClientSprayHash");
    MarkNativeAsOptional("SprayManager_UnbanClientSprayHash");
    MarkNativeAsOptional("SprayManager_ForceSpray");
    MarkNativeAsOptional("SprayManager_MarkSprayAsNSFW");
    MarkNativeAsOptional("SprayManager_MarkSprayAsSFW");
    MarkNativeAsOptional("SprayManager_GetClientSprayHash");
    MarkNativeAsOptional("SprayManager_ClientWantsToSeeNSFW");
    MarkNativeAsOptional("SprayManager_SetClientWantsToSeeNSFW");
    MarkNativeAsOptional("SprayManager_HasClientHiddenSpray");
    MarkNativeAsOptional("SprayManager_SetClientSprayHidden");
    MarkNativeAsOptional("SprayManager_GetClientSprayPosition");
    MarkNativeAsOptional("SprayManager_AreSpraysEnabled");
    MarkNativeAsOptional("SprayManager_SetSpraysEnabled");
    MarkNativeAsOptional("SprayManager_GetClientNextSprayTime");
    MarkNativeAsOptional("SprayManager_SetClientNextSprayTime");
    MarkNativeAsOptional("SprayManager_GetClientUnbanTimestamp");
    MarkNativeAsOptional("SprayManager_GetClientBanReason");
    MarkNativeAsOptional("SprayManager_GetClientBanIssuer");
    MarkNativeAsOptional("SprayManager_RemoveAllSprays");
}
#endif
