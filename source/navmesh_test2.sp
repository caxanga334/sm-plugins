#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <caxanga334>
#include <navmesh>

#pragma newdecls required // enforce new SM 1.7 syntax

// ===variables===

public Plugin myinfo = {
	name = "Nav Mesh Tester",
	author = "caxanga334",
	description = "Test plugin for nav mesh",
	version = "1.0.0",
	url = "https://www.gamersalapro.com"
}

public void OnPluginStart() {
	LoadTranslations("common.phrases.txt");

	RegConsoleCmd( "sm_getnavarea", Cmd_NavArea, "Gets a nav area");
	RegConsoleCmd( "sm_telerandomnav", Cmd_RandomTele, "Teleports to a random place using nav mesh");
}

public Action Cmd_NavArea(int client, int args)
{
	float PosVec[3];
	float NavVec[3];
	GetClientAbsOrigin(client, PosVec);

	CNavArea NavArea = NavMesh_GetNearestArea(PosVec, false, 2500.0, false, true);
	NavArea.GetCenter(NavVec);
	
	//NavMeshArea_GetCenter(iNav, NavVec);
	
	ReplyToCommand(client, "ID: %i", NavArea.ID);
	ReplyToCommand(client, "%f %f %f", NavVec[0], NavVec[1], NavVec[2]);
	
	return Plugin_Handled;
}

public Action Cmd_RandomTele(int client, int args)
{
	CNavArea NavArea;
	HidingSpot HideSpot = NavMesh_GetRandomHidingSpot();
	float NavPos[3];
	
	NavArea = HideSpot.GetArea();
	NavArea.GetCenter(NavPos);
	NavPos[2] += 15; 
	TeleportEntity(client, NavPos, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}