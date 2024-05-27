# Discord Server Status (V2)

This plugin send server status messages to discord via webhooks.

Status messages includes:

* Server Start
* Map Changes
* Player join/leave
* Game Specific status
* Call Admin Reports
* SourceTV Demo recordings

# Requirements

* [SteamWorks](https://github.com/KyleSanderson/SteamWorks)
* [REST in Pawn](https://github.com/ErikMinekus/sm-ripext)
* [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696)

**Left 4 DHooks Direct** is only required for Left 4 Dead/2 servers and if the plugin was compiled with Left 4 DHooks Direct support.

# Optional Dependencies

* [SteamPawn](https://github.com/nosoop/SM-SteamPawn)
* [SourceTV Manager](https://github.com/peace-maker/sourcetvmanager)

**SteamPawn** allows the plugins to obtain the server's Fake IP address and port obtained from SDR.

**SourceTV Manager** allows the plugin to send demo recording status notification and the current demo filename and tick.

# Compiling

The following libraries are **required** for the plugin to compile.

* [SteamWorks](https://github.com/KyleSanderson/SteamWorks)
* [REST in Pawn](https://github.com/ErikMinekus/sm-ripext)
* [Discord Webhook API](https://github.com/Sarrus1/DiscordWebhookAPI)
* [AutoExecConfig](https://github.com/Impact123/AutoExecConfig)
  
The following libraries are **optional** for compiling the plugin.

* [SteamPawn](https://github.com/nosoop/SM-SteamPawn)
* [SourceTV Manager](https://github.com/peace-maker/sourcetvmanager)
* [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696)
* [Call Admin](https://github.com/Impact123/CallAdmin)
* [SourceTV Manager](https://github.com/peace-maker/sourcetvmanager)
* [SMLib](https://github.com/bcserv/smlib/tree/transitional_syntax)
