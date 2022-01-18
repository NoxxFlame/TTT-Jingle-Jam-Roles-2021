AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Christmas Cannon"
    SWEP.Slot = 8
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.HoldType = "rpg"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Weight = 5

SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 5
SWEP.Primary.Recoil = 50
SWEP.Primary.Damage = 0
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.ClipMax = -1
SWEP.Primary.DefaultClip = -1

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.ViewModel = Model("models/weapons/v_rpg.mdl")
SWEP.WorldModel = Model("models/weapons/w_rocket_launcher.mdl")

SWEP.Kind = WEAPON_ROLE
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "none"
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = true

local ShootSound = Sound("weapons/grenade_launcher1.wav")

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    if CLIENT then
        self:AddHUDHelp("santa_help_pri", "santa_help_sec", true)
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local item_id = owner:GetNWString("SantaLoadedItem")
    local random_presents = GetGlobalBool("ttt_santa_random_presents", false)
    local has_ammo = owner:GetNWBool("SantaHasAmmo", false)

    if item_id ~= "" or (random_presents and has_ammo) then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:EmitSound(ShootSound)

        owner:SetNWString("SantaLoadedItem", "")
        owner:SetNWBool("SantaHasAmmo", false)

        if random_presents then
            -- TODO: Shoot random gift
        else
            -- TODO: Shoot bought gift
        end

        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(),  -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    else
        if has_ammo then
            owner:PrintMessage(HUD_PRINTTALK, LANG.GetParamTranslation("santa_load_gift", {menukey = Key("+menu_context", "C")}))
        end

        if CLIENT and LocalPlayer() == self:GetOwner() then
            self:EmitSound( "Weapon_Pistol.Empty" )
        end
    end
end

function SWEP:SecondaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local random_presents = GetGlobalBool("ttt_santa_random_presents", false)
    local has_ammo = owner:GetNWBool("SantaHasAmmo", false)

    if has_ammo then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:EmitSound(ShootSound)

        owner:SetNWBool("SantaHasAmmo", false)
        if not random_presents then
            owner:SetCredits(0)
        end

        -- TODO: Shoot coal

        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(),  -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    elseif CLIENT and LocalPlayer() == self:GetOwner() then
        self:EmitSound( "Weapon_Pistol.Empty" )
    end
end