/*===============================================================================
[Includes]
=================================================================================*/
#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>

/*===============================================================================
[Defines]
=================================================================================*/
#define CHAT_PREFIX "^4[ZP]^3"
#define MENU_TAG "\r[\dZP\r]\w"

#define ARMOR_ENABLE
#define MULTIJUMP_ENABLE

#define VM_ACESS ADMIN_RESERVATION

#define ZV_PLUGIN_SUPERCEDE 98

#if defined ARMOR_ENABLE
#include <fun>
new cvar_armor_amount, cvar_free_armor
#endif

#if defined MULTIJUMP_ENABLE
#include <engine>
new jumpnum[33] = 0
new bool:dojump[33] = false
new cvar_maxjumps, cvar_freemaxjumps, cvar_zmmultijump
#endif

/*===============================================================================
[News e Consts]
=================================================================================*/
enum _:items
{
	i_name[65], 
	i_description[65], 
	i_cost, 
	i_team
}

enum {
	ITEMS_SELECTED_PRE, 
	ITEMS_SELECTED_POST, 
	MAX_FORWARDS_NUM
}

new extra_items[items], Array:items_database, g_registered_items_count, g_itemid, g_damage_reward, g_damage_increase
new g_forward_return, g_forward_return2, g_forwards[MAX_FORWARDS_NUM], g_team[33], g_AdditionalMenuText[32], Float:g_damage[33]

/*===============================================================================
[Registro do Plugin]
=================================================================================*/
public plugin_init() 
{
	register_plugin("[DH/RTK] Addon: Vip Extra Itens Menu", "1.2", "[P]erfec[T] [S]cr[@]s[H] | aaarnas")

	register_clcmd("say vm", "extra_itens_menu")
	register_clcmd("say /vm", "extra_itens_menu")
	register_clcmd("say .vm", "extra_itens_menu")
	register_clcmd("say_team vm", "extra_itens_menu")
	register_clcmd("say_team /vm", "extra_itens_menu")
	register_clcmd("say_team .vm", "extra_itens_menu")
	
	#if defined ARMOR_ENABLE
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	cvar_armor_amount = register_cvar("zp_vip_armor", "100")
	cvar_free_armor = register_cvar("zp_user_free_armor", "20")
	#endif
	
	g_damage_reward = register_cvar("zp_vip_damage_reward", "500")
	g_damage_increase = register_cvar("zp_vip_damage_increase", "1.2")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")	
	
	#if defined MULTIJUMP_ENABLE
	cvar_maxjumps = register_cvar("zp_vip_jumps", "1") // Quantia de pulos no ar (Se bota 2 o cara pula 3x)
	cvar_freemaxjumps = register_cvar("zp_free_jumps", "0") // Quantia de pulos no ar (Se bota 2 o cara pula 3x)
	cvar_zmmultijump = register_cvar("zp_allow_zm_multijump", "0")
	#endif
	
	g_itemid = zp_register_extra_item("*VIP* Extra Itens", 0, ZP_TEAM_HUMAN|ZP_TEAM_ZOMBIE)

	g_forwards[ITEMS_SELECTED_PRE] = CreateMultiForward("zv_extra_item_selected_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_forwards[ITEMS_SELECTED_POST] = CreateMultiForward("zv_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)
}

/*===============================================================================
[Registro Da Native]
=================================================================================*/
public plugin_natives() 
{
	register_native("zv_register_extra_item", "native_register_extra_item", 1)
	register_native("zv_vip_item_textadd", "native_extra_item_textadd")
	register_native("za_register_extra_item", "native_register_extra_item", 1)
	register_native("za_vip_item_textadd", "native_extra_item_textadd")
	register_native("zv_get_extra_item_name", "native_get_item_name")
	register_native("zv_get_extra_item_cost", "native_get_extra_item_cost", 1)
}

public native_get_item_name(plugin_id, param_nums) {
	if (param_nums != 3)
		return -1;
	
	static itemid; itemid = get_param(1)
	static iname[65]
	ArrayGetArray(items_database, itemid-1, extra_items)
	formatex(iname, charsmax(iname), extra_items[i_name])
	set_string(2, iname, get_param(3))
	return 1;
}

public native_get_extra_item_cost(itemid) {
	ArrayGetArray(items_database, itemid-1, extra_items)
	return extra_items[i_cost]
}

public native_extra_item_textadd(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))	
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

public zp_extra_item_selected(id, itemid) if(itemid == g_itemid) extra_itens_menu(id)

#if defined ARMOR_ENABLE
public player_spawn(id) 
	set_task(0.7, "give_armor", id)

public zp_user_humanized_post(id) {
	set_task(0.7, "give_armor", id)
	setVip()
}

public zp_round_ended() setVip()
public zp_user_infected_post(id) setVip()

public give_armor(id) 
{
	if(!is_user_alive(id))
		return;
	
	if(zp_get_user_zombie(id))
		return;
	
	static amount
	amount = 0
	
	if(get_user_flags(id) & VM_ACESS)
		amount = get_pcvar_num(cvar_armor_amount)
	else if(get_pcvar_num(cvar_free_armor))
		amount = get_pcvar_num(cvar_free_armor)
		
	if(get_user_armor(id) < amount)
		set_user_armor(id, amount)
}
#endif

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED
		
	if(zp_get_user_zombie(attacker) || !(get_user_flags(attacker) & VM_ACESS))
		return HAM_IGNORED

	damage *= get_pcvar_float(g_damage_increase)
	SetHamParamFloat(4, damage)

	if(get_pcvar_num(g_damage_reward) > 0) {
		g_damage[attacker] += damage
		if(g_damage[attacker] > get_pcvar_float(g_damage_reward)) {
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker)+1)
			g_damage[attacker] -= get_pcvar_float(g_damage_reward)
		}
	}
	
	return HAM_IGNORED
}

/*===============================================================================
[Menu /vm]
=================================================================================*/
public extra_itens_menu(id)
{
	if(!is_user_alive(id))
		return
	
	if(g_registered_items_count == 0 || zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) 
	{
		client_print_color(id, print_team_default, "%s Menu de Itens Extras Desativado para sua classe!", CHAT_PREFIX)
		return;
	}
		
	static holder[150], menu, i, team_check, ammo_packs, check
	formatex(holder, charsmax(holder), "%s Vip Main Menu:^nTeam: %s^n\wStatus: %s", MENU_TAG, zp_get_user_zombie(id) ? "\r[Zombie]" : "\y[Humano]", get_user_flags(id) & VM_ACESS ? "\rCom Vip :)" : "\rSem Vip :(")
	
	menu = menu_create(holder, "extra_itens_menu_handler")
	check = 0
	ammo_packs = zp_get_user_ammo_packs(id)
	
	team_check = zp_get_user_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN
	
	if(zp_get_user_zombie(id)) team_check |= ZP_TEAM_ZOMBIE
	else if(!zp_get_user_zombie(id)) team_check |= ZP_TEAM_HUMAN

	g_team[id] = team_check
	for(i=0; i < g_registered_items_count; i++) {
		g_AdditionalMenuText[0] = 0
		ArrayGetArray(items_database, i, extra_items)
		if(extra_items[i_team] == 0 || g_team[id] & extra_items[i_team]) {
			ExecuteForward(g_forwards[ITEMS_SELECTED_PRE], g_forward_return, id, i+1)
			if (g_forward_return >= ZV_PLUGIN_SUPERCEDE)
				continue;
			
			if(g_forward_return >= ZP_PLUGIN_HANDLED || !(get_user_flags(id) & VM_ACESS)) {
				formatex(holder, charsmax(holder), "\d%s [%s] [%d] %s", extra_items[i_name], extra_items[i_description] , extra_items[i_cost], g_AdditionalMenuText)
				menu_additem(menu, holder, fmt("%d", i), (1<<30))
			}
			else  {
				formatex(holder, charsmax(holder), "%s%s %s[%s] %s[%d] %s", ammo_packs < extra_items[i_cost] ? "\d" : "\w", extra_items[i_name], ammo_packs < extra_items[i_cost] ? "\d" : "\r", extra_items[i_description], ammo_packs < extra_items[i_cost] ? "\d" : "\r", extra_items[i_cost], g_AdditionalMenuText)
				menu_additem(menu, holder, fmt("%d", i), 0)
			}
			check++
		}
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
 
public extra_itens_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	if(!(get_user_flags(id) & VM_ACESS))
	{
		client_print_color(id, print_team_default, "%s Voce Nao eh Membro ^4*VIP*", CHAT_PREFIX)
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if(zp_get_human_special_class(id) || zp_get_zombie_special_class(id)) 
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	static team_check; 
	team_check = zp_get_user_zombie(id) ? ZP_TEAM_ZOMBIE : ZP_TEAM_HUMAN
	
	if(zp_get_user_zombie(id)) team_check |= ZP_TEAM_ZOMBIE
	else if(!zp_get_user_zombie(id)) team_check |= ZP_TEAM_HUMAN
	
	if(g_team[id] != team_check) {
		
		menu_destroy(menu)
		extra_itens_menu(id)
		return PLUGIN_HANDLED;
	}
	
	static data[6], iName[64], item_id, ammo_packs, aaccess, callback
	menu_item_getinfo(menu, item, aaccess, data, charsmax(data), iName, charsmax(iName), callback)
	item_id = str_to_num(data)
	
	ExecuteForward(g_forwards[ITEMS_SELECTED_PRE], g_forward_return, id, item_id+1)
	if (g_forward_return >= ZP_PLUGIN_HANDLED || g_forward_return2 >= ZP_PLUGIN_HANDLED) return PLUGIN_HANDLED;
	
	ammo_packs = zp_get_user_ammo_packs(id)
	ArrayGetArray(items_database, item_id, extra_items)
	
	if(ammo_packs >= extra_items[i_cost]) zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - extra_items[i_cost])
	else 
	{
		client_print_color(id, print_team_default, "%s Voce Nao tem Ammo Packs suficiente", CHAT_PREFIX)
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	item_id++
	
	ExecuteForward(g_forwards[ITEMS_SELECTED_POST], g_forward_return, id, item_id)
	if (g_forward_return >= ZP_PLUGIN_HANDLED || g_forward_return2 >= ZP_PLUGIN_HANDLED) zp_set_user_ammo_packs(id, ammo_packs)

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

/*===============================================================================
[Native Action]
=================================================================================*/
public native_register_extra_item(const item_name[], const item_discription[], item_cost, item_team)
{
	param_convert(1)
	param_convert(2)
	
	if(!items_database) items_database = ArrayCreate(items)
	copy(extra_items[i_name], 64, item_name)
	copy(extra_items[i_description], 64, item_discription)
	extra_items[i_cost] = item_cost
	extra_items[i_team] = item_team
	ArrayPushArray(items_database, extra_items)
	g_registered_items_count++

	return g_registered_items_count
}

public plugin_end() if(items_database) ArrayDestroy(items_database);

/*===============================================================================
[Multijump]
=================================================================================*/
public client_putinserver(id) {
	#if defined MULTIJUMP_ENABLE
	jumpnum[id] = 0
	dojump[id] = false
	#endif
	
	static name[32]; get_user_name(id, name, charsmax(name))
	if(get_user_flags(id) & ADMIN_RESERVATION)
		client_print_color(0, print_team_default, "%s O Jogador ^4*VIP*^1 %s ^3Conectou-se ao Servidor", CHAT_PREFIX, name)
}

#if defined MULTIJUMP_ENABLE
public client_disconnected(id)
{
	jumpnum[id] = 0
	dojump[id] = false
}

public client_PreThink(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if(zp_get_user_zombie(id) && !get_pcvar_num(cvar_zmmultijump)) 
		return PLUGIN_CONTINUE

	static nbut, obut
	nbut = get_user_button(id)
	obut = get_user_oldbutton(id)
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jumpnum[id] < get_pcvar_num(cvar_maxjumps) && (get_user_flags(id) & VM_ACESS) 
		|| jumpnum[id] < get_pcvar_num(cvar_freemaxjumps))
		{
			dojump[id] = true
			jumpnum[id]++
			return PLUGIN_CONTINUE
		}
	}
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if(zp_get_user_zombie(id) && !get_pcvar_num(cvar_zmmultijump)) 
		return PLUGIN_CONTINUE

	if(dojump[id] == true) {
		static Float:velocity[3]	
		entity_get_vector(id, EV_VEC_velocity, velocity)
		velocity[2] = random_float(265.0, 285.0)
		entity_set_vector(id, EV_VEC_velocity, velocity)
		dojump[id] = false
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}	
#endif

public setVip() {
	static i;
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(get_user_flags(i) & VM_ACESS) {
			message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"))
			write_byte(i)
			write_byte(4)
			message_end()
		}
	}
	return PLUGIN_HANDLED
}
