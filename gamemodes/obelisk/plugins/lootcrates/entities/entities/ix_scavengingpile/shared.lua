ENT.Type = "anim";
ENT.PrintName = "Loot Object";
ENT.Category = "Helix";
ENT.Spawnable = true;
ENT.AdminOnly = true;
ENT.PhysgunDisable = false;
ENT.bNoPersist = true;

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "DisplayName" );
	self:NetworkVar( "String", 1, "DisplayDescription" );
end