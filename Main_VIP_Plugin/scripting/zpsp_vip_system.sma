/*
	[ZPSp Addon] VIP System

	* Plugin Description:
		- Enables a VIP System for Zombie Plague Special

	* Requirements:
		- Zombie Plague Special 4.5 [Patch 1] or higher

	* Functions:
		- Free armor for normal and vip players
		- Free multijump for normal and vip players
		- Happy Hour for Multiple Ammo packs and Free Vip
		- VIP prefix in score
		- Increase VIP Damage
		- VIP Itens menu

	* Change Log:
		- 1.0: 
			- First Version
		- 1.1: 
			- Separating HH Privileges Acess by flags
			- Fixed multiple ammo packs in happy hour
			- Added CFG File
			- Added Cvar: "zp_vip_flag_acess"
			- Added Native: "zv_is_in_happyhour"
			- Added Native: "zv_happyhour_flags"
			- Added Forward: "zv_happyhour_start"
			- Added Forward: "zv_happyhour_end"

	* Credits:
		- [P]erfect [S]crash: For Zombie plague special Vip system.
		- aaarnas: Part of code of Zombie VIP System
*/

/*===============================================================================
---> Includes
=================================================================================*/
#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>
#include <engine>

/*===============================================================================
---> Variable/Defines/Enums/Consts
=================================================================================*/
#define VIP_SYSTEM_CONFIG_FILE "zpsp_configs/zpsp_vip.cfg"

#define MAX_TEXT_BUFFER_SIZE 65
#define IsPlayerVIP(%1) (get_user_flags(%1) & g_vip_flag)

// Flags
#define ACCESS_VIP_MULTIJUMP (1<<0) 	// a
#define ACCESS_ARMOR_VIP (1<<1)			// b
#define ACCESS_EXTRA_DAMAGE (1<<2)		// c
#define ACCESS_VIP_EXTRA_ITEM (1<<3)	// d
#define ACCESS_DAMAGE_RWD (1<<4)		// e
#define ACCESS_VIP_SCORE_PREFIX (1<<5)	// f

#define get_hh_acess(%1) (g_happyhour && (g_hh_flags & %1))

#define TASK_HH 13291931

enum _:items {
	i_name[MAX_TEXT_BUFFER_SIZE],
	i_description[MAX_TEXT_BUFFER_SIZE],
	i_cost,
	i_team,
	i_use_lang,
	i_lang_itemname[MAX_TEXT_BUFFER_SIZE],
	i_lang_desc[MAX_TEXT_BUFFER_SIZE]
}
enum {
	ITEMS_SELECTED_PRE,
	ITEMS_SELECTED_POST,
	HH_START,
	HH_END,
	MAX_FORWARDS_NUM
}

new g_forward_return, g_forwards[MAX_FORWARDS_NUM], g_team[33], g_AdditionalMenuText[32], Float:g_damage[33]
new extra_items[items], Array:items_database, g_registered_items_count, g_itemid, msg_ScoreAttrib
new cvar_dmg_rwd, cvar_dmg_increase, cvar_ap_dmg_rwd_qtd, cvar_armor_amount, cvar_free_armor, cvar_vip_flag
new jumpnum[33], dojump[33], cvar_maxjumps, cvar_freemaxjumps, cvar_zmmultijump, g_vip_flag
new g_happyhour, g_hh_flags, cvar_hh[5]

/*===============================================================================
---> Plugin Register
=================================================================================*/
public plugin_init() {
	register_plugin("[ZPSp] Addon: Vip System", "1.1", "[P]erfect [S]crash | aaarnas")
	register_dictionary("zpsp_vip_system.txt")

	register_clcmd("say vm", "vip_menu")
	register_clcmd("say /vm", "vip_menu")
	register_clcmd("say .vm", "vip_menu")
	register_clcmd("say_team vm", "vip_menu")
	register_clcmd("say_team /vm", "vip_menu")
	register_clcmd("say_team .vm", "vip_menu")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", .specialbot=true);

	// Global Config
	cvar_zmmultijump = register_cvar("zp_allow_zm_multijump", "1") 	// Zombies have multijump

	// Free Privilegies
	cvar_freemaxjumps = register_cvar("zp_free_jumps", "1") 	// Jumps in air (Free)
	cvar_free_armor = register_cvar("zp_user_free_armor", "10")	// Free Armor amount for non vip players

	// VIP Privilegies
	cvar_vip_flag = register_cvar("zp_vip_flag_acess", "b")						// VIP flag Acess
	cvar_armor_amount = register_cvar("zp_vip_armor", "100")					// VIP Free Armor Amount
	cvar_dmg_rwd = register_cvar("zp_vip_damage_reward", "500")					// Damage require for reward
	cvar_dmg_increase = register_cvar("zp_vip_damage_increase", "1.2")			// Vip Damage increase
	cvar_ap_dmg_rwd_qtd = register_cvar("zp_vip_ammo_dmg_rwd_quantity", "1")	// Reward Quantity for ammopack damage
	cvar_maxjumps = register_cvar("zp_vip_jumps", "1") 							// Jumps in air (VIP)

	// Happyhour
	cvar_hh[0] = register_cvar("zp_vip_happy_hour_enable", "1")		// Enable happy hour
	cvar_hh[1] = register_cvar("zp_vip_happy_hour_start", "22")		// Happy Hour Start
	cvar_hh[2] = register_cvar("zp_vip_happy_hour_end", "5")		// Happy Hour End
	cvar_hh[3] = register_cvar("zp_vip_happy_hour_hud", "1")		// Enable Happy hour status hud
	cvar_hh[4] = register_cvar("zp_vip_happy_hour_flags", "abcdef")	// Happy Hour Free Vip Acess content

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	set_task(5.0 , "hh_update", TASK_HH, _ , _, "b")

	g_itemid = zpsp_register_extra_item("*VIP* Extra Itens", 0, "HUMAN, ZOMBIE", 1, "VIP_EXTRA_ITEM")

	// g_itemid = zp_register_extra_item("*VIP* Extra Itens", 0, ZP_TEAM_HUMAN|ZP_TEAM_ZOMBIE)

	g_forwards[ITEMS_SELECTED_PRE] = CreateMultiForward("zv_extra_item_selected_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_forwards[ITEMS_SELECTED_POST] = CreateMultiForward("zv_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)
	g_forwards[HH_START] = CreateMultiForward("zv_happyhour_start", ET_IGNORE)
	g_forwards[HH_END] = CreateMultiForward("zv_happyhour_end", ET_IGNORE)

	msg_ScoreAttrib = get_user_msgid("ScoreAttrib")
}

/*===============================================================================
---> Load CFG File
=================================================================================*/
public plugin_cfg() {
	static cfg_file[64]; get_localinfo("amxx_configsdir", cfg_file, charsmax(cfg_file));
	format(cfg_file, charsmax(cfg_file), "%s/%s", cfg_file, VIP_SYSTEM_CONFIG_FILE)

	if(file_exists(cfg_file)) {
		server_cmd("exec %s", cfg_file)
		server_print("[ZPSp] Configs file Loaded (%s)", cfg_file)
	} else {
		server_print("[ZPSp] Configs file not found (%s)", cfg_file)
	}

	static flags[20]; get_pcvar_string(cvar_hh[4], flags, charsmax(flags));
	g_hh_flags = read_flags(flags);

	get_pcvar_string(cvar_vip_flag, flags, charsmax(flags));
	g_vip_flag = read_flags(flags)
}

/*===============================================================================
---> Natives
=================================================================================*/
public plugin_natives() {
	register_native("zv_register_extra_item", "native_register_extra_item")
	register_native("zv_vip_item_textadd", "native_extra_item_textadd")
	register_native("zv_get_extra_item_name", "native_get_item_name")
	register_native("zv_get_extra_item_cost", "native_get_extra_item_cost")

	// 1.1 Natives
	register_native("zv_is_in_happyhour", "native_is_in_happyhour")
	register_native("zv_happyhour_flags", "native_happyhour_flags")
}
public native_register_extra_item(plugin_id, param_nums) {
	if(!items_database)
		items_database = ArrayCreate(items);

	get_string(1, extra_items[i_name], MAX_TEXT_BUFFER_SIZE-1);
	get_string(2, extra_items[i_description], MAX_TEXT_BUFFER_SIZE-1);
	extra_items[i_cost] = get_param(3);
	extra_items[i_team] = get_param(4);
	extra_items[i_use_lang] = get_param(5);
	get_string(6, extra_items[i_lang_itemname], MAX_TEXT_BUFFER_SIZE-1);
	get_string(7, extra_items[i_lang_desc], MAX_TEXT_BUFFER_SIZE-1);
	ArrayPushArray(items_database, extra_items)
	g_registered_items_count++
	return (g_registered_items_count-1)
}

public native_get_item_name(plugin_id, param_nums) {
	if (param_nums != 3)
		return -1;

	static itemid; itemid = get_param(1)
	ArrayGetArray(items_database, itemid-1, extra_items)
	set_string(2, extra_items[i_name], get_param(3))
	return 1;
}

public native_get_extra_item_cost(plugin_id, num_params) {
	ArrayGetArray(items_database, get_param(1)-1, extra_items)
	return extra_items[i_cost]
}

public native_extra_item_textadd(plugin_id, num_params) {
	static text[32]; get_string(1, text, charsmax(text))
	strcat(g_AdditionalMenuText, text, charsmax(g_AdditionalMenuText))
}

public native_is_in_happyhour(plugin_id, num_params)
	return g_happyhour;

public native_happyhour_flags(plugin_id, num_params)
	return get_hh_acess(get_param(1));

public plugin_end() if(items_database) ArrayDestroy(items_database);

/*===============================================================================
---> Happy hour
=================================================================================*/

public event_round_start()
{
	if(!get_pcvar_num(cvar_hh[0]) && g_happyhour) {
		g_happyhour = false
		ExecuteForward(g_forwards[HH_END], g_forward_return)
		return;
	}
	if(g_happyhour)
		return;

	static h, m, start_hh, end_hh
	start_hh = max(get_pcvar_num(cvar_hh[1]), 0)
	end_hh = max(get_pcvar_num(cvar_hh[2]), 0)

	if(start_hh > 24) start_hh = 0;
	if(end_hh > 24) end_hh = 0;

	if(end_hh == start_hh && !g_happyhour) {
		g_happyhour = true
		ExecuteForward(g_forwards[HH_START], g_forward_return)
		remove_task(TASK_HH)
		return;
	}
	time(h, m); hh_time(h, m, start_hh)
}

public hh_update()
{
	if(!get_pcvar_num(cvar_hh[0])) {
		g_happyhour = false
		return;
	}

	static h, m, start_hh, end_hh
	start_hh = max(get_pcvar_num(cvar_hh[1]), 0)
	end_hh = max(get_pcvar_num(cvar_hh[2]), 0)

	if(start_hh > 24) start_hh = 0;
	if(end_hh > 24) end_hh = 0;

	if(end_hh == start_hh && !g_happyhour) {
		g_happyhour = true
		return;
	}

	time(h, m)
	if(start_hh <= h < end_hh) {
		if(!g_happyhour) start_happy(end_hh);
	}
	else {
		if(g_happyhour) stop_happy();
	}
}

start_happy(end_hh) {
	if(!g_happyhour) {
		g_happyhour = true
		ExecuteForward(g_forwards[HH_START], g_forward_return)
		client_print_color(0, print_team_grey, "%L %L", LANG_PLAYER, "VIP_CHAT_PREFIX", LANG_PLAYER, "VIP_HH_STARTS", end_hh)
	}
}

stop_happy() {
	if(g_happyhour) {
		g_happyhour = false
		ExecuteForward(g_forwards[HH_END], g_forward_return)
		client_print_color(0, print_team_grey, "%L %L", LANG_PLAYER, "VIP_CHAT_PREFIX", LANG_PLAYER, "VIP_HH_ENDS")
	}
}

hh_time(h, m, start_hh) {
	if(h > start_hh) h -= 24
	if(m) h += 1, m = 60 - m

	h = start_hh - h;

	if(!g_happyhour && h <= 5 )
		client_print_color(0, print_team_grey, "%L %L", LANG_PLAYER, "VIP_CHAT_PREFIX", LANG_PLAYER, (h > 0) ? "VIP_HH_START_HOURS" : "VIP_HH_START_MINUTES", (h > 1) ? h : m)
}

public zp_player_show_hud(id, target, SpHudType:hudtype) {
	if(target)
		return;
	if(!get_pcvar_num(cvar_hh[0]) || !get_pcvar_num(cvar_hh[3]))
		return;

	static start_hh, end_hh
	start_hh = max(get_pcvar_num(cvar_hh[1]), 0)
	end_hh = max(get_pcvar_num(cvar_hh[2]), 0)
	if(start_hh > 24) start_hh = 0;
	if(end_hh > 24) end_hh = 0;

	if(end_hh == start_hh)
		return;

	if(hudtype == HUD_DEFAULT || hudtype == HUD_CENTER || hudtype == HUD_UNDER_RADAR)
		zp_add_hud_text(fmt("^n[%L: %L]^n[%L]^n[%L]", id, "VIP_HH_HUD_HAPPY", id, g_happyhour ? "VIP_HH_HUD_ON" : "VIP_HH_HUD_OFF", id, "VIP_HH_HUD_START", start_hh, id, "VIP_HH_HUD_END", end_hh))
	else if(hudtype == HUD_ANTRAX_STYLE || hudtype == HUD_CENTER_ANTRAX)
		zp_add_hud_text(fmt("^n[%L: %L] - [%L | %L]", id, "VIP_HH_HUD_HAPPY", id, g_happyhour ? "VIP_HH_HUD_ON" : "VIP_HH_HUD_OFF", id, "VIP_HH_HUD_START", start_hh, id, "VIP_HH_HUD_END", end_hh))
	else if(hudtype == HUD_CLASSIC)
		zp_add_hud_text(fmt("- %L: %L", id, "VIP_HH_HUD_HAPPY", id, g_happyhour ? "VIP_HH_HUD_ON" : "VIP_HH_HUD_OFF"))
}

/*===============================================================================
---> Armor
=================================================================================*/
public zp_player_spawn_post(id)
	set_task(0.7, "give_armor", id);

public zp_user_humanized_post(id) {
	set_task(0.7, "give_armor", id);
	setVip();
}

public give_armor(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_user_zombie(id))
		return;

	static amount;

	if(IsPlayerVIP(id) || get_hh_acess(ACCESS_ARMOR_VIP))
		amount = get_pcvar_num(cvar_armor_amount)
	else
		amount = get_pcvar_num(cvar_free_armor)

	if(amount <= 0)
		return;

	if(get_user_armor(id) < amount)
		set_user_armor(id, amount)
}

/*===============================================================================
---> Damage Increase/Reward
=================================================================================*/
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED

	if(zp_get_user_zombie(attacker))
		return HAM_IGNORED

	if(IsPlayerVIP(attacker) || get_hh_acess(ACCESS_EXTRA_DAMAGE)) {
		damage *= get_pcvar_float(cvar_dmg_increase)
		SetHamParamFloat(4, damage)
	}

	if(IsPlayerVIP(attacker) || get_hh_acess(ACCESS_DAMAGE_RWD)) {
		static Float:CvarDmgRwd, CvarApQtd
		CvarDmgRwd = get_pcvar_float(cvar_dmg_rwd);
		CvarApQtd = get_pcvar_num(cvar_ap_dmg_rwd_qtd)

		if(CvarDmgRwd > 0.0 && CvarApQtd > 0) {
			g_damage[attacker] += damage
			if(g_damage[attacker] > CvarDmgRwd) {
				zp_add_user_ammopacks(attacker, CvarApQtd)
				g_damage[attacker] -= CvarDmgRwd
			}
		}
	}

	return HAM_IGNORED
}

/*===============================================================================
---> Vip Prefix in Score
=================================================================================*/
public zp_round_ended() setVip();
public zp_user_infected_post(id) setVip();
public setVip() {
	static i;
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(!IsPlayerVIP(i) && !get_hh_acess(ACCESS_VIP_SCORE_PREFIX))
			continue;

		message_begin(MSG_ALL, msg_ScoreAttrib)
		write_byte(i)
		write_byte(4)
		message_end()

	}
	return PLUGIN_HANDLED
}

/*===============================================================================
---> Vip Menu
=================================================================================*/
public zp_extra_item_selected(id, itemid) if(itemid == g_itemid) vip_menu(id);

public vip_menu(id) {
	if(!is_user_alive(id))
		return

	if(!g_registered_items_count || zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) {
		client_print_color(id, print_team_default, "%L %L", id, "VIP_CHAT_PREFIX", id, "VIP_ITEM_DISABLE")
		return;
	}

	new holder[150], menu, i, team_check, ammo_packs, check
	formatex(holder, charsmax(holder), "%L %L", id, "VIP_MENU_TAG", id, "VIP_MENU_TITLE", id, zp_get_user_zombie(id) ? "VIP_TEAM_ZOMBIE" : "VIP_TEAM_HUMAN", id, IsPlayerVIP(id) ? "VIP_WITH_VIP" : g_happyhour ? "VIP_HAPPYHOUR" : "VIP_WITHOUT_VIP")

	menu = menu_create(holder, "vip_menu_handler")
	ammo_packs = zp_get_user_ammo_packs(id)

	team_check |= zp_get_user_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN

	g_team[id] = team_check
	for(i=0; i < g_registered_items_count; i++) {
		g_AdditionalMenuText[0] = 0
		ArrayGetArray(items_database, i, extra_items)
		if(extra_items[i_team] != 0 && !(g_team[id] & extra_items[i_team]))
			continue;

		ExecuteForward(g_forwards[ITEMS_SELECTED_PRE], g_forward_return, id, i)
		if (g_forward_return >= ZP_PLUGIN_SUPERCEDE)
			continue;

		if(extra_items[i_use_lang]) {
			if(g_forward_return >= ZP_PLUGIN_HANDLED || !IsPlayerVIP(id) && !get_hh_acess(ACCESS_VIP_EXTRA_ITEM) || ammo_packs < extra_items[i_cost]) {
				formatex(holder, charsmax(holder), "\d%L [%L] [%d] %s", id, extra_items[i_lang_itemname], id, extra_items[i_lang_desc], extra_items[i_cost], g_AdditionalMenuText)
				menu_additem(menu, holder, fmt("%d", i), (1<<30))
			}
			else  {
				formatex(holder, charsmax(holder), "\w%L \r[%L] \y[%d] %s", id, extra_items[i_lang_itemname], id, extra_items[i_lang_desc], extra_items[i_cost], g_AdditionalMenuText)
				menu_additem(menu, holder, fmt("%d", i), 0)
			}
		}
		else {
			if(g_forward_return >= ZP_PLUGIN_HANDLED || !IsPlayerVIP(id) && !get_hh_acess(ACCESS_VIP_EXTRA_ITEM) || ammo_packs < extra_items[i_cost]) {
				formatex(holder, charsmax(holder), "\d%s [%s] [%d] %s", extra_items[i_name], extra_items[i_description], extra_items[i_cost], g_AdditionalMenuText)
				menu_additem(menu, holder, fmt("%d", i), (1<<30))
			}
			else  {
				formatex(holder, charsmax(holder), "\w%s \r[%s] \y[%d] %s", extra_items[i_name], extra_items[i_description], extra_items[i_cost], g_AdditionalMenuText)
				menu_additem(menu, holder, fmt("%d", i), 0)
			}
		}
		check++

	}
	if(check == 0) {
		client_print_color(id, print_team_default, "%L %L", id, "VIP_CHAT_PREFIX", id, "VIP_ITEM_DISABLE")
		return;
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_NEXTNAME, fmt("%L", id, "VIP_MENU_ITEM_NEXT"))
	menu_setprop(menu, MPROP_BACKNAME, fmt("%L", id, "VIP_MENU_ITEM_BACK"))
	menu_setprop(menu, MPROP_EXITNAME, fmt("%L", id, "VIP_MENU_ITEM_EXIT"))
	menu_display(id, menu, 0)
}

public vip_menu_handler(id, menu, item) {
	if(item == MENU_EXIT || !is_user_connected(id)) {
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	if(!IsPlayerVIP(id) && !get_hh_acess(ACCESS_VIP_EXTRA_ITEM)) {
		client_print_color(id, print_team_default, "%L %L", id, "VIP_CHAT_PREFIX", id, "VIP_NOT_A_VIP")
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	if(zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) {
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64], item_id, ammo_packs, aaccess, callback, team_check
	menu_item_getinfo(menu, item, aaccess, data, charsmax(data), iName, charsmax(iName), callback)

	team_check |= zp_get_user_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN
	if(g_team[id] != team_check) {
		menu_destroy(menu)
		vip_menu(id)
		return PLUGIN_HANDLED;
	}

	item_id = str_to_num(data)
	ExecuteForward(g_forwards[ITEMS_SELECTED_PRE], g_forward_return, id, item_id)
	if (g_forward_return >= ZP_PLUGIN_HANDLED)
		return PLUGIN_HANDLED;

	ammo_packs = zp_get_user_ammo_packs(id)
	ArrayGetArray(items_database, item_id, extra_items)
	if(ammo_packs >= extra_items[i_cost]) {
		ExecuteForward(g_forwards[ITEMS_SELECTED_POST], g_forward_return, id, item_id)
		if(g_forward_return < ZP_PLUGIN_HANDLED) zp_remove_user_ammopacks(id, extra_items[i_cost]);
	}
	else client_print_color(id, print_team_default, "%L %L", id, "VIP_CHAT_PREFIX", id, "VIP_ENGOUT_AMMOPACK")

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

/*===============================================================================
---> VIP Connected Message
=================================================================================*/
public client_putinserver(id) {
	jumpnum[id] = 0
	dojump[id] = false

	if(IsPlayerVIP(id)) {
		static name[32]; get_user_name(id, name, charsmax(name))
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "VIP_CHAT_PREFIX", LANG_PLAYER, "VIP_CONNECTED")
	}
}

/*===============================================================================
---> Multijump
=================================================================================*/
public client_PreThink(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	if(zp_get_user_zombie(id) && !get_pcvar_num(cvar_zmmultijump))
		return PLUGIN_CONTINUE

	static CvarFreeJumps, CvarVipJumps
	CvarVipJumps = get_pcvar_num(cvar_maxjumps)
	CvarFreeJumps = get_pcvar_num(cvar_freemaxjumps)
	if(CvarVipJumps <= 0 && CvarFreeJumps <= 0)
		return PLUGIN_CONTINUE;

	static nbut, obut, ent_flags
	nbut = get_user_button(id);
	obut = get_user_oldbutton(id);
	ent_flags = get_entity_flags(id);
	if((nbut & IN_JUMP) && !(ent_flags & FL_ONGROUND) && !(obut & IN_JUMP)) {
		if(jumpnum[id] < CvarVipJumps && (IsPlayerVIP(id) || get_hh_acess(ACCESS_VIP_MULTIJUMP)) || jumpnum[id] < CvarFreeJumps) {
			dojump[id] = true
			jumpnum[id]++
			return PLUGIN_CONTINUE
		}
	}
	if((nbut & IN_JUMP) && (ent_flags & FL_ONGROUND)) {
		jumpnum[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public client_PostThink(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	if(zp_get_user_zombie(id) && !get_pcvar_num(cvar_zmmultijump))
		return PLUGIN_CONTINUE

	if(!dojump[id])
		return PLUGIN_CONTINUE

	static Float:velocity[3];
	entity_get_vector(id, EV_VEC_velocity, velocity)
	velocity[2] = random_float(265.0, 285.0)
	entity_set_vector(id, EV_VEC_velocity, velocity)
	dojump[id] = false
	return PLUGIN_CONTINUE
}

/*===============================================================================
---> Stocks
=================================================================================*/
stock set_user_armor(index, armor) { // Set user armor "engine util"
	entity_set_float(index, EV_FL_armorvalue, float(armor));
	return 1;
}