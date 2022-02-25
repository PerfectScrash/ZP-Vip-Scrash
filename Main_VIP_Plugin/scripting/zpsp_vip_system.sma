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
#define MAX_TEXT_BUFFER_SIZE 65
#define VM_ACESS ADMIN_RESERVATION
#define IsPlayerVIP(%1) (get_user_flags(%1) & VM_ACESS)

#define CHAT_PREFIX "^4[ZP]^3"
#define MENU_TAG "\r[\dZP\r]\w"

enum _:items {
	i_name[MAX_TEXT_BUFFER_SIZE], 
	i_description[MAX_TEXT_BUFFER_SIZE], 
	i_cost, 
	i_team
}
enum {
	ITEMS_SELECTED_PRE, 
	ITEMS_SELECTED_POST, 
	MAX_FORWARDS_NUM
}

new g_forward_return, g_forwards[MAX_FORWARDS_NUM], g_team[33], g_AdditionalMenuText[32], Float:g_damage[33]
new extra_items[items], Array:items_database, g_registered_items_count, g_itemid, msg_ScoreAttrib
new cvar_dmg_rwd, cvar_dmg_increase, cvar_ammo_dmg_rwd_quantity, cvar_armor_amount, cvar_free_armor
new jumpnum[33], dojump[33], cvar_maxjumps, cvar_freemaxjumps, cvar_zmmultijump

/*===============================================================================
---> Registro do Plugin
=================================================================================*/
public plugin_init() {
	register_plugin("[ZPSp] Addon: Vip System", "1.2", "[P]erfec[T] [S]cr[@]s[H] | aaarnas")

	register_clcmd("say vm", "vip_menu")
	register_clcmd("say /vm", "vip_menu")
	register_clcmd("say .vm", "vip_menu")
	register_clcmd("say_team vm", "vip_menu")
	register_clcmd("say_team /vm", "vip_menu")
	register_clcmd("say_team .vm", "vip_menu")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

	cvar_armor_amount = register_cvar("zp_vip_armor", "100")
	cvar_free_armor = register_cvar("zp_user_free_armor", "50")
	cvar_dmg_rwd = register_cvar("zp_vip_damage_reward", "500")
	cvar_dmg_increase = register_cvar("zp_vip_damage_increase", "1.2")
	cvar_ammo_dmg_rwd_quantity = register_cvar("zp_vip_ammo_dmg_rwd_quantity", "1")
	cvar_maxjumps = register_cvar("zp_vip_jumps", "1") // Quantia de pulos no ar (Se bota 2 o cara pula 3x)
	cvar_freemaxjumps = register_cvar("zp_free_jumps", "1") // Quantia de pulos no ar (Se bota 2 o cara pula 3x)
	cvar_zmmultijump = register_cvar("zp_allow_zm_multijump", "1")
	
	g_itemid = zp_register_extra_item("*VIP* Extra Itens", 0, ZP_TEAM_HUMAN|ZP_TEAM_ZOMBIE)

	g_forwards[ITEMS_SELECTED_PRE] = CreateMultiForward("zv_extra_item_selected_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_forwards[ITEMS_SELECTED_POST] = CreateMultiForward("zv_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)

	msg_ScoreAttrib = get_user_msgid("ScoreAttrib")
}

/*===============================================================================
---> Natives
=================================================================================*/
public plugin_natives() {
	register_native("zv_register_extra_item", "native_register_extra_item")
	register_native("zv_vip_item_textadd", "native_extra_item_textadd")
	register_native("zv_get_extra_item_name", "native_get_item_name")
	register_native("zv_get_extra_item_cost", "native_get_extra_item_cost")
}
public native_register_extra_item(plugin_id, param_nums) {
	if(!items_database) 
		items_database = ArrayCreate(items);

	get_string(1, extra_items[i_name], MAX_TEXT_BUFFER_SIZE-1);
	get_string(2, extra_items[i_description], MAX_TEXT_BUFFER_SIZE-1);
	extra_items[i_cost] = get_param(3);
	extra_items[i_team] = get_param(4);
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

public zp_extra_item_selected(id, itemid) if(itemid == g_itemid) vip_menu(id);

public plugin_end() if(items_database) ArrayDestroy(items_database);

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
	
	if(IsPlayerVIP(id))
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
		
	if(zp_get_user_zombie(attacker) || !IsPlayerVIP(attacker))
		return HAM_IGNORED

	damage *= get_pcvar_float(cvar_dmg_increase)
	SetHamParamFloat(4, damage)
	static Float:CvarDmgRwd, CvarApQtd
	CvarDmgRwd = get_pcvar_float(cvar_dmg_rwd);
	CvarApQtd = get_pcvar_num(cvar_ammo_dmg_rwd_quantity)

	if(CvarDmgRwd > 0.0 && CvarApQtd > 0) {
		g_damage[attacker] += damage
		if(g_damage[attacker] > CvarDmgRwd) {
			zp_add_user_ammopacks(attacker, CvarApQtd)
			g_damage[attacker] -= CvarDmgRwd
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

		if(!IsPlayerVIP(i)) 
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
public vip_menu(id) {
	if(!is_user_alive(id))
		return
	
	if(!g_registered_items_count || zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) {
		client_print_color(id, print_team_default, "%s Menu de Itens Extras Desativado para sua classe!", CHAT_PREFIX)
		return;
	}
		
	new holder[150], menu, i, team_check, ammo_packs, check
	formatex(holder, charsmax(holder), "%s Vip Main Menu:^nTeam: %s^n\wStatus: %s", MENU_TAG, zp_get_user_zombie(id) ? "\r[Zombie]" : "\y[Humano]", IsPlayerVIP(id) ? "\rCom Vip :)" : "\rSem Vip :(")
	
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

		if(g_forward_return >= ZP_PLUGIN_HANDLED || !IsPlayerVIP(id) || ammo_packs < extra_items[i_cost]) {
			formatex(holder, charsmax(holder), "\d%s [%s] [%d] %s", extra_items[i_name], extra_items[i_description], extra_items[i_cost], g_AdditionalMenuText)
			menu_additem(menu, holder, fmt("%d", i), (1<<30))
		}
		else  {
			formatex(holder, charsmax(holder), "\w%s \r[%s] \y[%d] %s", extra_items[i_name], extra_items[i_description], extra_items[i_cost], g_AdditionalMenuText)
			menu_additem(menu, holder, fmt("%d", i), 0)
		}
		check++
		
	}
	if(check == 0) {
		client_print_color(id, print_team_default, "%s Menu de Itens Extras Desativado para sua classe", CHAT_PREFIX)
		return;
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_NEXTNAME, "Proximo")
	menu_setprop(menu, MPROP_BACKNAME, "Voltar")
	menu_setprop(menu, MPROP_EXITNAME, "Sair")
	menu_display(id, menu, 0)
}
 
public vip_menu_handler(id, menu, item) {
	if(!IsPlayerVIP(id)) {
		client_print_color(id, print_team_default, "%s Voce Nao eh Membro ^4*VIP*", CHAT_PREFIX)
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	if(item == MENU_EXIT || zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) {
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
		if(g_forward_return < ZP_PLUGIN_HANDLED) zp_set_user_ammo_packs(id, ammo_packs - extra_items[i_cost]);
	}
	else client_print_color(id, print_team_default, "%s Voce Nao tem Ammo Packs suficiente", CHAT_PREFIX)

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
		client_print_color(0, print_team_default, "%s O Jogador ^4*VIP*^1 %s ^3Conectou-se ao Servidor", CHAT_PREFIX, name)
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
		if(jumpnum[id] < CvarVipJumps && IsPlayerVIP(id) || jumpnum[id] < CvarFreeJumps) {
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