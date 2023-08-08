/*
	[ZPSp *VIP* Extra Item] Buy Classes

	* Plugin Description:
		- Buy the mod you want when possible according to the round count.

	* Change Log:
		- 1.0: First Version
*/

/*-------------------------------------------------------------
-----> Includes <-----
-------------------------------------------------------------*/
#include <amxmodx>
#include <zombie_plague_special>
#include <zpsp_vip>

/*-------------------------------------------------------------
-----> Config  <-----
-------------------------------------------------------------*/
// Special Classes
enum {
	// Main plugin special classes
	_SURVIVOR = 0,
	_NEMESIS,
	_SNIPER,
	_ASSASSIN,
	_BERSERKER,
	_PREDATOR,
	_DRAGON,
	_WESKER,
	_BOMBARDIER,
	_SPY,

	// External Special Classes (Plugin does not depend on them to work)
	_MORPHEUS,
	_CHUCK,
	_ALIEN,
	_RAPTOR,
	_DOG,
	_PRIEST,
	_THANOS,
	_PAIN,
	_PLASMA,
	_SONIC,
	_SHADOW,
	_XITER,
	_ANTIDOTER,
	_GRENADIER,
	_GOKU,
	_FRIEZA,
	_KURILIN,

	// Private modes
	_MARIO,
	_NARUTO,

	MAX_MODS
}

// Variable Enum
enum _handler 
{ 
	ModRealName[32],
	ModName[32], 
	ModDescription[64], 
	Price,
	CvarName[100],
	CvarValue[10],
	is_zombie 
};

// Buy Class Register - Be careful when adding or removing, as it has to be in the same order as the enums
/* 
	- Real Name: The Real name that used for register special class
	- Name in menu lang key: Name in vip menu
	- Item Description lang key: Description in vip menu
	- Price: Price in ammo packs
	- Cvar Name: Register cvar name
	- Cvar Value: Default Cvar Value of limit
	- Team: Its a Special Human or a Special Zombie - (Use GET_HUMAN for special human or GET_ZOMBIE for special zombie)	
*/
new const Mods[MAX_MODS][_handler] = {

	// "Real Name" "Name in Menu (With Lang)" "Description (With Lang)", Price, "Cvar Name", "Cvar Value", Team

	// Internal Special Classes
	{ "survivor", "BUY_MODE_SURVIVOR_NAME", "BUY_MODE_SURVIVOR_DESC", 75, "zp_vip_buy_survivor_limit", "1", GET_HUMAN },
	{ "nemesis", "BUY_MODE_NEMESIS_NAME", "BUY_MODE_NEMESIS_DESC", 75, "zp_vip_buy_nemesis_limit", "1", GET_ZOMBIE },
	{ "sniper", "BUY_MODE_SNIPER_NAME", "BUY_MODE_SNIPER_DESC", 75, "zp_vip_buy_sniper_limit", "1", GET_HUMAN },
	{ "assassin", "BUY_MODE_ASSASSIN_NAME", "BUY_MODE_ASSASSIN_DESC", 75, "zp_vip_buy_assassin_limit", "1", GET_ZOMBIE },
	{ "berserker", "BUY_MODE_BERSERKER_NAME", "BUY_MODE_BERSERKER_DESC", 75, "zp_vip_buy_berserker_limit", "1", GET_HUMAN },
	{ "predator", "BUY_MODE_PREDATOR_NAME", "BUY_MODE_PREDATOR_DESC", 75, "zp_vip_buy_predator_limit", "1", GET_ZOMBIE },
	{ "dragon", "BUY_MODE_DRAGON_NAME", "BUY_MODE_DRAGON_DESC", 75, "zp_vip_buy_dragon_limit", "1", GET_ZOMBIE },
	{ "wesker", "BUY_MODE_WESKER_NAME", "BUY_MODE_WESKER_DESC", 75, "zp_vip_buy_wesker_limit", "1", GET_HUMAN },
	{ "bombardier", "BUY_MODE_BOMBARDIER_NAME", "BUY_MODE_BOMBARDIER_DESC", 75, "zp_vip_buy_bombardier_limit", "1", GET_ZOMBIE },
	{ "spy", "BUY_MODE_SPY_NAME", "BUY_MODE_SPY_DESC", 75, "zp_vip_buy_spy_limit", "1", GET_HUMAN },

	// External Special Classes (Plugin does not depend on them to work)
	{ "Morpheus", "BUY_MODE_MORPHEUS_NAME", "BUY_MODE_MORPHEUS_DESC", 75, "zp_vip_buy_morpheus_limit", "1", GET_HUMAN },
	{ "Chuck Norris", "BUY_MODE_CHUCK_NORIS_NAME", "BUY_MODE_CHUCK_NORIS_DESC", 75, "zp_vip_buy_chuck_norris_limit", "1", GET_HUMAN },
	{ "Alien", "BUY_MODE_ALIEN_NAME", "BUY_MODE_ALIEN_DESC", 75, "zp_vip_buy_alien_limit", "1", GET_ZOMBIE },
	{ "Raptor", "BUY_MODE_RAPTOR_NAME", "BUY_MODE_RAPTOR_DESC", 75, "zp_vip_buy_raptor_limit", "1", GET_ZOMBIE },
	{ "Dog", "BUY_MODE_DOG_NAME", "BUY_MODE_DOG_DESC", 75, "zp_vip_buy_dog_limit", "1", GET_ZOMBIE },
	{ "Priest", "BUY_MODE_PRIEST_NAME", "BUY_MODE_PRIEST_DESC", 75, "zp_vip_buy_priest_limit", "1", GET_HUMAN },
	{ "Thanos", "BUY_MODE_THANOS_NAME", "BUY_MODE_THANOS_DESC", 75, "zp_vip_buy_thanos_limit", "1", GET_ZOMBIE },
	{ "Pain", "BUY_MODE_PAIN_NAME", "BUY_MODE_PAIN_DESC", 75, "zp_vip_buy_pain_limit", "1", GET_HUMAN },
	{ "Plasma", "BUY_MODE_PLASMA_NAME", "BUY_MODE_PLASMA_DESC", 75, "zp_vip_buy_plasma_limit", "1", GET_HUMAN },
	{ "Sonic", "BUY_MODE_SONIC_NAME", "BUY_MODE_SONIC_DESC", 75, "zp_vip_buy_sonic_limit", "1", GET_HUMAN },
	{ "Shadow", "BUY_MODE_SHADOW_NAME", "BUY_MODE_SHADOW_DESC", 75, "zp_vip_buy_shadow_limit", "1", GET_ZOMBIE },
	{ "Xiter", "BUY_MODE_XITER_NAME", "BUY_MODE_XITER_DESC", 75, "zp_vip_buy_xiter_limit", "1", GET_HUMAN },
	{ "Antidoter", "BUY_MODE_ANTIDOTER_NAME", "BUY_MODE_ANTIDOTER_DESC", 75, "zp_vip_buy_antidoter_limit", "1", GET_HUMAN },
	{ "Grenadier", "BUY_MODE_GRENADIER_NAME", "BUY_MODE_GRENADIER_DESC", 75, "zp_vip_buy_grenadier_limit", "1", GET_HUMAN },
	{ "Goku", "BUY_MODE_GOKU_NAME", "BUY_MODE_GOKU_DESC", 75, "zp_vip_buy_goku_limit", "1", GET_HUMAN },
	{ "Frieza", "BUY_MODE_FRIEZA_NAME", "BUY_MODE_FRIEZA_DESC", 75, "zp_vip_buy_frieza_limit", "1", GET_ZOMBIE },
	{ "Krillin", "BUY_MODE_KRILLIN_NAME", "BUY_MODE_KRILLIN_DESC", 75, "zp_vip_buy_krillin_limit", "1", GET_HUMAN },
	
	// Private modes
	{ "Mario", "BUY_MODE_MARIO_NAME", "BUY_MODE_MARIO_DESC", 75, "zp_vip_buy_mario_limit", "1", GET_HUMAN },
	{ "Naruto", "BUY_MODE_NARUTO_NAME", "BUY_MODE_NARUTO_DESC", 75, "zp_vip_buy_naruto_limit", "1", GET_HUMAN }
}

/*-------------------------------------------------------------
-----> Variable <-----
-------------------------------------------------------------*/
new g_item_id[MAX_MODS], cvar_limit[MAX_MODS], g_limit[MAX_MODS], allow_buy, passed_rounds, cvar_rounds_for_buy, global_buyed_classes, cvar_mods_per_map
new first_buy, block, g_mods_id[MAX_MODS]

/*-------------------------------------------------------------
-----> Plugin Register <-----
-------------------------------------------------------------*/
public plugin_init() {
	
	register_plugin("[ZPSp] *VIP* Item: Buy modes + Round count", "1.0", "Perfect Scrash") // Plugin Register
	register_dictionary("zpsp_vip_buy_modes.txt")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0") // Round Start
	register_event("TextMsg", "event_game_commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");  // Game Commecing

	cvar_mods_per_map =  register_cvar("zp_vip_buy_classes_map", "3")  // Global Map limit
	cvar_rounds_for_buy = register_cvar("zp_vip_buy_classes_rounds", "5") // Buy every 5 rounds

	register_clcmd("say /rounds", "check_round")
	register_clcmd("say .rounds", "check_round")
	register_clcmd("say /round", "check_round")
	register_clcmd("say .round", "check_round")

	for(new i = 0; i < MAX_MODS; i++) {
		g_item_id[i] = -1 // Null value for disable class
		g_mods_id[i] = zp_get_special_class_id(Mods[i][is_zombie], Mods[i][ModRealName]) // Search the class name in the special base registers
		
		if(g_mods_id[i] == -1) // If not find
			continue;

		if(!zp_is_special_class_enable(Mods[i][is_zombie], g_mods_id[i])) // If find but its disable
			continue;

		g_item_id[i] = zv_register_extra_item(Mods[i][ModRealName], Mods[i][ModDescription], Mods[i][Price], ZP_TEAM_HUMAN, 1, Mods[i][ModName], Mods[i][ModDescription]) // Item Register
		cvar_limit[i] = register_cvar(Mods[i][CvarName], Mods[i][CvarValue]) // Register Cvar for class limit
	}	
}

/*-------------------------------------------------------------
-----> Main Functions <-----
-------------------------------------------------------------*/
// Map Start / Restart Round / Game commecing
public event_game_commencing() 
{
	passed_rounds = 0 			// Clear Round counter
	global_buyed_classes = 0 	// Clear a global buy class limit
	first_buy = false 	// Declare as first round
	block = false 				// "Unlock" Buy
	
	// Clear a class limit
	static i;
	for(i = 0; i < MAX_MODS; i++) 
		g_limit[i] = 0
}

// Round Start
public event_round_start() { 
	allow_buy = false 	// Bug Prevention - Blocks buying in the first few seconds of the round
	passed_rounds++ 	// Round count increase
	
	set_task(5.0, "task_allow_buy"); // Bug Prevention - Task for unlock a buy
	
	check_round(0); // Show round count for every player
}

public check_round(id) {
	static id_lang;
	id_lang = is_user_connected(id) ? id : LANG_PLAYER

	if(zp_is_escape_map()) // Escape map
		client_print_color(id, print_team_grey, "%L %L", id_lang, "BUY_MODE_CHAT_PREFIX", id_lang, "BUY_MODE_ESCAPE_NOT_ALLOWED")

	else if(global_buyed_classes >= get_pcvar_num(cvar_mods_per_map)) // Per map purchases of all mods
		client_print_color(id, print_team_grey, "%L %L", id_lang, "BUY_MODE_CHAT_PREFIX", id_lang, "BUY_MODE_MAX_LIMIT", get_pcvar_num(cvar_mods_per_map))

	else if(block) // Prevent consecutive special class rounds
		client_print_color(id, print_team_grey, "%L %L", id_lang, "BUY_MODE_CHAT_PREFIX", id_lang, "BUY_MODE_SPECIAL_ROUND_LAST")

	else if(!first_buy) // Check if it is the first purchase, if so, release the purchase in the second round of the map
		client_print_color(id, print_team_grey, "%L %L", id_lang, "BUY_MODE_CHAT_PREFIX", id_lang, "BUY_MODE_FIRST_BUY", id_lang, passed_rounds > 1 ? "BUY_MODE_ALLOWED" : "BUY_MODE_ALLOWED_NEXT")
	
	else // Check if you passed enough rounds
		client_print_color(id, print_team_grey, "%L %L", id_lang, "BUY_MODE_CHAT_PREFIX", id_lang, "BUY_MODE_ROUND_COUNT", passed_rounds, passed_rounds >= get_pcvar_num(cvar_rounds_for_buy) ? fmt("%L", id_lang, "BUY_MODE_ALLOWED") : "")
}

// Buy Unlock
public task_allow_buy() 
	allow_buy = true;

// Mod Start
public zp_round_started(gm) {

	// Check if it is special class mod (External or not)
	if(gm != MODE_INFECTION && gm != MODE_MULTI && gm != MODE_SWARM && gm != MODE_PLAGUE && gm != MODE_LNJ) { 
		if(get_alive_specials() == 1)
			block = true
		else
			block = false
	}
	else 
		block = false
}

// On buy item
public zv_extra_item_selected(id, itemid) {
	static i;
	for(i = 0; i < MAX_MODS; i++) {
		if(g_item_id[i] == -1)
			continue;
		
		if(itemid == g_item_id[i]) {
			if(!get_mod_buy_allow(id, i))
				return ZV_PLUGIN_HANDLED;
			
			set_user_mod(id, i)
			break;
		}
	}
	return PLUGIN_CONTINUE
}

// Checks if the class is available, otherwise the class will be hidden in the vip menu
public zv_extra_item_selected_pre(id, itemid) {
	static i;
	for(i = 0; i < MAX_MODS; i++) {
		if(g_item_id[i] == -1)
			continue;

		if(itemid == g_item_id[i] && (zp_has_round_started() || !get_pcvar_num(cvar_limit[i])))
			return ZV_PLUGIN_SUPERCEDE
	}
	return PLUGIN_CONTINUE
}

// Check if it's available
public get_mod_buy_allow(id, mod) {
	if(zp_is_escape_map()) {
		client_print_color(id, print_team_grey, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_ESCAPE_NOT_ALLOWED")
		return false;
	}
	if(get_pcvar_num(cvar_limit[mod]) <= 0) {
		client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_DISABLE")
		return false
	}

	if(first_buy) { // There has already been a purchase of mods
		if(passed_rounds < get_pcvar_num(cvar_rounds_for_buy)) { // Didn't go through the rounds enough
			client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_WAIT_ROUNDS")
			return false
		}
		if(global_buyed_classes >= get_pcvar_num(cvar_mods_per_map)) { // Limit per map reached
			client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_MAX_LIMIT", global_buyed_classes)
			return false
		}
	}
	else { // No purchases yet
		if(passed_rounds <= 1) {
			client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_WAIT_SEC_ROUND")
			return false
		}
	}

	if(block) { // Already had a special mod in the previous round
		client_print_color(id, print_team_red, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_SPECIAL_ROUND_LAST")
		return false
	}

	if(g_limit[mod] >= get_pcvar_num(cvar_limit[mod])) { // Limit by specific class map
		client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_SINGLE_MAX_LIMIT", get_pcvar_num(cvar_limit[mod]))
		return false
	}

	if(zp_has_round_started()) { // A game mode has already been started
		client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_NOT_ALLOWED_INFECTION")
		return false
	}

	if(!allow_buy) { // Bug Prevention - Blocks buying in the first few seconds of the round
		client_print_color(id, print_team_default, "%L %L", id, "BUY_MODE_CHAT_PREFIX", id, "BUY_MODE_ANTIBUG")
		return false
	}
	return true
}

// When buy mod set the mode
public set_user_mod(id, mod) {
	// Check if it's available
	if(!get_mod_buy_allow(id, mod))
		return;
	
	static name[32];
	get_user_name(id, name, charsmax(name)) // Player name
	zp_make_user_special(id, g_mods_id[mod], Mods[mod][is_zombie]) // Make user a purchased special class
	client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "BUY_MODE_CHAT_PREFIX", LANG_PLAYER, "BUY_MODE_MOD_PURCHASED", name, LANG_PLAYER, Mods[mod][ModName])
	g_limit[mod]++ // Increments the count to the specified class limit
	passed_rounds = 0 // Clear the count of past rounds
	global_buyed_classes++ // Increments the count of times it was purchased
	first_buy = true // Declares that there has already been a purchase of mods
}

// Check Alive Special Class count
stock get_alive_specials() {
	static count, id
	count = 0

	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue

		if(zp_get_human_special_class(id) || zp_get_zombie_special_class(id))
			count++
	}
	return count;
}