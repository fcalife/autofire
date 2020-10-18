-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc
require('dota_but')

-- BMD Libraries
require('libraries/timers')
require('libraries/table')
require('internal/gamesetup')
require('internal/events')
require('events')

-- Game files
require('internal/util')

-- Global modifiers
--LinkLuaModifier("modifier_butt", "global_modifiers", LUA_MODIFIER_MOTION_NONE)

function Precache(context)

	-- Gamemode loading precache
	print("Performing pre-load precache")

	-- Examples
	-- PrecacheResource("particle", "particles/dev/library/base_dust_hit_detail.vpcf", context)
	-- PrecacheResource("particle_folder", "particles/test_particle", context)
	-- PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	-- PrecacheResource("model_folder", "particles/heroes/antimage", context)
	-- PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts", context)
	-- PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
	-- PrecacheItemByNameSync("example_ability", context)

	-- Job ability precaches
	PrecacheResource("soundfile", "soundevents/autofire_soundevents.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/autofire_client_soundevents.vsndevts", context)

	--PrecacheResource("particle_folder", "particles/butt_particles", context)

	--PrecacheResource("particle", "particles/econ/items/drow/drow_ti9_immortal/drow_ti9_base_attack_impact.vpcf", context)

	-- We done
	print("Finished pre-load precache")
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:_InitGameMode()
end