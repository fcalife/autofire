LinkLuaModifier("modifier_basic_shot_thinker", "abilities/basic_shot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_basic_shot_cdr", "abilities/basic_shot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_basic_shot_ms", "abilities/basic_shot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_basic_shot_health", "abilities/basic_shot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_basic_shot_armor", "abilities/basic_shot", LUA_MODIFIER_MOTION_NONE)

upgrade_damage = class({})
upgrade_range = class({})
upgrade_speed = class({})
upgrade_health = class({})
upgrade_armor = class({})
upgrade_movement = class({})
upgrade_cooldown = class({})
upgrade_bullet = class({})
upgrade_multishot = class({})
upgrade_crit_up = class({})
upgrade_crit_pow_up = class({})



basic_shot = class({})

function basic_shot:GetIntrinsicModifierName()
	return "modifier_basic_shot_thinker"
end

function basic_shot:OnUpgrade()
	self.shot_range = 900
	self.shot_speed = 1200
	self.shot_radius = 48
	self.shot_damage = 100
	self.shot_count = 1
	self.shot_layers = 1
	self.crit_chance = 8
	self.crit_pow = 1.5
end

function basic_shot:OnSpellStart()
	self:Shoot(self:GetCursorPosition())
end

function basic_shot:AutoShoot()
	if (not IsServer()) then return end

	local attacker = self:GetCaster()
	local nearby_enemies = FindUnitsInRadius(attacker:GetTeam(), attacker:GetAbsOrigin(), nil, self.shot_range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	local target = nearby_enemies[1] or nil
	if target then
		self:Shoot(target:GetAbsOrigin())
		self:UseResources(true, true, true)
	end
end

function basic_shot:Shoot(location)
	local attacker = self:GetCaster()
	attacker:StartGesture(ACT_DOTA_ATTACK)
	attacker:EmitSound("Ability.Powershot")

	local main_direction = (location - attacker:GetAbsOrigin()):Normalized()
	attacker:SetForwardVector(main_direction)

	local shot_layers = self.shot_layers
	local shot_count = self.shot_count
	local spread = math.min(20, 5 * (shot_count - 1))

	for i = 1, shot_layers do
		local shot_speed = self.shot_speed * 0.8 ^ (i - 1)

		for j = 1, shot_count do
			local spread_angle = (j > 1 and spread * (j - 1) / (shot_count - 1)) or 0
			local shot_direction = RotatePosition(main_direction, QAngle(0, spread_angle - 0.5 * spread, 0), main_direction * 100):Normalized()
			shot_direction = Vector(shot_direction.x, shot_direction.y, 0)

			local shot_projectile = {
				Ability				=	self,
				EffectName			=	"particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf",
				vSpawnOrigin		=	attacker:GetAbsOrigin(),
				fDistance			=	self.shot_range,
				fStartRadius		=	self.shot_radius,
				fEndRadius			=	self.shot_radius,
				Source				=	attacker,
				bHasFrontalCone		=	false,
				bReplaceExisting	=	false,
				iUnitTargetTeam		=	DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags	=	DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType		=	DOTA_UNIT_TARGET_BASIC,
				fExpireTime 		=	GameRules:GetGameTime() + 1.5,
				bDeleteOnHit		=	true,
				vVelocity			=	shot_direction * shot_speed,
				bProvidesVision		=	false
			}

			ProjectileManager:CreateLinearProjectile(shot_projectile)
		end
	end
end

function basic_shot:OnProjectileHit(target, location)
	if IsServer() and target then
		target:EmitSound("Hero_Windrunner.PowershotDamage")

		local damage = self.shot_damage
		if RollPercentage(self.crit_chance) then
			damage = damage * self.crit_pow
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, damage, nil)
		end

		ApplyDamage({victim = target, attacker = self:GetCaster(), damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NONE, ability = self})
	end
	return true
end



modifier_basic_shot_thinker = class({})

function modifier_basic_shot_thinker:IsHidden() return true end
function modifier_basic_shot_thinker:IsDebuff() return false end
function modifier_basic_shot_thinker:IsPurgable() return false end
function modifier_basic_shot_thinker:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_basic_shot_thinker:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true
	}
end

function modifier_basic_shot_thinker:OnCreated(keys)
	if IsServer() then self:StartIntervalThink(0.01) end
end

function modifier_basic_shot_thinker:OnIntervalThink()
	if self:GetAbility():IsCooldownReady() and self:GetAbility():GetAutoCastState() then
		self:GetAbility():AutoShoot()
	end
end



modifier_basic_shot_cdr = class({})

function modifier_basic_shot_cdr:IsHidden() return true end
function modifier_basic_shot_cdr:IsDebuff() return false end
function modifier_basic_shot_cdr:IsPurgable() return false end
function modifier_basic_shot_cdr:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_basic_shot_cdr:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
	}
end

function modifier_basic_shot_cdr:GetModifierPercentageCooldown()
	return 15
end



modifier_basic_shot_ms = class({})

function modifier_basic_shot_ms:IsHidden() return true end
function modifier_basic_shot_ms:IsDebuff() return false end
function modifier_basic_shot_ms:IsPurgable() return false end
function modifier_basic_shot_ms:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_basic_shot_ms:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
	}
end

function modifier_basic_shot_ms:GetModifierMoveSpeedBonus_Constant()
	return 35
end

function modifier_basic_shot_ms:GetModifierIgnoreMovespeedLimit()
	return 1
end



modifier_basic_shot_health = class({})

function modifier_basic_shot_health:IsHidden() return true end
function modifier_basic_shot_health:IsDebuff() return false end
function modifier_basic_shot_health:IsPurgable() return false end
function modifier_basic_shot_health:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_basic_shot_health:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE
	}
end

function modifier_basic_shot_health:GetModifierExtraHealthPercentage()
	return 10
end



modifier_basic_shot_armor = class({})

function modifier_basic_shot_armor:IsHidden() return true end
function modifier_basic_shot_armor:IsDebuff() return false end
function modifier_basic_shot_armor:IsPurgable() return false end
function modifier_basic_shot_armor:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_basic_shot_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_basic_shot_armor:GetModifierPhysicalArmorBonus()
	return 3
end