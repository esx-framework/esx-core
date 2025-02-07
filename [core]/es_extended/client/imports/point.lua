local Point = ESX.Class()

local nearby, loop = {}

function Point:constructor(properties)
	self.coords = properties.coords
	self.hidden = properties.hidden
	self.enter = properties.enter
	self.leave = properties.leave
	self.inside = properties.inside
	self.handle = ESX.CreatePointInternal(properties.coords, properties.distance, properties.hidden, function()
		nearby[self.handle] = self
		if self.enter then
			self:enter()
		end
		if not loop then
			loop = true
			CreateThread(function()
				while loop do
					local coords = GetEntityCoords(ESX.PlayerData.ped)
					for handle, point in pairs(nearby) do
						if point.inside then
							point:inside(#(coords - point.coords))
						end
					end
					Wait()
				end
			end)
		end
	end, function()
		nearby[self.handle] = nil
		if self.leave then
			self:leave()
		end
		if #nearby == 0 then
			loop = false
		end
	end)
end

function Point:delete()
    if not nearby[self.handle] then
        return
    end
    nearby[self.handle] = nil

    if self.leave then
        self:leave()
    end

    if next(nearby) == nil then
        loop = false
    end

    ESX.RemovePointInternal(self.handle)
end


function Point:toggle(hidden)
	if hidden == nil then
		hidden = not self.hidden
	end
	self.hidden = hidden
	ESX.HidePointInternal(self.handle, hidden)
end

return Point