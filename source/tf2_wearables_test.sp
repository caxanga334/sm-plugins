#include <sourcemod>
#include <tf2wearables>

public Plugin myinfo = {
	name = "TF2 Wearables API test",
	author = "caxanga334",
	description = "Test plugin for tf2 wearables",
	version = "1.0.0",
	url = "https://github.com/caxanga334/sm-plugins/"
}

public void OnPluginStart() {
	LoadTranslations("common.phrases.txt");

	RegConsoleCmd( "sm_test_wearables", cmd_wearables, "Test wearables");
	RegConsoleCmd( "sm_test_wearables2", cmd_wearables2, "Remove all weapons via wearables API");
}

public Action cmd_wearables(int client, int args) {
	int primary,secondary,melee;
	primary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Primary);
	secondary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary);
	melee = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Melee);
	ReplyToCommand(client,"Weapons: %d %d %d", primary, secondary, melee);
	return Plugin_Handled;
}

public Action cmd_wearables2(int client, int args) {
	int ent;
	for(int i = 0; i < 5; i++) 
	{
		ent = TF2_GetPlayerLoadoutSlot(client, i);
		ReplyToCommand(client, "Removing: %d", ent);
		if (ent != -1)
			TF2_RemoveWeapon(client, ent);
	}
	return Plugin_Handled;
}