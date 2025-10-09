
print("Auto-Workshop Force Download by Sammy started")
for i,addon in pairs(engine.GetAddons()) do
	print("Adding Workshop Addons:")
	if addon.mounted then
		resource.AddWorkshop( addon.wsid )
		print("\t[+]"..addon.wsid..": "..addon.title)
	end
end