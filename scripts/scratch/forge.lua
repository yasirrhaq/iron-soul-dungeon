local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Cek hanya berdasarkan nama Remote-nya saja
    if self.Name == "ForgeRF" then
        
        -- Log penanda untuk memastikan remote ini berhasil dicegat sistem
        print("⚡ [DEBUG] Mendeteksi ForgeRF terpanggil dengan method: " .. tostring(method))
        
        -- Looping untuk mencari tabel argumen yang berisi data 'Rating'
        for i, arg in pairs(args) do
            if type(arg) == "table" and arg.Rating ~= nil then
                arg.Rating = 15
                print("🎯 [SUCCESS] Berhasil memaksa Rating menjadi 15 pada argumen ke-" .. tostring(i))
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

print("🔥 Script Universal Perfect Forge Aktif! Silakan coba pukul besi.")