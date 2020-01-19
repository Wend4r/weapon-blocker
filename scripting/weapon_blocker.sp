#pragma semicolon 1

#include <sourcemod>

#include <adminmenu>
#include <cstrike>
#include <regex>
#include <sdktools>
#include <sdkhooks>

// #include <weapon_blocker>

#pragma newdecls required
#pragma tabsize 4

enum struct WeaponData
{
	bool Block;
	int  ClipCount;
	int  AmmoCount;
	int  AccessFlags;
	int  RoundFlags;
	bool RoundIsKnife;
}

WeaponData		g_iWeaponData[CSWeapon_MAX_WEAPONS_NO_KNIFES];

int				g_iPlayerFlags[MAXPLAYERS + 1],
				m_iClip1, m_iPrimaryReserveAmmoCount, m_hMyWeapons, m_iItemDefinitionIndex, m_iAccountID;

char			g_sMap[64];

CSWeaponID		g_iCustomRound;

ConVar			g_hItemsProhibited;

GlobalForward	g_hWB_WeaponDataUpdate, g_hWB_OnSettingsIsLoaded, g_hWB_OnCustomRoundStart;

KeyValues		g_hKv;

TopMenu			g_hAdminMenu;

// weapon_blocker.sp
public Plugin myinfo =
{
	name = "[Weapon Blocker] Core",
	author = "Wend4r",
	version = "1.0 Alpha"
};

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] sError, int iErrLen)
{
	g_hWB_WeaponDataUpdate = new GlobalForward("WB_WeaponDataUpdate", ET_Ignore, Param_Cell, Param_Cell);
	g_hWB_OnSettingsIsLoaded = new GlobalForward("WB_OnSettingsIsLoaded", ET_Ignore, Param_Cell);
	g_hWB_OnCustomRoundStart = new GlobalForward("WB_OnCustomRoundStart", ET_Ignore, Param_Cell);

	CreateNative("WB_GetWeaponData", WB_GetWeaponData);
	CreateNative("WB_SetWeaponData", WB_SetWeaponData);
	CreateNative("WB_GetClientAccessFlags", WB_GetClientAccessFlags);
	CreateNative("WB_SetClientAccessFlags", WB_SetClientAccessFlags);
	CreateNative("WB_GetCustomRound", WB_GetCustomRound);
	CreateNative("WB_SetCustomRound", WB_SetCustomRound);

	RegPluginLibrary("weapon_blocker");

	HookEvent("round_prestart", OnRoundStartPre, EventHookMode_PostNoCopy);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

	return APLRes_Success;
}

int WB_GetWeaponData(Handle hPlugin, int iArgs)
{
	CSWeaponID iWeaponID = GetNativeCell(1);

	switch(GetNativeCell(2))
	{
		case 0:	// WeaponData.Block
		{
			return g_iWeaponData[iWeaponID].Block;
		}

		case 1:	// WeaponData.ClipCount
		{
			return g_iWeaponData[iWeaponID].ClipCount;
		}

		case 2:	// WeaponData.AmmoCount
		{
			return g_iWeaponData[iWeaponID].AmmoCount;
		}

		case 3:	// WeaponData.AccessFlags
		{
			return g_iWeaponData[iWeaponID].AccessFlags;
		}

		case 4:	// WeaponData.RoundFlags
		{
			return g_iWeaponData[iWeaponID].RoundFlags;
		}

		case 5:	// WeaponData.RoundIsKnife
		{
			return g_iWeaponData[iWeaponID].RoundIsKnife;
		}
	}

	return 0;
}

int WB_SetWeaponData(Handle hPlugin, int iArgs)
{
	int iValue = GetNativeCell(3);

	CSWeaponID iWeaponID = GetNativeCell(1);

	switch(GetNativeCell(2))
	{
		case 0:	// WeaponData.Block
		{
			static char sValue[256],
						sReplace[16];

			g_hItemsProhibited.GetString(sValue, sizeof(sValue));

			int iDefIndex = CS_WeaponIDToItemDefIndex(iWeaponID);

			IntToString(iDefIndex, sReplace, sizeof(sReplace));

			int iLen = StrContains(sValue, sReplace, false);

			if(iValue)
			{
				if(iLen > 0 || !sValue[0])
				{
					Format(sValue, sizeof(sValue), "%s,%i", sValue, iDefIndex);
				}
				else
				{
					IntToString(iDefIndex, sValue, sizeof(sValue));
				}
			}
			else
			{
				if(iLen != -1)
				{
					if(iLen)
					{
						Format(sReplace, sizeof(sReplace), ",%s", sReplace);
					}

					ReplaceString(sValue[iLen], sizeof(sValue) - iLen, sReplace, NULL_STRING);
				}
			}

			g_hItemsProhibited.SetString(sValue);
			g_iWeaponData[iWeaponID].Block = iValue != 0;
		}

		case 1:	// WeaponData.ClipCount
		{
			g_iWeaponData[iWeaponID].ClipCount = iValue;
		}

		case 2:	// WeaponData.AmmoCount
		{
			g_iWeaponData[iWeaponID].AmmoCount = iValue;
		}

		case 3:	// WeaponData.AccessFlags
		{
			g_iWeaponData[iWeaponID].AccessFlags = iValue;
		}

		case 4:	// WeaponData.RoundFlags
		{
			g_iWeaponData[iWeaponID].RoundFlags = iValue;
		}

		case 5:	// WeaponData.RoundIsKnife
		{
			g_iWeaponData[iWeaponID].RoundIsKnife = iValue != 0;
		}
	}
}

int WB_GetClientAccessFlags(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	if(IsClientInGame(iClient))
	{
		return g_iPlayerFlags[iClient];
	}

	return 0;
}

int WB_SetClientAccessFlags(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	if(IsClientInGame(iClient))
	{
		if(!g_iPlayerFlags[iClient])
		{
			SDKHookCanUse(iClient);
		}

		g_iPlayerFlags[iClient] = GetNativeCell(2);
	}
}

int WB_GetCustomRound(Handle hPlugin, int iArgs)
{
	return view_as<int>(g_iCustomRound);
}

int WB_SetCustomRound(Handle hPlugin, int iArgs)
{
	if(GetNativeCell(2))
	{
		static char sAlias[64];

		CS_WeaponIDToAlias(GetNativeCell(1), sAlias, sizeof(sAlias));

		SetCustomRound(0, sAlias);
	}
	else
	{
		g_iCustomRound = GetNativeCell(1);
	}
}

public void OnPluginStart()
{
	LoadTranslations("weapon_blocker.phrases");

	g_hItemsProhibited = FindConVar("mp_items_prohibited");

	m_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	m_iPrimaryReserveAmmoCount = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryReserveAmmoCount");
	m_hMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	m_iItemDefinitionIndex = FindSendPropInfo("CEconEntity", "m_iItemDefinitionIndex");
	m_iAccountID = FindSendPropInfo("CEconEntity", "m_iAccountID");

	if(LibraryExists("adminmenu")) 
	{
		g_hAdminMenu = GetAdminTopMenu();
	}

	OnMapStart();
	RegAdminCmd("sm_weapon_blocker_reload", OnConfigReload, ADMFLAG_CONVARS, "Config reload weapon_blocker.ini"); 
}

public void OnLibraryRemoved(const char[] sName)
{
	if(!strcmp(sName, "adminmenu")) 
	{
		g_hAdminMenu = null;
	}
}

public void OnAdminMenuReady(Handle hMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(hMenu);

	if(hTopMenu)
	{
		if(!g_hAdminMenu)
		{
			g_hAdminMenu = hTopMenu;
		}

		TopMenuObject iCategory = hTopMenu.FindCategory("ServerCommands");

		if(iCategory)
		{
			static char sCmdName[76] = "sm_wb_start_";

			for(CSWeaponID i = CSWeapon_MAX_WEAPONS_NO_KNIFES; --i;)
			{
				if(g_iWeaponData[i].RoundFlags)
				{
					CS_WeaponIDToAlias(i, sCmdName[12], sizeof(sCmdName) - 12);
					hTopMenu.AddItem(sCmdName[3], Handler_AdminStart, iCategory, sCmdName, g_iWeaponData[i].RoundFlags);
				}
			}
		}
	}
}

void Handler_AdminStart(TopMenu hMenu, TopMenuAction iAction, TopMenuObject iObjectId, int iClient, char[] sBuffer, int iMaxLength)
{
	static char sItem[72];

	if(iAction == TopMenuAction_DrawOption && g_iCustomRound)
	{
		sBuffer[0] = ITEMDRAW_DISABLED;
	}
	else if(iAction == TopMenuAction_DisplayOption)
	{
		SetGlobalTransTarget(iClient);

		hMenu.GetObjName(iObjectId, sItem, sizeof(sItem));
		FormatEx(sBuffer, iMaxLength, "%t", "AdminMenu_Item", sItem[9]);
	}
	else if(iAction == TopMenuAction_SelectOption)
	{
		hMenu.GetObjName(iObjectId, sItem, sizeof(sItem));
		SetCustomRound(iClient, sItem[9]);
	}
}

void SetCustomRound(int iClient, const char[] sAlias)
{
	if(!g_iCustomRound)
	{
		g_iCustomRound = CS_AliasToWeaponID(sAlias);

		ShowActivity2(iClient, "[SM] ", "%t", "Start_CustomRound", sAlias);
		LogAction(iClient, -1, "\"%L\" setup a %s round for the next round.", iClient, sAlias);
	}
}

Action OnConfigReload(int iClient, int iArgs)
{
	OnMapStart();
	OnRoundStartPre(null, NULL_STRING, false);
	ReplyToCommand(iClient, "[WB] Settings cache has been refreshed");

	return Plugin_Handled;
}

public void OnMapStart()
{
	static char sPath[PLATFORM_MAX_PATH];

	if(!sPath[0])
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/weapon_blocker.ini");
	}
	else
	{
		g_hKv.Close();
	}

	if(!(g_hKv = new KeyValues("Weapon Blocker")).ImportFromFile(sPath))
	{
		SetFailState("%s - is not found", sPath);
	}

	GetCurrentMapEx(g_sMap, sizeof(g_sMap));

	if(g_iCustomRound)
	{
		g_iCustomRound = CSWeapon_NONE;

		UnhookEvent("round_end", OnRoundEnd);
	}
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(!g_iCustomRound && !strncmp(sClassname, "weapon_", 7))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, OnWeaponSpawnPost);
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient) && (g_iPlayerFlags[iClient] |= GetUserFlagBits(iClient)))
	{
		SDKHookCanUse(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	g_iPlayerFlags[iClient] = 0;
}

void OnWeaponSpawnPost(int iEntity)
{
	RequestFrame(OnWeaponSpawnPostPost, iEntity);

	SDKUnhook(iEntity, SDKHook_SpawnPost, OnWeaponSpawnPost);
}

void OnWeaponSpawnPostPost(int iEntity)
{
	if(IsValidEntity(iEntity))
	{
		CSWeaponID iWeaponID = CS_ItemDefIndexToID(GetEntData(iEntity, m_iItemDefinitionIndex));

		if(CSWeapon_NONE < iWeaponID < CSWeapon_MAX_WEAPONS_NO_KNIFES)
		{
			if(g_iWeaponData[iWeaponID].ClipCount != -1)
			{
				SetEntData(iEntity, m_iClip1, g_iWeaponData[iWeaponID].ClipCount);
			}

			if(g_iWeaponData[iWeaponID].AmmoCount != -1)
			{
				SetEntData(iEntity, m_iPrimaryReserveAmmoCount, g_iWeaponData[iWeaponID].AmmoCount);

				int iClient = GetWeaponOwner(iEntity);

				if(iClient)
				{
					static int iDataMapAmmoOffset = 0;

					if(!iDataMapAmmoOffset)
					{
						iDataMapAmmoOffset = FindDataMapInfo(iClient, "m_iAmmo") + GetEntData(iEntity, FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType")) * 4;
					}

					SetEntData(iClient, iDataMapAmmoOffset, g_iWeaponData[iWeaponID].AmmoCount, 4, true);
				}
			}
		}
	}
}

Action OnWeaponCanUse(int iClient, int iEntity)
{
	int iDefIndex = GetEntData(iEntity, m_iItemDefinitionIndex);

	CSWeaponID iWeaponID = CS_ItemDefIndexToID(iDefIndex);

	if(CSWeapon_NONE < iWeaponID < CSWeapon_MAX_WEAPONS_NO_KNIFES)
	{
		if(CheckClientWeaponAccess(iClient, iWeaponID) && !IsPlayerHasWeapon(iClient, iDefIndex))
		{
			EquipPlayerWeapon(iClient, iEntity);
		}
	}
}

void OnRoundStartPre(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	bool bIsThisMap = false;

	int iPlayerCount = 0;

	char sBuffer[256];

	CSWeaponID iWeaponID = CSWeapon_MAX_WEAPONS_NO_KNIFES;

	while(--iWeaponID)
	{
		if(CS_IsValidWeaponID(iWeaponID))
		{
			g_iWeaponData[iWeaponID].Block = g_iCustomRound && !(g_iCustomRound == iWeaponID || CheckRoundIsKnife(iWeaponID));
			g_iWeaponData[iWeaponID].ClipCount = -1;
			g_iWeaponData[iWeaponID].AmmoCount = -1;
			g_iWeaponData[iWeaponID].AccessFlags = 0;
			g_iWeaponData[iWeaponID].RoundFlags = 0;
			g_iWeaponData[iWeaponID].RoundIsKnife = false;
		}
	}

	for(int i = MaxClients + 1; --i;)
	{
		if(IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			iPlayerCount++;
		}
	}

	g_hKv.Rewind();
	g_hKv.GotoFirstSubKey();

	do
	{
		bIsThisMap = false;

		g_hKv.GetSectionName(sBuffer, 64);

		if(!strcmp(sBuffer, "all"))
		{
			bIsThisMap = true;
		}
		else
		{
			RegexError iRegexError = REGEX_ERROR_NONE;

			Regex hRegex = new Regex(sBuffer, _, _, _, iRegexError);

			if(iRegexError != REGEX_ERROR_NONE)
			{
				LogError("%s - pattern regex error (%i)", sBuffer, iRegexError);
			}

			if(hRegex.Match(g_sMap, iRegexError) > 0)
			{
				bIsThisMap = true;
			}

			if(iRegexError != REGEX_ERROR_NONE)
			{
				LogError("%s - match regex error (%i)", sBuffer, iRegexError);
			}

			hRegex.Close();
		}

		if(bIsThisMap)
		{
			g_hKv.GotoFirstSubKey();

			do
			{
				g_hKv.GetSectionName(sBuffer, 12);

				if(StringToInt(sBuffer) <= iPlayerCount && g_hKv.GotoFirstSubKey())
				{
					do
					{
						g_hKv.GetSectionName(sBuffer, 64);

						if(CSWeapon_NONE < (iWeaponID = CS_AliasToWeaponID(sBuffer)) < CSWeapon_MAX_WEAPONS_NO_KNIFES)
						{
							if(!g_iCustomRound)
							{
								g_iWeaponData[iWeaponID].Block = g_hKv.GetNum("block", 0) != 0;
								g_iWeaponData[iWeaponID].ClipCount = g_hKv.GetNum("clip_count", -1);
								g_iWeaponData[iWeaponID].AmmoCount = g_hKv.GetNum("ammo_count", -1);
							}

							g_hKv.GetString("access_flags", sBuffer, 32);
							g_iWeaponData[iWeaponID].AccessFlags = ReadFlagString(sBuffer);

							g_hKv.GetString("round_flags", sBuffer, 32);
							g_iWeaponData[iWeaponID].RoundFlags = ReadFlagString(sBuffer);

							g_iWeaponData[iWeaponID].RoundIsKnife = g_hKv.GetNum("round_is_knife", -1) != 0;

							Call_StartForward(g_hWB_WeaponDataUpdate);
							Call_PushCell(g_hKv);
							Call_PushCell(iWeaponID);
							Call_Finish();
						}
						else
						{
							LogError("%s - weapon is not found", sBuffer);
						}
					}
					while g_hKv.GotoNextKey();

					g_hKv.GoBack();
				}
			}
			while g_hKv.GotoNextKey();

			g_hKv.GoBack();
		}
	}
	while g_hKv.GotoNextKey();

	sBuffer[0] = '\0';

	for(CSWeaponID i = CSWeapon_MAX_WEAPONS_NO_KNIFES; --i;)
	{
		if(g_iWeaponData[i].Block)
		{
			if(sBuffer[0])
			{
				int iLen = strlen(sBuffer);

				sBuffer[iLen++] = ',';
				IntToString(CS_WeaponIDToItemDefIndex(i), sBuffer[iLen], sizeof(sBuffer) - iLen);
			}
			else
			{
				IntToString(CS_WeaponIDToItemDefIndex(i), sBuffer, sizeof(sBuffer));
			}
		}
	}

	g_hItemsProhibited.SetString(sBuffer);

	Call_StartForward(g_hWB_OnSettingsIsLoaded);
	Call_PushCell(g_hKv);
	Call_Finish();

	if(g_hAdminMenu)
	{
		OnAdminMenuReady(g_hAdminMenu);
	}

	for(int i = MaxClients + 1; --i;)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

void OnRoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for(int i = MaxClients + 1; --i;)
	{
		if(IsClientInGame(i))
		{
			for(int i2 = 68, iEnt; i2 -= 4;)
			{
				if((iEnt = GetEntDataEnt2(i, m_hMyWeapons + i2)) != -1)
				{
					CSWeaponID iWeaponID = CS_ItemDefIndexToID(GetEntData(iEnt, m_iItemDefinitionIndex));

					if(CSWeapon_NONE < iWeaponID < CSWeapon_MAX_WEAPONS_NO_KNIFES && g_iWeaponData[iWeaponID].Block && !CheckClientWeaponAccess(i, iWeaponID))
					{
						CS_DropWeapon(i, iEnt, false, false);
					}
				}
			}
		}
	}

	if(g_iCustomRound)
	{
		Call_StartForward(g_hWB_OnCustomRoundStart);
		Call_Finish();

		HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	}
}

void OnRoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	static char sAlias[64];

	UnhookEvent("round_end", OnRoundEnd);

	CS_WeaponIDToAlias(g_iCustomRound, sAlias, sizeof(sAlias));
	PrintToChatAll("[SM] %t", "End_CustomRound", sAlias);

	g_iCustomRound = CSWeapon_NONE;
}

void GetCurrentMapEx(char[] sMapBuffer, int iSize)
{
	static char sBuffer[256];

	GetCurrentMap(sBuffer, sizeof(sBuffer));

	int iIndex = -1, iLen = strlen(sBuffer);
	
	for(int i = 0; i != iLen; i++)
	{
		if(sBuffer[i] == '/' || sBuffer[i] == '\\')
		{
			iIndex = i;
		}
	}

	strcopy(sMapBuffer, iSize, sBuffer[iIndex + 1]);
}

// Custom Functions

void SDKHookCanUse(int iClient)
{
	SDKUnhook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

bool CheckRoundIsKnife(const CSWeaponID& iWeaponID)
{
	return g_iWeaponData[g_iCustomRound].RoundIsKnife && (iWeaponID == CSWeapon_KNIFE || iWeaponID == CSWeapon_KNIFE_GG || iWeaponID == CSWeapon_KNIFE_T);
}

bool CheckClientWeaponAccess(const int& iClient, const CSWeaponID& iWeaponID)
{
	int iAccessFlags = g_iWeaponData[iWeaponID].AccessFlags;

	return iAccessFlags && (iAccessFlags & g_iPlayerFlags[iClient] == iAccessFlags || g_iPlayerFlags[iClient] & ADMFLAG_ROOT);
}

int GetWeaponOwner(const int& iEntity)
{
	int iAcoountID = GetEntData(iEntity, m_iAccountID),
		iClient = MaxClients + 1;

	while(--iClient && !(IsClientInGame(iClient) && GetSteamAccountID(iClient) == iAcoountID)){}

	return iClient;
}

bool IsPlayerHasWeapon(const int& iClient, const int& iDefIndex)
{
	for(int i = 68, iEnt; i -= 4;)
	{
		if((iEnt = GetEntDataEnt2(iClient, m_hMyWeapons + i)) != -1 && iDefIndex == GetEntData(iEnt, m_iItemDefinitionIndex))
		{
			return true;
		}
	}

	return false;
}