#if defined _zpsp_vip
	#endinput
#endif
#define _zpsp_vip

#if !defined _zombie_special_new_included
	#include <zombie_plague_special>
#endif

// For noobs
#define ZV_TEAM_ZOMBIE ZP_TEAM_ZOMBIE
#define ZV_TEAM_HUMAN ZP_TEAM_HUMAN
#define ZV_PLUGIN_HANDLED ZP_PLUGIN_HANDLED
#define ZV_PLUGIN_SUPERCEDE ZP_PLUGIN_SUPERCEDE

/**
 * Registers a custom item which will be added to the vip extra items menu of ZP.
 *
 * @note The returned extra item ID can be later used to catch item
 * purchase events for the zv_extra_item_selected() forward.
 *
 *
 * @param name		    Caption to display on the menu.
 * @param description	Extra item description
 * @param cost		    Ammo packs to be deducted on purchase.
 * @param teams		    Bitsum of teams it should be available for.
 * @return              An internal extra item ID, or -1 on failure.
 * @error			    If Extra Item name alterady exists
 */
native zv_register_extra_item(const name[], const description[], cost, team);

/**
 * Get VIP Extra Item Name
 *
 * @param itemid	Extra item index
 * @param itemname	Buffer to copy item name to
 * @param len		Maximum length of buffer
 * @return			True if sucess, false otherwise
 * @error			If Extra Item index are invalid
 */
native zv_get_extra_item_name(itemid, itemname[], len);

/**
 * Get Extra Item Price
 *
 * @param itemid	Extra item index
 * @return			Item Price
 * @error			If Extra Item index are invalid
 */
native zv_get_extra_item_cost(itemid);

/**
 * Add menu text in a VIP extra itens
 * 
 * @param text		Text
 * @return			True if sucess / false otherwise
 */
native zv_vip_item_textadd(const text[]);

/**
 * Called when a player buys an vip extra item from the ZP menu.
 *
 * @note You can now return ZP_PLUGIN_HANDLED in your plugin to block
 * the purchase and the player will be automatically refunded.
 *
 * @param id		Player index of purchaser.
 * @param itemid	Internal extra item ID.
 */
forward zv_extra_item_selected(id, itemid);

/**
 * Called while player are choosing vip item
 *
 * @note Use the ZP_PLUGIN_HANDLED for block option (Like ZP 5.0)
 * @note Use the ZP_PLUGIN_SUPERCEDE for block showing item in menu
 * @note Use 'zv_vip_item_textadd' for add a small text description
 *
 * @param id		Player index
 * @param itemid	Extra item index
 */
forward zv_extra_item_selected_pre(id, itemid);