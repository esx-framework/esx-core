local Point = ESX.Class()

local points, nearbyPoints, mainThread, nearbyThread = {}, {}, false, false

local function UnloadPoint(handle, point)
    nearbyPoints[handle] = nil
    if point.leave then
        point:leave()
    end
    if #nearbyPoints == 0 then
        nearbyThread = false
    end
end

function Point:constructor(properties)
    self.coords = properties.coords
    self.distance = properties.distance
    self.hidden = properties.hidden
    self.enter = properties.enter
    self.leave = properties.leave
    self.inside = properties.inside
    self.handle = table.sizeOf(points) + 1
    points[self.handle] = self
    if not mainThread then
        mainThread = true
        CreateThread(function()
            while mainThread do Wait(500)
                local coords = PlayerObject:GetCoords()
                for handle, point in pairs(points) do
                    if not point.hidden and #(coords - point.coords) <= point.distance then
                        if not nearbyPoints[handle] then
                            nearbyPoints[handle] = point
                            if point.enter then
                                point:enter()
                            end
                            if not nearbyThread then
                                nearbyThread = true
                                CreateThread(function()
                                    while nearbyThread do Wait()
                                        coords = PlayerObject:GetCoords()
                                        for handle, point in pairs(nearbyPoints) do
                                            if point.inside then
                                                point:inside(#(coords - point.coords))
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    elseif nearbyPoints[handle] then
                        UnloadPoint(handle, point)
                    end
                end
            end
        end)
    end
end

function Point:delete()
    points[self.handle] = nil
    if #points == 0 then
        mainThread = false
    end
    if nearbyPoints[self.handle] then
        UnloadPoint(self.handle, self)
    end
end

function Point:toggle(hidden)
    if hidden == nil then
        hidden = not self.hidden
    end
    self.hidden = hidden 
end

return Point
