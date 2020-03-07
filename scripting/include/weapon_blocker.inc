#if defined _weapon_blocker_included
  #endinput
#endif
#define _weapon_blocker_included

#include <cstrike>

enum WB_ParamType
{
	WB_Block = 0,
	WB_ClipCount,
	WB_AmmoCount,
	WB_AccessFlags,
	WB_RoundFlags,
	WB_RoundIsKnife,
};

/**
 * Called in the fields of getting values from the config.
 *
 * @param hKv				KeyValues with SubKey section.
 * @param iWeaponID			WeaponID in the section where the SubKey is located.
 */
forward void WB_OnGetWeaponData(KeyValues hKv, CSWeaponID iWeaponID);

/**
 * Called before load settings.
 *
 * @param KeyValues		Full config tree.
 */
forward void WB_OnLoadSettings(KeyValues hKv);

/**
 * Called when the settings have been loaded.
 *
 * @param KeyValues			Full config tree.
 */
forward void WB_OnSettingsIsLoaded(KeyValues hKv);

/**
 * Called when the custom round starts.
 */
forward void WB_OnCustomRoundStart();

/**
 * Gets the value of the weapon parameter.
 *
 * @param iWeaponID			WeaponID to get of parameter.
 * @param iParam			Parameter.
 *
 * @return Parameter value.
 */
native int WB_GetWeaponData(CSWeaponID iWeaponID, WB_ParamType iParam);

/**
 * Sets the value of the weapon parameter during the round.
 *
 * @param iWeaponID			WeaponID to set of parameter.
 * @param iParam			Parameter.
 * @param iValue			Value to be set.
 */
native void WB_SetWeaponData(CSWeaponID iWeaponID, WB_ParamType iParam, any iValue);

/**
 * Gets the flags the player access to weapons.
 *
 * @param iClient			Client index.
 *
 * @return Access flags.
 */
native int WB_GetClientAccessFlags(int iClient);

/**
 * Sets the flags the player access to weapons.
 *
 * @param iClient			Client index.
 * @param iFlags			Access flags. (1 << 14) for full access independent of settings.
 * @param bAdd				Add flags to existing.
 */
native void WB_SetClientAccessFlags(int iClient, int iFlags, bool bAdd = false);

/**
 * Gets a custom round on behalf of the server.
 *
 * @param CSWeaponID		WeaponID.
 */
native CSWeaponID WB_GetCustomRound();

/**
 * Sets a custom round on behalf of the server.
 *
 * @param CSWeaponID		WeaponID on which the custom round will be played.
 * @param bAnnounce			Whether to announce the installation of a custom round to players.
 */
native void WB_SetCustomRound(CSWeaponID iWeaponID, bool bAnnounce = true);



public SharedPlugin __pl_weapon_blocker = 
{
	name = "weapon_blocker",
	file = "weapon_blocker.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_vip_core_SetNTVOptional()
{
	MarkNativeAsOptional("WB_GetWeaponData");
	MarkNativeAsOptional("WB_SetWeaponData");
	MarkNativeAsOptional("WB_GetClientAccessFlags");
	MarkNativeAsOptional("WB_GetCustomRound");
	MarkNativeAsOptional("WB_SetCustomRound");
}
#endif