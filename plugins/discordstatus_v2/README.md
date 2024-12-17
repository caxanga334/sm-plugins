# Discord Server Status (V2)

This plugin send server status messages to discord via webhooks.

Status messages includes:

* Server Start
* Map Changes
* Player join/leave
* Game Specific Status
* Call Admin Reports
* SourceTV Demo Recordings
* SourceTV Demo Requests
* Native Vote Logging (on supported games)
* Seed Requests

# Requirements

* [REST in Pawn](https://github.com/ErikMinekus/sm-ripext)
* [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696)

**Left 4 DHooks Direct** is only required for Left 4 Dead/2 servers and if the plugin was compiled with Left 4 DHooks Direct support.

# Optional Dependencies

* [SteamPawn](https://github.com/nosoop/SM-SteamPawn)
* [SourceTV Manager](https://github.com/peace-maker/sourcetvmanager)
* [SteamWorks](https://github.com/KyleSanderson/SteamWorks)

**SteamPawn** allows the plugins to obtain the server's Fake IP address and port obtained from SDR.

**SourceTV Manager** allows the plugin to send demo recording status notification and the current demo filename and tick.

**SteamWorks** allows the plugin to obtain the server's IP address while behind NAT.

# Usage

You need to set the webhooks URL and which messages you want to be enabled at `addons/sourcemod/configs/discordstatus.cfg`.

A config file will be auto generated at `cfg/sourcemod/plugin.serverstatus.cfg` with some global settings.

# Commands

| Command |                     Description                     | Default Admin Flag |
|:-------:|:---------------------------------------------------:|:------------------:|
| sm_seed | Sends a seed request message to discord if enabled. |    None (Public)   |

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
