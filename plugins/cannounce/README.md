# caxanga334's Connect Announce

A simple plugin that announces when a player connects to the server.

## ConVars

`sm_cannounce_disconnect_mode` - Controls how the plugins detect client disconnects.

0 Uses OnClientDisconnect. 1 Uses the player_disconnect game event.

Disconnect reason is only available via the game event mode.

`sm_cannounce_prejoin` - Enable announcements of players joining, before they fully connect to the server.

Announcement may be skipped/delayed since it waits for the player to authenticated with Steam.