if GameMode == nil then
	print("Initializing game mode...")
	_G.GameMode = class({})
end

function GameMode:PostLoadPrecache()
	print("Performing post-load precache...")    
	--PrecacheItemByNameAsync("item_example_item", function(...) end)
	--PrecacheItemByNameAsync("example_ability", function(...) end)
	--PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
end

function GameMode:OnFirstPlayerLoaded()
	print("First player has finished loading the gamemode")
end

function GameMode:OnAllPlayersLoaded()
	print("All players have finished loading the gamemode")
end

function GameMode:OnHeroInGame(hero)
	print(hero:GetUnitName() .. " spawned in game for the first time.")
	if hero:FindAbilityByName("basic_shot") then hero:FindAbilityByName("basic_shot"):SetLevel(1) end
	if hero:FindAbilityByName("windrunner_windrun") then hero:FindAbilityByName("windrunner_windrun"):SetLevel(1) end
end

function GameMode:OnGameInProgress()
	if IsServer() then
		print("The game has officially begun")

		self.enemy_types = {
			"npc_autofire_mechanospider",
			"npc_autofire_black_drake",
			"npc_autofire_harpy"
		}

		self.boon_types = {}
		table.insert(self.boon_types, "damage")
		table.insert(self.boon_types, "range")
		--table.insert(self.boon_types, "speed")
		table.insert(self.boon_types, "health")
		table.insert(self.boon_types, "armor")
		table.insert(self.boon_types, "movement")
		table.insert(self.boon_types, "cooldown")
		table.insert(self.boon_types, "bullet")
		table.insert(self.boon_types, "multishot")
		table.insert(self.boon_types, "crit_up")
		table.insert(self.boon_types, "crit_pow_up")

		CustomGameEventManager:RegisterListener("boon_selected", Dynamic_Wrap(self, 'ApplyBoon'))

		self.main_hero = PlayerResource:GetSelectedHeroEntity(0)
		self.waiting_for_boon_choice = false
		self.currently_spawning = false

		local min_x = -1344
		local min_y = -1472
		local max_x = 1408
		local max_y = 1088

		self.spawn_info = {}
		self.spawn_info.x_rand = max_x - min_x
		self.spawn_info.x_offset = min_x
		self.spawn_info.x_center = 0.5 * self.spawn_info.x_rand
		self.spawn_info.x_block_range = self.spawn_info.x_rand / 5

		self.spawn_info.y_rand = max_y - min_y
		self.spawn_info.y_offset = min_y
		self.spawn_info.y_center = 0.5 * self.spawn_info.y_rand
		self.spawn_info.y_block_range = self.spawn_info.y_rand / 5

		self.round_info = {}

		self:StartRound(1)
	end
end

function GameMode:GetRandomSpawnPosition()
	local x_rand = RandomInt(0, self.spawn_info.x_rand)
	local y_rand = RandomInt(0, self.spawn_info.y_rand)

	if math.abs(x_rand - self.spawn_info.x_center) < self.spawn_info.x_block_range and math.abs(y_rand - self.spawn_info.y_center) < self.spawn_info.y_block_range then
		return self:GetRandomSpawnPosition()
	end

	return Vector(x_rand + self.spawn_info.x_offset, y_rand + self.spawn_info.y_offset, 0)
end

function GameMode:StartRound(round)

	self.round_enemy = self.enemy_types[RandomInt(1, #self.enemy_types)]
	self.enemy_health = (60 + (15 + 5 * math.floor(0.2 * round)) * (round - 1)) * (1 + 0.01 * math.max(0, round - 20) ^ 1.5)
	self.enemy_damage = (30 + (5 + math.floor(0.2 * round)) * (round - 1)) * (1 + 0.01 * math.max(0, round - 20) ^ 1.5)
	self.enemy_count = 10 + 2 * math.floor(0.2 * round)
	self.spawn_interval = 0.2

	self.round_info.round_number = round
	self.round_info.round_enemy = self.round_enemy
	self.round_info.round_count = self.enemy_count

	CustomNetTables:SetTableValue("game_state", "round_info", self.round_info)

	self.entity_kill_listener = ListenToGameEvent("entity_killed", Dynamic_Wrap(GameMode, 'OnRoundKill'), self)

	self.current_spawns = {}
	self.currently_spawning = true
	local spawn_count = 0

	Timers:CreateTimer(0, function()
		local unit = CreateUnitByName(self.round_enemy, self:GetRandomSpawnPosition(), true, nil, nil, DOTA_TEAM_NEUTRALS)

		unit:SetBaseMaxHealth(self.enemy_health)
		unit:SetMaxHealth(self.enemy_health)
		unit:SetHealth(self.enemy_health)

		unit:SetBaseDamageMin(self.enemy_damage)
		unit:SetBaseDamageMax(self.enemy_damage)

		if unit:FindAbilityByName("dragon_shot") then unit:FindAbilityByName("dragon_shot"):SetLevel(1) end
		if unit:FindAbilityByName("harpy_shot") then unit:FindAbilityByName("harpy_shot"):SetLevel(1) end

		table.insert(self.current_spawns, unit)

		spawn_count = spawn_count + 1

		if spawn_count < self.enemy_count then
			return self.spawn_interval
		else
			self.currently_spawning = false
		end
	end)
end

-- Creep kill listener
function GameMode:OnRoundKill(keys)
	local killed_unit = EntIndexToHScript(keys.entindex_killed)

	-- If the player was killed, restart the game
	if killed_unit == self.main_hero then
		self:RestartGame()
		return
	end

	-- Remove this unit from the current spawn table
	for _, creep in pairs(self.current_spawns) do
		if creep == killed_unit then
			self:TryEndRound()
			return
		end
	end
end

function GameMode:TryEndRound()
	if self.currently_spawning then return end

	for _, creep in pairs(self.current_spawns) do
		if (not creep:IsNull()) and creep:IsAlive() then return end
	end

	StopListeningToGameEvent(self.entity_kill_listener)

	self.main_hero:AddExperience(100, DOTA_ModifyXP_CreepKill, false, true)
	self.main_hero:SetHealth(self.main_hero:GetMaxHealth())

	local boon_choices = table.random_some(self.boon_types, 3)
	CustomGameEventManager:Send_ServerToAllClients("show_boon_choice", boon_choices)

	local time_to_next_round = 3
	CustomNetTables:SetTableValue("game_state", "next_round_timer", {next_round_timer = time_to_next_round})
	self.waiting_for_boon_choice = true

	Timers:CreateTimer(1, function()
		
		if (not self.waiting_for_boon_choice) then
			time_to_next_round = time_to_next_round - 1
			CustomNetTables:SetTableValue("game_state", "next_round_timer", {next_round_timer = time_to_next_round})
		end

		if time_to_next_round <= 0 then
			self:StartRound(1 + self.round_info.round_number)
		else
			return 1
		end
	end)
end

function GameMode:RestartGame()
	StopListeningToGameEvent(self.entity_kill_listener)

	for _, creep in pairs(self.current_spawns) do
		if (not creep:IsNull()) then
			creep:Destroy()
			UTIL_Remove(creep)
		end
	end

	self.current_spawns = {}

	Timers:CreateTimer(5, function()
		PlayerResource:ReplaceHeroWith(0, "npc_dota_hero_wisp", 0, 0)
		self.main_hero = PlayerResource:ReplaceHeroWith(0, "npc_dota_hero_windrunner", 0, 0)
	end)

	Timers:CreateTimer(10, function()
		self:StartRound(1)
	end)
end

function GameMode:ApplyBoon(keys)
	local ability = GameMode.main_hero:FindAbilityByName("basic_shot")
	if not ability then return end

	if keys.boon_name == "damage" then
		ability.shot_damage = ability.shot_damage + 50
	elseif keys.boon_name == "range" then
		ability.shot_range = ability.shot_range + 150
		ability.shot_speed = ability.shot_speed + 200
	elseif keys.boon_name == "speed" then
		ability.shot_speed = ability.shot_speed + 250
	elseif keys.boon_name == "bullet" then
		ability.shot_count = ability.shot_count + 1
		if ability.shot_count >= 12 then GameMode:RemoveBoonOption("bullet") end
	elseif keys.boon_name == "multishot" then
		ability.shot_layers = ability.shot_layers + 1
		if ability.shot_layers >= 4 then GameMode:RemoveBoonOption("multishot") end
	elseif keys.boon_name == "crit_up" then
		ability.crit_chance = ability.crit_chance + 4
		if ability.crit_chance >= 100 then GameMode:RemoveBoonOption("crit_up") end
	elseif keys.boon_name == "crit_pow_up" then
		ability.crit_pow = ability.crit_pow + 0.25
	elseif keys.boon_name == "health" then
		GameMode.main_hero:AddNewModifier(GameMode.main_hero, nil, "modifier_basic_shot_health", {})
	elseif keys.boon_name == "armor" then
		GameMode.main_hero:AddNewModifier(GameMode.main_hero, nil, "modifier_basic_shot_armor", {})
	elseif keys.boon_name == "movement" then
		GameMode.main_hero:AddNewModifier(GameMode.main_hero, nil, "modifier_basic_shot_ms", {})
	elseif keys.boon_name == "cooldown" then
		GameMode.main_hero:AddNewModifier(GameMode.main_hero, nil, "modifier_basic_shot_cdr", {})
	end

	GameMode.waiting_for_boon_choice = false
end

function GameMode:RemoveBoonOption(boon_to_remove)
	for boon_index, boon_type in pairs(self.boon_types) do
		if boon_type == boon_to_remove then
			table.remove(self.boon_types, boon_index)
			return
		end
	end
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
	GameMode = self
	print("Performing initialization tasks...")

	-- Global filter setup
	--GameRules:GetGameModeEntity():SetModifyGoldFilter(Dynamic_Wrap(GameMode, "GoldFilter"), self)
	--GameRules:GetGameModeEntity():SetModifyExperienceFilter(Dynamic_Wrap(GameMode, "ExpFilter"), self)
	--GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(GameMode, "DamageFilter"), self)
	--GameRules:GetGameModeEntity():SetModifierGainedFilter(Dynamic_Wrap(GameMode, "ModifierFilter"), self)
	--GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "OrderFilter"), self)

	-- Custom console commands
	--Convars:RegisterCommand("runes_on", Dynamic_Wrap(GameMode, 'EnableAllRunes'), "Enables all runes", FCVAR_CHEAT )
	--Convars:RegisterCommand("runes_off", Dynamic_Wrap(GameMode, 'DisableAllRunes'), "Disables all runes", FCVAR_CHEAT )

	-- Custom listeners
	--CustomGameEventManager:RegisterListener("increase_game_speed", Dynamic_Wrap(GameMode, "IncreaseGameSpeed"))

	print("Initialization tasks done!")
end

-- Global gold filter function
function GameMode:GoldFilter(keys)

	-- Ignore negative gold values
	if keys.gold <= 0 then
		return false
	end

	-- Gold from abandoning players does not get multiplied
	if keys.reason_const == DOTA_ModifyGold_AbandonedRedistribute or keys.reason_const == DOTA_ModifyGold_GameTick then
		return true
	end

	-- Bonus gold from settings
	--keys.gold = keys.gold * GAME_SPEED_MULTIPLIER

	return true
end

-- Global experience filter function
function GameMode:ExpFilter(keys)
	--keys.experience: 40
	--keys.player_id_const: 1
	--keys.reason_const: 1

	-- Ignore negative experience values
	if keys.experience < 0 then
		return false
	end

	-- Bonus EXP from settings
	--keys.experience = keys.experience * GAME_SPEED_MULTIPLIER

	return true
end

-- Global damage filter function
function GameMode:DamageFilter(keys)
	-- keys.damage: 5
	-- keys.damagetype_const: 1
	-- keys.entindex_inflictor_const: 801	--optional
	-- keys.entindex_attacker_const: 172
	-- keys.entindex_victim_const: 379

	local attacker = EntIndexToHScript(keys.entindex_attacker_const)
	local victim = EntIndexToHScript(keys.entindex_victim_const)

	return true
end

-- Global modifier filter function
function GameMode:ModifierFilter(keys)
	--keys.duration: -1
	--keys.entindex_ability_const: 164	--optional
	--keys.entindex_caster_const: 163
	--keys.entindex_parent_const: 163
	--keys.name_const: modifier_kobold_taskmaster_speed_aura

	if not keys.entindex_caster_const then return true end

	local duration = keys.duration
	local caster = EntIndexToHScript(keys.entindex_caster_const)
	local parent = EntIndexToHScript(keys.entindex_parent_const)

	return true
end

-- Global order filter function
function GameMode:OrderFilter(keys)

	-- keys.entindex_ability	 ==> 	0
	-- keys.sequence_number_const	 ==> 	20
	-- keys.queue	 ==> 	0
	-- keys.units	 ==> 	table: 0x031d5fd0
	-- keys.entindex_target	 ==> 	0
	-- keys.position_z	 ==> 	384
	-- keys.position_x	 ==> 	-5694.3334960938
	-- keys.order_type	 ==> 	1
	-- keys.position_y	 ==> 	-6381.1127929688
	-- keys.issuer_player_id_const	 ==> 	0

	local order_type = keys.order_type

	return true
end