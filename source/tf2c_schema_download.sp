#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[TF2C] Item Schema Precache",
	author = "caxanga334",
	description = "Precaches the item schema.",
	version = "1.0.0",
	url = "github.com/caxanga334"
};

void LoadFile(const char[] path)
{
	if (FileExists(path))
	{
		PrecacheGeneric(path, true);
		AddFileToDownloadsTable(path);
	}
}

public void OnMapStart()
{
	LoadFile("scripts/items/custom_items_game.txt");
}