-- Mamba_Comodidades: arranque. Guarda sus opciones en MambaComodidadesDB (por cuenta).
-- Licencia: GPL-3.0-only.
local _, M = ...

function M.DB()
	MambaComodidadesDB = type(MambaComodidadesDB) == "table" and MambaComodidadesDB or {}
	return MambaComodidadesDB
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
	for _, fn in ipairs({ M.Comodidades.Iniciar, M.Raros.Iniciar, M.Registrar }) do
		local ok, err = pcall(fn)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
end)
