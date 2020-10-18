LinkLuaModifier("modifier_dragon_shot_thinker", "abilities/creep_shots", LUA_MODIFIER_MOTION_NONE)

dragon_shot = class({})

function dragon_shot:GetIntrinsicModifierName()
	return "modifier_dragon_shot_thinker"
end

function dragon_shot:OnUpgrade()
	self.shot_range = 3000
	self.shot_speed = 600 + 100 * math.floor(0.2 * GameMode.round_info.round_number)
	self.shot_radius = 32
	self.shot_damage = 1.25 * GameMode.enemy_damage
end

function dragon_shot:AutoShoot()
	if (not IsServer()) then return end

	if GameMode.main_hero and (not GameMode.main_hero:IsNull()) and GameMode.main_hero:IsAlive() then
		self:Shoot(GameMode.main_hero:GetAbsOrigin())
		self:UseResources(true, true, true)
	end
end

function dragon_shot:Shoot(location)
	local attacker = self:GetCaster()
	attacker:StartGesture(ACT_DOTA_ATTACK)

	attacker:EmitSound("Dragon.Attack")

	local shot_direction = (location - attacker:GetAbsOrigin()):Normalized()
	attacker:SetForwardVector(shot_direction)
	shot_direction = Vector(shot_direction.x, shot_direction.y, 0)

	local shot_origin = attacker:GetAbsOrigin()
	shot_origin = Vector(shot_origin.x, shot_origin.y, 300)

	local shot_projectile = {
		Ability				=	self,
		EffectName			=	"particles/dragon_shot.vpcf",
		vSpawnOrigin		=	shot_origin,
		fDistance			=	self.shot_range,
		fStartRadius		=	self.shot_radius,
		fEndRadius			=	self.shot_radius,
		Source				=	attacker,
		bHasFrontalCone		=	false,
		bReplaceExisting	=	false,
		iUnitTargetTeam		=	DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	=	DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType		=	DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime 		=	GameRules:GetGameTime() + 10,
		bDeleteOnHit		=	true,
		vVelocity			=	shot_direction * self.shot_speed,
		bProvidesVision		=	false
	}

	ProjectileManager:CreateLinearProjectile(shot_projectile)
end

function dragon_shot:OnProjectileHit(target, location)
	if IsServer() and target then
		target:EmitSound("Dragon.Hit")
		ApplyDamage({victim = target, attacker = self:GetCaster(), damage = self.shot_damage, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NONE, ability = self})
	end
	return true
end



modifier_dragon_shot_thinker = class({})

function modifier_dragon_shot_thinker:IsHidden() return true end
function modifier_dragon_shot_thinker:IsDebuff() return false end
function modifier_dragon_shot_thinker:IsPurgable() return false end
function modifier_dragon_shot_thinker:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dragon_shot_thinker:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true
	}
end

function modifier_dragon_shot_thinker:OnCreated(keys)
	if IsServer() then
		self:StartIntervalThink(2.5)
	end
end

function modifier_dragon_shot_thinker:OnIntervalThink()
	self:GetAbility():AutoShoot()
end





LinkLuaModifier("modifier_harpy_shot_thinker", "abilities/creep_shots", LUA_MODIFIER_MOTION_NONE)

harpy_shot = class({})

function harpy_shot:GetIntrinsicModifierName()
	return "modifier_harpy_shot_thinker"
end

function harpy_shot:OnUpgrade()
	self.shot_range = 3000
	self.shot_speed = 900 + 100 * math.floor(0.2 * GameMode.round_info.round_number)
	self.shot_radius = 32
	self.shot_damage = 0.75 * GameMode.enemy_damage
end

function harpy_shot:AutoShoot()
	if (not IsServer()) then return end

	if GameMode.main_hero and (not GameMode.main_hero:IsNull()) and GameMode.main_hero:IsAlive() then
		self:Shoot(GameMode.main_hero:GetAbsOrigin())
		self:UseResources(true, true, true)
	end
end

function harpy_shot:Shoot(location)
	local attacker = self:GetCaster()
	attacker:StartGesture(ACT_DOTA_ATTACK)

	attacker:EmitSound("Harpy.Attack")

	local shot_direction = (location - attacker:GetAbsOrigin()):Normalized()
	attacker:SetForwardVector(shot_direction)
	shot_direction = Vector(shot_direction.x, shot_direction.y, 0)

	local shot_origin = attacker:GetAbsOrigin()
	shot_origin = Vector(shot_origin.x, shot_origin.y, 300)

	local shot_projectile = {
		Ability				=	self,
		EffectName			=	"particles/harpy_shot.vpcf",
		vSpawnOrigin		=	shot_origin,
		fDistance			=	self.shot_range,
		fStartRadius		=	self.shot_radius,
		fEndRadius			=	self.shot_radius,
		Source				=	attacker,
		bHasFrontalCone		=	false,
		bReplaceExisting	=	false,
		iUnitTargetTeam		=	DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	=	DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType		=	DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime 		=	GameRules:GetGameTime() + 10,
		bDeleteOnHit		=	true,
		vVelocity			=	shot_direction * self.shot_speed,
		bProvidesVision		=	false
	}

	ProjectileManager:CreateLinearProjectile(shot_projectile)
end

function harpy_shot:OnProjectileHit(target, location)
	if IsServer() and target then
		target:EmitSound("Harpy.Hit")
		ApplyDamage({victim = target, attacker = self:GetCaster(), damage = self.shot_damage, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NONE, ability = self})
	end
	return true
end



modifier_harpy_shot_thinker = class({})

function modifier_harpy_shot_thinker:IsHidden() return true end
function modifier_harpy_shot_thinker:IsDebuff() return false end
function modifier_harpy_shot_thinker:IsPurgable() return false end
function modifier_harpy_shot_thinker:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_harpy_shot_thinker:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true
	}
end

function modifier_harpy_shot_thinker:OnCreated(keys)
	if IsServer() then
		self:StartIntervalThink(2.0)
	end
end

function modifier_harpy_shot_thinker:OnIntervalThink()
	self:GetAbility():AutoShoot()
end