local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if self.Name == "ForgeRF" then
        for i, arg in pairs(args) do
            if type(arg) == "table" and arg.Rating ~= nil then
                arg.Rating = 15
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)