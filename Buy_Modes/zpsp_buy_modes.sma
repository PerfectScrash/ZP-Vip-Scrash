/*
	[ZPSp *VIP* Extra Item] Mods

	* Descricao do Plugin:
		- Compre o mod que quiser quando for possivel de acordo com a contagem de rounds.

	* Change Log:
		- 1.0: Primeira Versao
		- 1.1: Fixado alguns bugs e pequenas melhorias no codigo
		- 1.2: Adicionado Variados mods e o plugin funciona mesmo com esses mods desligados
		- 1.3: Melhoria Profunda no codigo
		- 1.4: Passando suporte somente ao amx 1.8.3 ou superior
*/

/*-------------------------------------------------------------
-----> Includes <-----
-------------------------------------------------------------*/
#include <amxmodx>
#include <zombie_plague_special>
#include <zpsp_vip>

/*-------------------------------------------------------------
-----> Configuracoes <-----
-------------------------------------------------------------*/

// Prefixo no Chat
#define CHAT_PREFIX "^4[ZP]^1"

/*-------------------------------------------------------------
-----> Configuracoes avancadas  <-----
-------------------------------------------------------------*/
// Classes especiais (Eh necessario mexer aqui caso queira remover/adicionar uma classe)
enum {
	// Classes do plugin principal
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

	// Classes Externas (Plugin nao depende delas para funcionar)
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

	// Private modes
	_GOKU,
	_FRIEZA,
	_GOLD_FRIEZA,
	_KURILIN,
	_MARIO,
	_NARUTO,

	MAX_MODS
}

// Enum manipuladora de variavel
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

// Registro das classes - Tenha cuidado na hora de adicionar ou remover, pois tem que estar na mesma ordem das enums
/* 
	- Nome Real: O nome que fica na sma da classe especial
	- Nome no menu: O Nome que ficara no item extra
	- Descricao: Descricao da classe especial
	- Preco: Preco em Ammo packs da Classe
	- Nome da Cvar: Nome da Cvar de Compra
	- Valor da Cvar: Valor padrao da cvar de compra
	- Time: É Classe Especial Humana ou Classe Especial Zumbi - (Use GET_HUMAN para Humano e GET_ZOMBIE para zumbi)	
*/
new const Mods[MAX_MODS][_handler] = {

	// "Nome real" "Nome no Menu" "Descricao", Preco, "Nome da Cvar", "Valor da Cvar", Time

	// Classes Internas do Plugin Principal
	{ "survivor", "Survivor", "Municao Infinita", 75, "zp_vip_buy_survivor_limit", "1", GET_HUMAN },
	{ "nemesis", "Nemesis", "O Imortal", 75, "zp_vip_buy_nemesis_limit", "1", GET_ZOMBIE },
	{ "sniper", "Sniper", "O Tiro", 75, "zp_vip_buy_sniper_limit", "1", GET_HUMAN },
	{ "assassin", "Assassino", "O Nome ja Diz", 75, "zp_vip_buy_assassin_limit", "1", GET_ZOMBIE },
	{ "berserker", "Berserker", "O Ninja", 75, "zp_vip_buy_berserker_limit", "1", GET_HUMAN },
	{ "predator", "Predator", "Assassino Invisivel", 75, "zp_vip_buy_predator_limit", "1", GET_ZOMBIE },
	{ "dragon", "Dragon", "Pode Voar", 75, "zp_vip_buy_dragon_limit", "1", GET_ZOMBIE },
	{ "wesker", "Wesker", "Deagle da Morte", 75, "zp_vip_buy_wesker_limit", "1", GET_HUMAN },
	{ "bombardier", "Bombardier", "Granadas do Infinito", 75, "zp_vip_buy_bombardier_limit", "1", GET_ZOMBIE },
	{ "spy", "Spy", "Punheteiro Invisivel", 75, "zp_vip_buy_spy_limit", "1", GET_HUMAN },

	// Classes Externas (O plugin nao depende delas pra funcionar)
	{ "Morpheus", "Morpheus", "Dual MP5", 75, "zp_vip_buy_morpheus_limit", "1", GET_HUMAN },
	{ "Chuck Norris", "Chuck Norris", "Ate o Thanos Treme", 75, "zp_vip_buy_chuck_norris_limit", "1", GET_HUMAN },
	{ "Alien", "Alien", "ETzaum", 75, "zp_vip_buy_alien_limit", "1", GET_ZOMBIE },
	{ "Raptor", "Raptor", "Mais Rapido que o Sonic", 75, "zp_vip_buy_raptor_limit", "1", GET_ZOMBIE },
	{ "Dog", "Cachorro", "Esse Morde", 75, "zp_vip_buy_dog_limit", "1", GET_ZOMBIE },
	{ "Priest", "Padre", "Tira o Capeta do Zumbi", 75, "zp_vip_buy_priest_limit", "1", GET_HUMAN },
	{ "Thanos", "Thanos", "O Fodao", 75, "zp_vip_buy_thanos_limit", "1", GET_ZOMBIE },
	{ "Pain", "Pain (Nagato)", "O Mundo tem que conhecer a DOR", 75, "zp_vip_buy_pain_limit", "1", GET_HUMAN },
	{ "Plasma", "Plasma", "Plasma Rifle FODA", 75, "zp_vip_buy_plasma_limit", "1", GET_HUMAN },
	{ "Sonic", "Sonic the Hedgehog", "Melhor que Mario", 75, "zp_vip_buy_sonic_limit", "1", GET_HUMAN },
	{ "Shadow", "Shadow the Hedgehog", "O Vegeta do Sonic", 75, "zp_vip_buy_shadow_limit", "1", GET_ZOMBIE },
	{ "Xiter", "Xiter", "Nao Use", 75, "zp_vip_buy_xiter_limit", "1", GET_HUMAN },
	{ "Antidoter", "Antidoter", "Vacina conta T-Virus", 75, "zp_vip_buy_antidoter_limit", "1", GET_HUMAN },
	{ "Grenadier", "Grenadier", "Bombinhas mortais", 75, "zp_vip_buy_grenadier_limit", "1", GET_HUMAN },
	
	// Private modes (O plugin nao depende deles pra funcionar)
	{ "Goku", "Goku", "Dragon Ball Z", 75, "zp_vip_buy_goku_limit", "1", GET_HUMAN },
	{ "Frieza", "Frieza", "Dragon Ball Z", 75, "zp_vip_buy_frieza_limit", "1", GET_ZOMBIE },
	{ "Golden Frieza", "Frieza", "Dragon Ball Z", 75, "zp_vip_buy_frieza_limit", "1", GET_ZOMBIE },
	{ "Krillin", "Kurilin", "So sabe morrer", 75, "zp_vip_buy_krillin_limit", "1", GET_HUMAN },
	{ "Mario", "Mario Bros", "Aquele que te come atras do armario", 75, "zp_vip_buy_mario_limit", "1", GET_HUMAN },
	{ "Naruto", "Naruto", "Tem 9 caudas no cu", 75, "zp_vip_buy_naruto_limit", "1", GET_HUMAN }
};

/*-------------------------------------------------------------
-----> Variaveis <-----
-------------------------------------------------------------*/
new g_item_id[MAX_MODS], cvar_limit[MAX_MODS], g_limit[MAX_MODS], allow_buy, rounds_passados, cvar_rounds_for_buy, classes_compradas, cvar_mods_per_map
new primeira_compra, block, g_mods_id[MAX_MODS]

/*-------------------------------------------------------------
-----> Registro de plugin <-----
-------------------------------------------------------------*/
public plugin_init() {
	
	register_plugin("[ZPSp] *VIP* Item: Buy modes + Round count", "1.5", "Perfect Scrash") // Registro do plugin

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0") // Inicio de round
	register_event("TextMsg", "event_game_commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");  // Reseta o contador

	cvar_mods_per_map =  register_cvar("zp_vip_buy_classes_map", "3")  // Limite Por Mapa
	cvar_rounds_for_buy = register_cvar("zp_vip_buy_classes_rounds", "5") // Comprar de 5 em 5 rounds

	register_clcmd("say /rounds", "check_round")
	register_clcmd("say .rounds", "check_round")
	register_clcmd("say /round", "check_round")
	register_clcmd("say .round", "check_round")

	for(new i = 0; i < MAX_MODS; i++) {
		g_item_id[i] = -1 // Valor para classe desligada
		g_mods_id[i] = zp_get_special_class_id(Mods[i][is_zombie], Mods[i][ModRealName]) // Pesquisa o nome da classe nos registos da base special
		
		if(g_mods_id[i] == -1) // Se nao encontrar
			continue;

		if(!zp_is_special_class_enable(Mods[i][is_zombie], g_mods_id[i])) // Se encontrar e estiver desligado
			continue;

		g_item_id[i] = zv_register_extra_item(Mods[i][ModName], Mods[i][ModDescription], Mods[i][Price], ZP_TEAM_HUMAN) // Registro do item da classe correspondente
		cvar_limit[i] = register_cvar(Mods[i][CvarName], Mods[i][CvarValue]) // Limite de Compras por Mapa da Classe correspondente
	}	
}

/*-------------------------------------------------------------
-----> Funcoes Principais <-----
-------------------------------------------------------------*/
// Inicio do Mapa / Restart Round
public event_game_commencing() 
{
	rounds_passados = 0 		// Zera contador de rounds
	classes_compradas = 0 		// Zera o Limite de classes ao todo
	primeira_compra = false 	// Declara como se ninguem tivesse comprado nenhum mod
	block = false 				// "Desbloqueia a compra"
	
	// Zera o limite das classes correspondente
	static i;
	for(i = 0; i < MAX_MODS; i++) 
		g_limit[i] = 0
}

// Inicio do round
public event_round_start() { 
	allow_buy = false 	// Anti-Bug - Bloqueia a compra nos primeiros segundos do round
	rounds_passados++ 	// Incrementa a contagem de rounds
	
	set_task(5.0, "task_allow_buy"); // Anti-Bug - Desbloqueio das compras apos os primeiros segundos
	
	check_round(0); // Mostrar mensagem pra todos
}

public check_round(id) {
	if(zp_is_escape_map()) // Mapa de zombie escape
		client_print_color(id, print_team_grey, "%s Mapas de zombie escape nao ha compra de mods. ^3[Compras de Mods Indisponiveis]", CHAT_PREFIX)

	else if(classes_compradas >= get_pcvar_num(cvar_mods_per_map)) // Compras por mapa de todos os mods
		client_print_color(id, print_team_grey, "%s Ja Foram Comprados ^3%d^1 Mods Nesse Mapa. ^3[Compras de Mods Indisponiveis]", CHAT_PREFIX, get_pcvar_num(cvar_mods_per_map))

	else if(block) // Travamento basico para evitar mods seguidos
		client_print_color(id, print_team_grey, "%s Alguem Ganhou Mod no Round Passado Aguarde mais alguns rounds. ^3[Compra Nao Permitida]", CHAT_PREFIX)

	else if(!primeira_compra) // Verifica se eh a primeira compra, caso sim, libera a compra no segundo round do mapa
		client_print_color(id, print_team_blue, "%s Ainda Nao foram comprados mods Nesse mapa. %s", CHAT_PREFIX, rounds_passados > 1 ? "^4[Compra Permitida]" : "^3[Compra Permitida somente no Proximo Round]")
	
	else // Verifica se passou os rounds o suficiente
		client_print_color(id, print_team_default, "%s Passou ^3%d^1 Round(s) depois da Ultima Compra de Mod. ^4%s", CHAT_PREFIX, rounds_passados, rounds_passados >= get_pcvar_num(cvar_rounds_for_buy) ? "^4[Compra Permitida]" : "")
}

// Desbloqueio da compra
public task_allow_buy() 
	allow_buy = true;

// Inicio de Mod
public zp_round_started(gm) {

	// Verifica se eh mod de classe especial (Externo ou nao) [Gambiarra]
	if(gm != MODE_INFECTION && gm != MODE_MULTI && gm != MODE_SWARM && gm != MODE_PLAGUE && gm != MODE_LNJ) { 
		if(get_alive_specials() == 1)
			block = true
		else
			block = false
	}
	else 
		block = false
}

// Ao comprar o item
public zv_extra_item_selected(id, itemid) 
{
	static i;
	for(i = 0; i < MAX_MODS; i++)
	{
		if(g_item_id[i] == -1)
			continue;
		
		if(itemid == g_item_id[i]) 
		{
			if(!get_mod_buy_allow(id, i))
				return ZV_PLUGIN_HANDLED;
			
			set_user_mod(id, i)
			break;
		}
	}
	return PLUGIN_CONTINUE
}

// Verifica se esta disponivel a classe, caso contrario a classe ira ficar oculto no VM. [Somente nos VMs especificos]
public zv_extra_item_selected_pre(id, itemid) 
{
	static i;
	for(i = 0; i < MAX_MODS; i++) 
	{
		if(g_item_id[i] == -1)
			continue;

		if(itemid == g_item_id[i] && (zp_has_round_started() || !get_pcvar_num(cvar_limit[i])))
			return ZV_PLUGIN_SUPERCEDE
	}
	return PLUGIN_CONTINUE
}

// Verifica se esta disponivel
public get_mod_buy_allow(id, mod)
{
	if(zp_is_escape_map()) {
		client_print_color(id, print_team_grey, "%s Mapas de zombie escape nao ha compra de mods. ^3[Compras de Mods Indisponiveis]", CHAT_PREFIX)
		return false;
	}
	if(get_pcvar_num(cvar_limit[mod]) <= 0) {
		client_print_color(id, print_team_default, "%s A Compra desse mod esta desligada no momento", CHAT_PREFIX)
		return false
	}

	if(primeira_compra) { // Ja houve compra de mods
		if(rounds_passados < get_pcvar_num(cvar_rounds_for_buy)) { // Nao passou os rounds o bastante
			client_print_color(id, print_team_default, "%s Aguarde Mais Alguns Rounds Para Comprar Mod", CHAT_PREFIX)
			return false
		}
		if(classes_compradas >= get_pcvar_num(cvar_mods_per_map)) { // Limite por mapa atingido
			client_print_color(id, print_team_default, "%s Ja Foram Comprados ^3%d^1 Mods Nesse Mapa. Compras de Mods Indisponiveis", CHAT_PREFIX, classes_compradas)
			return false
		}
	}
	else { // Nao houve compras ainda
		if(rounds_passados <= 1) {
			client_print_color(id, print_team_default, "%s Primeira Compra de Mod Sera Somente Permitida no Segundo Round do Mapa", CHAT_PREFIX)
			return false
		}
	}

	if(block) { // Ja teve mod especial no round anterior
		client_print_color(id, print_team_red, "%s Alguem Ganhou Mod no Round Passado Aguarde mais alguns rounds. ^3[Compra Nao Permitida]", CHAT_PREFIX)
		return false
	}

	if(g_limit[mod] >= get_pcvar_num(cvar_limit[mod])) { // Limite por mapa de classe especifica
		client_print_color(id, print_team_default, "%s Esse mod ja foi comprado ^3%d^1 vezes nesse mapa. ^3[Tente com outro mod]", CHAT_PREFIX, get_pcvar_num(cvar_limit[mod]))
		return false
	}

	if(zp_has_round_started()) { // Um modo ja foi iniciado
		client_print_color(id, print_team_default, "%s Voce nao pode comprar depois da infeccao.", CHAT_PREFIX) 
		return false
	}

	if(!allow_buy) { // Anti-Bug - Previne que os troxas comprem mod nos primeiros segundos do round
		client_print_color(id, print_team_default, "^4[Anti-Bug]^1 Aguarde Alguns Segundos Para Comprar Mod") 
		return false
	}
	return true
}

// Seta o modo comprado
public set_user_mod(id, mod)
{
	// Verifica se a compra esta disponivel [De novo]
	if(!get_mod_buy_allow(id, mod))
		return;
	
	static name[32];
	get_user_name(id, name, charsmax(name)) // Nome do jogador
	zp_make_user_special(id, g_mods_id[mod], Mods[mod][is_zombie]) // Converte a classe comprada
	client_print_color(0, print_team_default, "%s O Jogador ^3%s ^1Comprou o Mod ^3[%s]^1.", CHAT_PREFIX, name, Mods[mod][ModName]) // Mensagem no chat
	g_limit[mod]++ // Incrementa a contagem para o limite de classe especifica
	rounds_passados = 0 // Zera a contagem de rounds passados
	classes_compradas++ // Incrementa a contagem de vezes que foi comprada
	primeira_compra = true // Declara que ja houve compra de mods
}

// Verifica quantos negos de classe especial estao vivos
stock get_alive_specials()
{
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