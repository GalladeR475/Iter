--[[
    Iterator
        lazy iterators for Luau/Roblox
        Inspired by rustlang Iterators
    
    author: glaphyre (@GalladeR475)
]]

export type IPair<First, Second> = { First: First, Second: Second };

type BaseIterator<Item> = {
    next: () -> (Item?);
};

export type Iterator<Item> = BaseIterator<Item> & {
    --// Iteration Methods
    Map: <Item, NewItem>(self: Iterator<Item>, Callback: (Item) -> (NewItem)) -> (Iterator<NewItem>);
    Filter: <Item>(self: Iterator<Item>, Callback: (Item) -> (boolean)) -> (Iterator<Item>);
    Take: <Item>(self: Iterator<Item>, Count: number) -> (Iterator<Item>);
    Zip: <First, Second>(self: Iterator<First>, rhs: Iterator<Second>) -> (Iterator<IPair<First, Second>>);

    --// Iterator Consumers
    Any: <Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)) -> (boolean?);
    All: <Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)) -> (boolean?);
    Count: <Item>(self: Iterator<Item>) -> (number);
    ForEach: <Item>(self: Iterator<Item>, Callback: (Item) -> ()) -> ();
    Find: <Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)) -> ({Item?});
    Position: <Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)) -> ({number?});
    Collect: <Item>(self: Iterator<Item>) -> ({Item});
    Fold: <Item, Accumulator>(self: Iterator<Item>, Callback: (Accumulator, Item) -> (Accumulator), InitialAccumulator: Accumulator) -> (Accumulator);
    Reduce: <Item>(self: Iterator<Item>, Callback: (Item, Item) -> (Item)) -> (Item?);
    Unzip: <First, Second>(self: Iterator<IPair<First, Second>>) -> ({First}, {Second});
};

type IteratorClass = {
    new: <Item>(Next: () -> (Item?)) -> (Iterator<Item>);
    Keys: <Key, Value>(keyValue: { [Key]: Value }) -> (Iterator<Key>);
    Values: <Key, Value>(keyValue: { [Key]: Value }) -> (Iterator<Value>);
}

local Iterator = ({});
Iterator.__index = Iterator;

Iterator.prototype = ({});
function Iterator.prototype:__index(key: any): (any)
	return (rawget(self, key)) or (rawget(Iterator, key));
end;

--// Iterator Class
--// Responsible for creating new iterators

--[[
    Creates a new Iterator Object
    @param Next iterator next
]]
function Iterator.new<Item>(Next: () -> (Item?)): (Iterator<Item>)
    local self = setmetatable({
        next = Next;
    }, Iterator.prototype);
    return (self :: Iterator<Item>);
end;

--[[
    Creates a new iterator of only keys of a key-value pair.
    @param keyValue the key-value pair
]]
function Iterator.Keys<Key, Value>(keyValue: { [Key]: Value }): (Iterator<Key>)
    return (Iterator.new(function(): ()
        local Key: Key?;
        Key = next(keyValue, Key);
        return (Key);
    end));
end;

--[[
    Creates a new iterator of only values of a key-value pair.
    @param keyValue the key-value pair
]]
function Iterator.Values<Key, Value>(keyValue: { [Key]: Value }): (Iterator<Value>)
    return (Iterator.new(function(): ()
        local Key: Key?, Value: Value?;
        Key, Value = next(keyValue, Key);
        return (Value);
    end));
end;

--// Iterator Definitions
--// Iteration Methods
function Iterator.prototype.Map<Item, NewItem>(self: Iterator<Item>, Callback: (Item) -> (NewItem?)): (Iterator<NewItem>)
    return (Iterator.new(function(): ()
        local Item = self.next();
        return (Callback(Item));
    end));
end;

function Iterator.prototype.Filter<Item>(self:Iterator<Item>, Callback: (Item) -> (boolean?)): (Iterator<Item>)
    return (Iterator.new(function(): ()
        for Item in self.next do
            if (Callback(Item)) then
                return (Item);
            end;
        end;
        return;
    end));
end;

function Iterator.prototype.Take<Item>(self: Iterator<Item>, Count: number): (Iterator<Item>)
    return (Iterator.new(function(): ()
        if (not Count) then
            return;
        end;
        Count -= 1;
        return (self.next());
    end));
end;

function Iterator.prototype.Zip<First, Second>(self: Iterator<First>, rhs: Iterator<Second>): (Iterator<IPair<First, Second>>)
    return (Iterator.new(function(): ()
        local First: First?, Second: Second?;
        First = self.next;
        Second = rhs.next;
        if (not First) or (not Second) then
            return;
        end;
        return ({
            First = First;
            Second = Second;
        });
    end));
end;

--// Iterator Consumer Methods
function Iterator.prototype.ForEach<Item>(self: Iterator<Item>, Callback: (Item) -> ()): ()
    for Item in (self.next) do
        Callback(Item);
    end;
end;

function Iterator.prototype.Find<Item>(self: Iterator<Item>, Callback: () -> ()): ({Item?})
    local FoundItems = ({});
    for Item in self.next do
        if (Callback(Item)) then
            FoundItems[#FoundItems + 1] = Item;
        end;
    end;
    return (FoundItems);
end;

function Iterator.prototype.Any<Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)): (boolean?)
    for Item in (self.next) do
        if (Callback(Item)) then
            return (true);
        end;
    end;
    return;
end;

function Iterator.prototype.All<Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)): (boolean?)
    for Item in (self.next) do
        if (not Callback(Item)) then
            return (false);
        end;
    end;
    return;
end;

function Iterator.prototype.Count<Item>(self: Iterator<Item>): (number)
    local Count = 0;
    for Item in self.next do
        Count += 1;
    end;
    return (Count);
end;

function Iterator.prototype.Position<Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)): ({number?})
    local FoundPositions = ({});
    local CurrentPosition = 1;
    for Item in self.next do
        if (Callback(Item)) then
            FoundPositions[#FoundPositions + 1] = CurrentPosition;
        end;
        CurrentPosition += 1;
    end;
    return (FoundPositions);
end;

function Iterator.prototype.Collect<Item>(self: Iterator<Item>): ({Item})
    local Collected = ({});
    for Item in self.next do
        Collected[#Collected + 1] = Item;
    end;
    return (Collected);
end;

function Iterator.prototype.Fold<Item, Accumulator>(self: Iterator<Item>, Callback: (Accumulator, Item) -> (Accumulator), InitialAccumulator: Accumulator): (Accumulator)
    local Accumulator = InitialAccumulator;
    for Item in self.next do
        Accumulator = Callback(Accumulator, Item);
    end;
    return (Accumulator);
end;

function Iterator.prototype.Reduce<Item>(self: Iterator<Item>, Callback: (Item, Item) -> (Item)): (Item?)
    local InitialAccumulator = self.next();
    if (not InitialAccumulator) then
        return;
    end;
    return (self:Fold(Callback, InitialAccumulator));
end;

function Iterator.prototype.Unzip<First, Second>(self: Iterator<IPair<First, Second>>): ({First}, {Second})
    local First, Second = ({}), ({});
    for IPair: IPair<First, Second> in self.next do
        First[#First + 1] = IPair.First;
        Second[#Second + 1] = IPair.Second;
    end;
    return (First), (Second);
end;

return (Iterator :: IteratorClass);