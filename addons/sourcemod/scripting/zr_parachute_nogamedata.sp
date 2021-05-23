/*
 * =============================================================================
 * File:		  zr_parachute.sp
 * Type:		  Base
 * Description:   Plugin's base file.
 *
 * Copyright (C)   Anubis Edition. All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors_fix>

#pragma newdecls required

int g_iVelocity = -1;
int g_iMoney = -1;

char g_sGame[30];

ConVar g_cCvarEnabled = null;
ConVar g_cCvarFallSpeed = null;
ConVar g_cCvarLinear = null;
ConVar g_cCvarMsgType = null;
ConVar g_cCvarCost = null;
ConVar g_cCvarPayBack = null;
ConVar g_cCvarWelcome = null;
ConVar g_cCvarRoundMsg = null;
ConVar g_cCvarModel = null;
ConVar g_cCvarDecrease = null;
ConVar g_cCvarbutton = null;
ConVar g_cCvarModelSettings = null;
ConVar g_cCvarModelDownloads = null;

bool g_bCvarEnabled;
float g_fCvarFallSpeed;
bool g_bCvarLinear;
int g_iCvarMsgType;
int g_iCvarCost;
float g_fCvarPayBack;
bool g_bCvarWelcome;
bool g_bCvarRoundMsg;
bool g_bCvarModel;
float g_fCvarDecrease;
int g_iCvarbutton;
char g_sCvarModelSettings[PLATFORM_MAX_PATH];
char g_sCvarModelDownloads[PLATFORM_MAX_PATH];

int g_iCl_Flags;
int g_iCl_Buttons;
float g_sSpeed[3];
bool g_bIsFallSpeed;

int g_iUse_Button;
char g_sButtonText[265];

bool g_bInUse[MAXPLAYERS+1];
bool g_bHasPara[MAXPLAYERS+1];
bool g_bHasModel[MAXPLAYERS+1];
int g_iParachute_Ent[MAXPLAYERS+1];

char g_sCT_Model[PLATFORM_MAX_PATH];
float g_fCTfAng[3];
float g_fCTfPos[3];
char g_sT_Model[PLATFORM_MAX_PATH];
float g_fTfAng[3];
float g_fTfPos[3];

#define PLUGIN_NAME           "Zr Parachute"
#define PLUGIN_AUTHOR         "Anubis, SWAT_88, n00b"
#define PLUGIN_DESCRIPTION    "To use your parachute press and hold your E(+use) button while falling."
#define PLUGIN_VERSION        "3.0"
#define PLUGIN_URL            "https://github.com/Stewart-Anubis"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	LoadTranslations ("zr_parachute.phrases");

	g_cCvarEnabled = CreateConVar("sm_parachute_enabled","1", "0: disables the plugin - 1: enables the plugin.");
	g_cCvarFallSpeed = CreateConVar("sm_parachute_fallspeed","100", "speed of the fall when you use the parachute.");
	g_cCvarLinear = CreateConVar("sm_parachute_linear","1", "0: disables linear fallspeed - 1: enables it.");
	g_cCvarMsgType = CreateConVar("sm_parachute_msgtype","1", "0: disables Information - 1: Chat - 2: Panel - 3: BottomCenter.");
	g_cCvarCost = CreateConVar("sm_parachute_cost","0", "cost of the parachute (CS ONLY) (If cost = 0 then free for everyone).");
	g_cCvarPayBack = CreateConVar("sm_parachute_payback","75", "how many percent of the parachute cost you get when you sell your parachute (ie. 75% of 1000 = 750$).");
	g_cCvarWelcome = CreateConVar("sm_parachute_welcome","1", "0: disables Welcome Message - 1: enables it.");
	g_cCvarRoundMsg = CreateConVar("sm_parachute_roundmsg","1", "0: disables Round Message - 1: enables it.");
	g_cCvarModel = CreateConVar("sm_parachute_model","1", "0: dont use the model - 1: display the Model.");
	g_cCvarDecrease = CreateConVar("sm_parachute_decrease","50", "0: dont use Realistic velocity-decrease - x: sets the velocity-decrease.");
	g_cCvarbutton = CreateConVar("sm_parachute_button","1", "1: uses button +USE for parachute usage. - 2: uses button +JUMP.");
	g_cCvarModelSettings = CreateConVar("sm_parachute_settings_file", "configs/Zr_Parachute/zr_parachute.txt", "Model configuration file path.");
	g_cCvarModelDownloads = CreateConVar("sm_parachute_downloads_file", "configs/Zr_Parachute/zr_parachute_downloads.txt", "Downloads configuration file path.");

	if (FileExists("cfg/sourcemod/zr_parachute.cfg"))
	{
		ServerCommand("exec sourcemod/zr_parachute.cfg");
	}

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	g_iMoney = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	g_bCvarEnabled = g_cCvarEnabled.BoolValue;
	g_fCvarFallSpeed = g_cCvarFallSpeed.FloatValue;
	g_bCvarLinear = g_cCvarLinear.BoolValue;
	g_iCvarMsgType = g_cCvarMsgType.IntValue;
	g_iCvarCost = g_cCvarCost.IntValue;
	g_fCvarPayBack = g_cCvarPayBack.FloatValue;
	g_bCvarWelcome = g_cCvarWelcome.BoolValue;
	g_bCvarRoundMsg = g_cCvarRoundMsg.BoolValue;
	g_bCvarModel = g_cCvarModel.BoolValue;
	g_fCvarDecrease = g_cCvarDecrease.FloatValue;
	g_iCvarbutton = g_cCvarbutton.IntValue;
	g_cCvarModelSettings.GetString(g_sCvarModelSettings ,sizeof(g_sCvarModelSettings));
	g_cCvarModelDownloads.GetString(g_sCvarModelDownloads ,sizeof(g_sCvarModelDownloads));

	g_cCvarEnabled.AddChangeHook(OnConVarChanged);
	g_cCvarFallSpeed.AddChangeHook(OnConVarChanged);
	g_cCvarLinear.AddChangeHook(OnConVarChanged);
	g_cCvarMsgType.AddChangeHook(OnConVarChanged);
	g_cCvarCost.AddChangeHook(OnConVarChanged);
	g_cCvarPayBack.AddChangeHook(OnConVarChanged);
	g_cCvarWelcome.AddChangeHook(OnConVarChanged);
	g_cCvarRoundMsg.AddChangeHook(OnConVarChanged);
	g_cCvarModel.AddChangeHook(OnConVarChanged);
	g_cCvarDecrease.AddChangeHook(OnConVarChanged);
	g_cCvarbutton.AddChangeHook(OnConVarChanged);
	g_cCvarModelSettings.AddChangeHook(OnConVarChanged);
	g_cCvarModelDownloads.AddChangeHook(OnConVarChanged);

	InitGameMode();
	
	RegConsoleCmd("say",HandleSay,"",FCVAR_GAMEDLL);
	RegConsoleCmd("say_team",HandleSay,"",FCVAR_GAMEDLL);
	HookEvent("player_death",PlayerDeath);
	HookEvent("player_spawn",PlayerSpawn);

	AutoExecConfig(true, "zr_parachute");
}

public void OnConVarChanged(ConVar CVar, const char[] oldVal, const char[] newVal)
{

	if (CVar == g_cCvarEnabled)
	{
		g_bCvarEnabled = g_cCvarEnabled.BoolValue;
		if (!g_bCvarEnabled)
		{
			for(int client = 1 ; client < MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					if (g_bHasPara[client])
					{
						SetEntityGravity(client,1.0);
						SetEntityMoveType(client,MOVETYPE_WALK);
						SellParachuteOff(client, g_iCvarCost);
					}
					CPrintToChat(client,"%T", "Disabled", client);
				}
			}
		}
		else
		{
			for(int client = 1 ; client < MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					CPrintToChat(client,"%T", "Enabled", client);
					if (g_iCvarCost == 0)
					{
						CPrintToChat(client,"%T", "Parachute For Everyone", client);
					}
					else
					{
						CPrintToChat(client,"%T", "Buy Help", client);
						CPrintToChat(client,"%T", "Sell Help", client);
					}
				}
			}
		}
	}
	if (CVar == g_cCvarFallSpeed)
	{
		g_fCvarFallSpeed = g_cCvarFallSpeed.FloatValue;
	}
	if (CVar == g_cCvarLinear)
	{
		g_bCvarLinear = g_cCvarLinear.BoolValue;
		if (!g_bCvarLinear)
		{
			for(int client = 1 ; client < MaxClients; client++)
			{
				if (IsValidClient(client) && g_bHasPara[client]) SetEntityMoveType(client,MOVETYPE_WALK);
			}
		}
	}
	if (CVar == g_cCvarMsgType)
	{
		g_iCvarMsgType = g_cCvarMsgType.IntValue;
	}
	if (CVar == g_cCvarCost)
	{
		g_iCvarCost = g_cCvarCost.IntValue;
		if (g_iCvarCost == 0)
		{
			for(int client = 1 ; client < MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					if (g_bHasPara[client]) SellParachuteOff(client,StringToInt(oldVal));
					CPrintToChat(client,"%T", "Parachute For Everyone", client);
				}
			}
		}
		else
		{
			//if (strcmp(g_sGame,"cstrike",false) != 0) SetConVarInt(g_cCvarCost,0);
		}
	}
	if (CVar == g_cCvarPayBack)
	{
		g_fCvarPayBack = g_cCvarPayBack.FloatValue;
	}
	if (CVar == g_cCvarWelcome)
	{
		g_bCvarWelcome = g_cCvarWelcome.BoolValue;
	}
	if (CVar == g_cCvarRoundMsg)
	{
		g_bCvarRoundMsg = g_cCvarRoundMsg.BoolValue;
	}
	if (CVar == g_cCvarModel)
	{
		g_bCvarModel = g_cCvarModel.BoolValue;
		if (!g_bCvarModel)
		{
			for(int client = 1 ; client < MaxClients; client++)
			{
				if (IsValidClient(client)) CloseParachute(client);
			}
		}
	}
	if (CVar == g_cCvarDecrease)
	{
		g_fCvarDecrease = g_cCvarDecrease.FloatValue;
	}
	if (CVar == g_cCvarbutton)
	{
		g_iCvarbutton = g_cCvarbutton.IntValue;
		if (g_iCvarbutton == 1) SetButton(1);
		else if(g_iCvarbutton == 2) SetButton(2);
	}
	if (CVar == g_cCvarModelSettings)
	{
		g_cCvarModelSettings.GetString(g_sCvarModelSettings ,sizeof(g_sCvarModelSettings));
	}
	if (CVar == g_cCvarModelDownloads)
	{
		g_cCvarModelDownloads.GetString(g_sCvarModelDownloads ,sizeof(g_sCvarModelDownloads));
	}
}

void InitGameMode()
{
	GetGameFolderName(g_sGame, 29);
	if(StrEqual(g_sGame,"tf",false)){
		SetConVarInt(g_cCvarbutton,2);
		SetButton(2);
	}
	else{
		SetButton(1);
	}
}

public void OnMapStart()
{
	char s_Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, s_Path, sizeof(s_Path), "%s", g_sCvarModelDownloads);
	File_ReadDownloadList(s_Path);
	BuildPath(Path_SM, s_Path, sizeof(s_Path), "%s", g_sCvarModelSettings);
	InitModel(s_Path);
}

stock bool InitModel(const char[] path)
{
	Handle h_kv;
	h_kv = CreateKeyValues("Zr_Parachute");

	if (!FileToKeyValues(h_kv, path))
	{
		SetFailState("Couldn't parse file %s", path);
		return false;
	}

	if(KvJumpToKey(h_kv, "CT_Model"))
	{
		KvGetString(h_kv, "Model", g_sCT_Model, sizeof(g_sCT_Model));
		KvGetVector(h_kv, "Position", g_fCTfPos);
		KvGetVector(h_kv, "Angles", g_fCTfAng);
		KvRewind(h_kv);
	}
	if(KvJumpToKey(h_kv, "T_Model"))
	{
		KvGetString(h_kv, "Model", g_sT_Model, sizeof(g_sT_Model));
		KvGetVector(h_kv, "Position", g_fTfPos);
		KvGetVector(h_kv, "Angles", g_fTfAng);
		KvRewind(h_kv);
	}
	CloseHandle(h_kv);
	return true;
}

public void OnClientPutInServer(int client)
{
	g_bInUse[client] = false;
	g_bHasPara[client] = false;
	g_bHasModel[client] = false;
	CreateTimer (20.0, WelcomeMsg, client);
}

public void OnClientDisconnect(int client)
{
	CloseParachute(client);
}

public Action PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_iCvarCost == 0){
		CreateTimer (1.0, RoundMsg, client);
	}
	return Plugin_Continue;
}

public Action PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bHasPara[client] = false;
	EndPara(client);
	return Plugin_Continue;
}

public Action RoundMsg(Handle timer, any client)
{
	if(g_bCvarRoundMsg){
		if(IsValidClient(client))
			PrintMsg(client,"Have Got Free Parachute");
	}
	return Plugin_Continue;
}

void StartPara(int client, bool open)
{
	float velocity[3];
	float fallspeed;
	if (g_iVelocity == -1) return;
	if((g_bCvarEnabled && g_bHasPara[client]) || (g_bCvarEnabled && g_iCvarCost == 0)){
		fallspeed = g_fCvarFallSpeed*(-1.0);
		GetEntDataVector(client, g_iVelocity, velocity);
		if(velocity[2] >= fallspeed){
			g_bIsFallSpeed = true;
		}
		if(velocity[2] < 0.0)
		{
			if(g_bIsFallSpeed && !g_bCvarLinear)
			{
			}
			else if((g_bIsFallSpeed && g_bCvarLinear) || g_fCvarDecrease == 0.0)
			{
				velocity[2] = fallspeed;
			}
			else
			{
				velocity[2] = velocity[2] + g_fCvarDecrease;
			}
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			SetEntDataVector(client, g_iVelocity, velocity);
			SetEntityGravity(client,0.01);
			if(open) OpenParachute(client);
		}
	}
}

void EndPara(int client)
{
	if(g_bCvarEnabled){
		SetEntityGravity(client,1.0);
		g_bInUse[client]=false;
		CloseParachute(client);
	}
}

void OpenParachute(int client)
{
	if(g_bHasModel[client]) return;

	if(g_bCvarModel)
	{
		g_iParachute_Ent[client] = CreateEntityByName("prop_dynamic_override");
		if(GetClientTeam(client) == 3) DispatchKeyValue(g_iParachute_Ent[client],"model", g_sCT_Model);
		else DispatchKeyValue(g_iParachute_Ent[client],"model", g_sT_Model);
		SetEntityMoveType(g_iParachute_Ent[client], MOVETYPE_NOCLIP);
		DispatchSpawn(g_iParachute_Ent[client]);
		
		g_bHasModel[client]=true;
		TeleportParachute(client);
	}
}

public void TeleportParachute(int client)
{
	if(g_bHasModel[client] && IsValidEntity(g_iParachute_Ent[client]))
	{
		float Client_Origin[3];
		float Client_Angles[3];
		float Parachute_Angles[3] = {0.0, 0.0, 0.0};
		float fForward[3], fRight[3], fUp[3];
		GetClientAbsOrigin(client,Client_Origin);
		GetClientAbsAngles(client,Client_Angles);
		if(GetClientTeam(client) == 3)
		{
			Client_Angles[0] += g_fCTfAng[0];
			Client_Angles[1] += g_fCTfAng[1];
			Client_Angles[2] += g_fCTfAng[2];
			GetAngleVectors(Client_Angles, fForward, fRight, fUp);

			Client_Origin[0] += fRight[0]*g_fCTfPos[0] + fForward[0]*g_fCTfPos[1] + fUp[0]*g_fCTfPos[2];
			Client_Origin[1] += fRight[1]*g_fCTfPos[0] + fForward[1]*g_fCTfPos[1] + fUp[1]*g_fCTfPos[2];
			Client_Origin[2] += fRight[2]*g_fCTfPos[0] + fForward[2]*g_fCTfPos[1] + fUp[2]*g_fCTfPos[2];
		}
		else
		{
			Client_Angles[0] += g_fTfAng[0];
			Client_Angles[1] += g_fTfAng[1];
			Client_Angles[2] += g_fTfAng[2];
			GetAngleVectors(Client_Angles, fForward, fRight, fUp);

			Client_Origin[0] += fRight[0]*g_fTfPos[0] + fForward[0]*g_fTfPos[1] + fUp[0]*g_fTfPos[2];
			Client_Origin[1] += fRight[1]*g_fTfPos[0] + fForward[1]*g_fTfPos[1] + fUp[1]*g_fTfPos[2];
			Client_Origin[2] += fRight[2]*g_fTfPos[0] + fForward[2]*g_fTfPos[1] + fUp[2]*g_fTfPos[2];
		}
		Parachute_Angles[1] = Client_Angles[1];
		TeleportEntity(g_iParachute_Ent[client], Client_Origin, Parachute_Angles, NULL_VECTOR);
	}
}

void CloseParachute(int client)
{
	if(g_bHasModel[client] && IsValidEntity(g_iParachute_Ent[client]))
	{
		RemoveEdict(g_iParachute_Ent[client]);
		g_bHasModel[client]=false;
	}
}

void Check(int client)
{
	if(g_bCvarEnabled){
		GetEntDataVector(client,g_iVelocity,g_sSpeed);
		g_iCl_Flags = GetEntityFlags(client);
		if(g_sSpeed[2] >= 0 || (g_iCl_Flags & FL_ONGROUND)) EndPara(client);
	}
}

public void OnGameFrame()
{
	if(!g_bCvarEnabled) return;
	for(int i = 1 ; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			g_iCl_Buttons = GetClientButtons(i);
			if (g_iCl_Buttons & g_iUse_Button)
			{
				if (!g_bInUse[i])
				{
					g_bInUse[i] = true;
					g_bIsFallSpeed = false;
					StartPara(i,true);
				}
				StartPara(i,false);
				TeleportParachute(i);
			}
			else
			{
				if (g_bInUse[i])
				{
					g_bInUse[i] = false;
					EndPara(i);
				}
			}
			Check(i);
		}
	}
}

stock int GetNextSpaceCount(char[] text, int CurIndex)
{
    int Count=0;
    int len = strlen(text);
    for(int i=CurIndex;i<len;i++){
        if(text[i] == ' ') return Count;
        else Count++;
    }
    return Count;
}

stock void SendHintText(int client, char[] text, any ...)
{
    char message[192];

    VFormat(message,191,text, 2);
    int len = strlen(message);
    if(len > 30){
        int LastAdded=0;
        
        for(int i=0;i<len;i++){
            if((message[i]==' ' && LastAdded > 30 && (len-i) > 10) || ((GetNextSpaceCount(text,i+1) + LastAdded)  > 34)){
                message[i] = '\n';
                LastAdded = 0;
            }
            else LastAdded++;
        }
    }
    Handle HintMessage = StartMessageOne("HintText",client);
    BfWriteByte(HintMessage,-1);
    BfWriteString(HintMessage,message);
    EndMessage();
}

public void PrintMsg(int client, char[] msg)
{
	char translation[256];
	if(!g_bCvarEnabled) return;
	Format(translation, 255, "%T", msg, client, g_sButtonText);
	if(g_iCvarMsgType == 1){		
		CPrintToChat(client,"%s", translation);
	}
	else if(g_iCvarMsgType == 2) {
		Handle panel = CreatePanel();
		DrawPanelText(panel,translation);
		SendPanelToClient(panel,client,PanelHandle,5);
	}
	else if(g_iCvarMsgType == 3){
		SendHintText(client,translation);
	}
}

public int PanelHandle(Handle menu, MenuAction action, int param1, int param2)
{
}

public void BuyParachute(int client)
{
	int money;
	int cost;
	if (g_iMoney == -1) return;
	if (g_bHasPara[client] == false){
		money = GetEntData(client,g_iMoney);
		cost = g_iCvarCost;
		if (cost == 0){
			PrintMsg(client,"Have Free Parachute");
		}
		else{
			if((money - cost)<0){
				PrintMsg(client,"No Money");
			}
			else{
				g_bHasPara[client] = true;
				SetEntData(client,g_iMoney,money-cost);
				PrintMsg(client,"Have Bought Parachute");
			}
		}
	}
	else{
		PrintMsg(client,"Have Parachute");
	}
	
}

public void SellParachute(int client)
{
	int money;
	float payback;
	char pb[10];
	if (g_iMoney == -1) return;
	if (g_bHasPara[client] == true){
		money = GetEntData(client,g_iMoney);
		payback = g_iCvarCost*(g_fCvarPayBack/100);
		if ((money + payback) > 16000){
			SetEntData(client,g_iMoney,16000);
		}
		else{
			FloatToString(payback,pb,9);
			SetEntData(client,g_iMoney,money+StringToInt(pb));
		}
		g_bHasPara[client] = false;
		PrintMsg(client,"Sold Parachute");
	}
	else{
		if (g_iCvarCost == 0){
			PrintMsg(client,"Sell Free Parachute");
		}
		else{
			PrintMsg(client,"No Parachute");
		}
	}
}

public Action HandleSay(int client, int args)
{
	char line[30];
	if(!g_bCvarEnabled || g_iCvarCost == 0) return Plugin_Continue;
	if (args > 0){
		GetCmdArg(1,line,sizeof(line));
		if (strcmp(g_sGame,"csgo",false)==0){
			if (StrEqual(line, "!bp", false) || StrEqual(line, "!buy_parachute", false)) BuyParachute(client);
			else if(StrEqual(line, "!sp", false) || StrEqual(line, "!sell_parachute", false)) SellParachute(client);
		}
		else{
			SetConVarInt(g_cCvarCost,0);
			if (StrEqual(line, "!bp", false) || StrEqual(line, "!buy_parachute", false)) PrintMsg(client,"Have Free Parachute");
			else if(StrEqual(line, "!sp", false) || StrEqual(line, "!sell_parachute", false)) PrintMsg(client,"Sell Free Parachute");
		}
	}
	return Plugin_Continue;
}

public Action WelcomeMsg(Handle timer, any client)
{
	if(!g_bCvarEnabled) return Plugin_Continue;

	if (g_bCvarWelcome && IsValidClient(client))
	{
		CPrintToChat(client,"%T", "Welcome", client);
		if (g_iCvarCost == 0){
			CPrintToChat(client,"%T", "Parachute For Everyone", client);
		}
		else{
			CPrintToChat(client,"%T", "Buy Help", client);
			CPrintToChat(client,"%T", "Sell Help", client);
		}
	}
	return Plugin_Continue;
}

public void SellParachuteOff(int client, int cost)
{
	int money;
	float payback;
	char pb[10];
	if (g_iMoney == -1) return;
	if (g_bHasPara[client] == true){
		money = GetEntData(client,g_iMoney);
		payback = cost*(g_fCvarPayBack/100);
		if ((money + payback) > 16000){
			SetEntData(client,g_iMoney,16000);
		}
		else{
			FloatToString(payback,pb,9);
			SetEntData(client,g_iMoney,money+StringToInt(pb));
		}
		g_bHasPara[client] = false;
	}
}

public void SetButton(int button)
{
	if (button == 1){
		g_iUse_Button = IN_USE;
		g_sButtonText = "E";
	}
	else if(button == 2){
		g_iUse_Button = IN_JUMP;
		g_sButtonText = "Space";
	}
}

stock bool IsValidClient(int client, bool bzrAllowBots = false, bool bzrAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bzrAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bzrAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}

stock bool File_ReadDownloadList(const char[] path)
{
	Handle file = OpenFile(path, "r");
	
	if (file  == INVALID_HANDLE) {
		return false;
	}

	char buffer[PLATFORM_MAX_PATH];
	while (!IsEndOfFile(file)) {
		ReadFileLine(file, buffer, sizeof(buffer));
		
		int pos;
		pos = StrContains(buffer, "//");
		if (pos != -1) {
			buffer[pos] = '\0';
		}
		
		pos = StrContains(buffer, "#");
		if (pos != -1) {
			buffer[pos] = '\0';
		}

		pos = StrContains(buffer, ";");
		if (pos != -1) {
			buffer[pos] = '\0';
		}
		
		TrimString(buffer);
		
		if (buffer[0] == '\0') {
			continue;
		}

		File_AddToDownloadsTable(buffer);
	}

	CloseHandle(file);
	
	return true;
}

char _smlib_empty_twodimstring_array[][] = { { '\0' } };
stock void File_AddToDownloadsTable(char[] path, bool recursive = true, const char[][] ignoreExts = _smlib_empty_twodimstring_array, int size = 0)
{
	if (path[0] == '\0') {
		return;
	}

	if (FileExists(path)) {
		
		char fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));
		
		if (StrEqual(fileExtension, "bz2", false) || StrEqual(fileExtension, "ztmp", false)) {
			return;
		}
		
		if (Array_FindString(ignoreExts, size, fileExtension) != -1) {
			return;
		}

		AddFileToDownloadsTable(path);
		
		if (StrEqual(fileExtension, "mdl", false))
		{
			PrecacheModel(path, true);
		}
	}
	
	else if (recursive && DirExists(path)) {

		char dirEntry[PLATFORM_MAX_PATH];
		Handle __dir = OpenDirectory(path);

		while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

			if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
				continue;
			}
			
			Format(dirEntry, sizeof(dirEntry), "%s/%s", path, dirEntry);
			File_AddToDownloadsTable(dirEntry, recursive, ignoreExts, size);
		}
		
		CloseHandle(__dir);
	}
	else if (FindCharInString(path, '*', true)) {
		
		char fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));

		if (StrEqual(fileExtension, "*")) {

			char
				dirName[PLATFORM_MAX_PATH],
				fileName[PLATFORM_MAX_PATH],
				dirEntry[PLATFORM_MAX_PATH];

			File_GetDirName(path, dirName, sizeof(dirName));
			File_GetFileName(path, fileName, sizeof(fileName));
			StrCat(fileName, sizeof(fileName), ".");

			Handle __dir = OpenDirectory(dirName);
			while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

				if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
					continue;
				}

				if (strncmp(dirEntry, fileName, strlen(fileName)) == 0) {
					Format(dirEntry, sizeof(dirEntry), "%s/%s", dirName, dirEntry);
					File_AddToDownloadsTable(dirEntry, recursive, ignoreExts, size);
				}
			}

			CloseHandle(__dir);
		}
	}

	return;
}

stock void File_GetExtension(const char[] path, char[] buffer, int size)
{
	int extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}

stock bool File_GetDirName(const char[] path, char[] buffer, int size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	int pos_start = FindCharInString(path, '/', true);
	
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
		
		if (pos_start == -1) {
			buffer[0] = '\0';
			return;
		}
	}
	
	strcopy(buffer, size, path);
	buffer[pos_start] = '\0';
}

stock bool File_GetFileName(const char[] path, char[] buffer, int size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	File_GetBaseName(path, buffer, size);
	
	int pos_ext = FindCharInString(buffer, '.', true);

	if (pos_ext != -1) {
		buffer[pos_ext] = '\0';
	}
}

stock int Array_FindString(const char[][] array, int size, const char[] str, bool caseSensitive=true, int start=0)
{
	if (start < 0) {
		start = 0;
	}

	for (int i=start; i < size; i++) {

		if (StrEqual(array[i], str, caseSensitive)) {
			return i;
		}
	}
	
	return -1;
}

stock bool File_GetBaseName(const char[] path, char[] buffer, int size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	int pos_start = FindCharInString(path, '/', true);
	
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
	}
	
	pos_start++;
	
	strcopy(buffer, size, path[pos_start]);
}