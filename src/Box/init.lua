export type Box<T> = {
    IsOk: (self: Box<T>) -> (boolean?);
    IsErr: (self: Box<T>) -> (boolean?);
    Unwrap: (self: Box<T>) -> (T?);
    Value: T;
};

local Box = ({});
Box.__index = Box;

Box.prototype = ({});
function Box.prototype:__index(key: any): (unknown)
    return rawget(self, key) or rawget(Box.prototype, key);
end;
function Box.prototype:__newindex(key: any, value: any): (unknown)
    if (key == "Value") then
        error("[Box] Attempted to set the value inside a Box directly. Use .Unwrap() on the box to get the value.");
    end;
end;

function Box.new<T>(Value: T): (Box<T>)
    local self = setmetatable({
        _value = Value;
    }, Box.prototype);
    return (self);
end;

function Box.prototype.IsErr<T>(self: Box<T>): (boolean?)
    if (not self._value) then
        return (true);
    end;
    return;
end;

function Box.prototype.IsOk<T>(self: Box<T>): (boolean?)
    if (self._value) then
        return (true);
    end;
    return;
end;

function Box.prototype.Unwrap<T>(self: Box<T>): (T)
    if (self:IsOk()) then
        return (self._value) :: T;
    end;
    error("[Box] Box.Unwrap(self) called on an err value.");
end;

return (Box);