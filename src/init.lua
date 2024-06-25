--[[
    Iterator
        lazy iterators for Luau/Roblox
        Inspired by rustlang Iterators
    
    author: cgl4de (@GalladeR475)

    Documentation can be found in a comment above the desired function.
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
    Enumerate: <Item>(self: Iterator<Item>) -> (Iterator<IPair<number, Item>>);
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
    Reduce: <Item>(self: Iterator<Item>, Reducer: (Item, Item) -> (Item)) -> (Item?);
    Unzip: <First, Second>(self: Iterator<IPair<First, Second>>) -> ({First}, {Second});
};

--// Class for handling creation of iterators
type IteratorClass = {
    new: <Item>(Next: () -> (Item?)) -> (Iterator<Item>);
    Keys: <Key, Value>(keyValue: { [Key]: Value }) -> (Iterator<Key>);
    Values: <Key, Value>(keyValue: { [Key]: Value }) -> (Iterator<Value>);
    Iota: (Start: number, Step: number) -> Iterator<number>;
};

local Iterator = ({});
Iterator.__index = Iterator;

Iterator.prototype = ({});
function Iterator.prototype:__index(key: any): (any)
	return (rawget(self, key)) or (rawget(Iterator, key));
end;

--// Iterator Class
--// Responsible for the creation of new iterators
--[[
    Creates a new Iterator Object
    @param Next returns the next element of the iterator
]]
function Iterator.new<Item>(Next: () -> (Item?)): (Iterator<Item>)
    local self = setmetatable({
        next = Next;
    }, Iterator.prototype);
    return (self :: Iterator<Item>);
end;

--[[
    Creates a new iterator of only keys of a key-value pair (iterables)
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
    Creates a new iterator of only values of a key-value pair (iterables)
    @param keyValue the key-value pair
]]
function Iterator.Values<Key, Value>(keyValue: { [Key]: Value }): (Iterator<Value>)
    return (Iterator.new(function(): ()
        local Key: Key?, Value: Value?;
        Key, Value = next(keyValue, Key);
        return (Value);
    end));
end;

--[[
    Creates a new iterator of only successive values in a specified range (iterables)
    @param Start start index of the Iterator
    @param Step amount to be incremented
]]
function Iterator.Iota(Start: number, Step: number): (Iterator<number>)
    local Counter = Start;
    return (Iterator.new(function(): ()
        Counter += Step;
        return (Counter);
    end));
end;

--// Iterator Definitions
--// Iteration Methods

--[[
    Returns a new `Iterator` consisting of transformed `Item` by a mapping function.
    @param Callback Map
]]
function Iterator.prototype.Map<Item, NewItem>(self: Iterator<Item>, Map: (Item) -> (NewItem?)): (Iterator<NewItem>)
    return (Iterator.new(function(): ()
        local Item = self.next();
        return (Map(Item));
    end));
end;

--[[
    Returns an `Iterator` which consists of Items whose `Callback` function returns true.
    @param Callback function
]]
function Iterator.prototype.Filter<Item>(self:Iterator<Item>, Filter: (Item) -> (boolean?)): (Iterator<Item>)
    return (Iterator.new(function(): ()
        for Item in self.next do
            if (Filter(Item)) then
                return (Item);
            end;
        end;
        return;
    end));
end;

--[[
    Returns an `Iterator` consisting of `n` number of `Item`s from the start.
    @param Count number
]]
function Iterator.prototype.Take<Item>(self: Iterator<Item>, Count: number): (Iterator<Item>)
    return (Iterator.new(function(): ()
        if (not Count) then
            return;
        end;
        Count -= 1;
        return (self.next());
    end));
end;

--[[
    Returns an `Iterator` of `IPair`s with the index as the first, and the `Item` as the second parameter.
]]
function Iterator.prototype.Enumerate<Item>(self: Iterator<Item>): (Iterator<IPair<number, Item>>)
    return (Iterator.Iota(0, 1):Zip(self));
end;

--[[
    Returns an `Iterator` of `IPair`s from two iterators with two distinct types.
]]
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
--// Consumer methods are methods which no longer return an `Iterator`, terminating the chain.

--[[
    Calls a function `Iteration` for each `Item` in the `Iterator`.
    @param Iteration function
    @returns nil
]]
function Iterator.prototype.ForEach<Item>(self: Iterator<Item>, Iteration: (Item) -> ()): ()
    for Item in (self.next) do
        Iteration(Item);
    end;
end;

--[[
    Returns a list of `Item`s in the `Iterator` whose `Callback` function returned `true`.
    @param Callback function
]]
function Iterator.prototype.Find<Item>(self: Iterator<Item>, Callback: (Item) -> ()): ({Item?})
    local FoundItems = ({});
    for Item in self.next do
        if (Callback(Item)) then
            FoundItems[#FoundItems + 1] = Item;
        end;
    end;
    return (FoundItems);
end;

--[[
    Returns `true` if the `Callback` function of `ANY` item of the `Iterator` returns `true`, else `false`.
    @param Callback function
]]
function Iterator.prototype.Any<Item>(self: Iterator<Item>, Callback: (Item) -> (boolean?)): (boolean?)
    for Item in (self.next) do
        if (Callback(Item)) then
            return (true);
        end;
    end;
    return;
end;

--[[
    Returns `true` if the `Callback` function of `ALL` items of the `Iterator` returns `true`, else `false`.
    @param Callback function
]]
function Iterator.prototype.All<Item>(self: Iterator<Item>, Check: (Item) -> (boolean?)): (boolean?)
    for Item in (self.next) do
        if (not Check(Item)) then
            return (false);
        end;
    end;
    return;
end;

--[[
    Returns the length of the `Iterator`.
    @returns number
]]
function Iterator.prototype.Count<Item>(self: Iterator<Item>): (number)
    local Count = 0;
    for Item in self.next do
        Count += 1;
    end;
    return (Count);
end;

--[[
    Returns a list of indexes of the `Iterator` whose `Callback` function returns `true`.
    @param Callback function
]]
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

--[[
    Returns a list of all `Item`s of the `Iterator`.
    @returns table
]]
function Iterator.prototype.Collect<Item>(self: Iterator<Item>): ({Item})
    local Collected = ({});
    for Item in self.next do
        Collected[#Collected + 1] = Item;
    end;
    return (Collected);
end;

--[[
    Applies a callback function to each `Item` of an `Iterator` per iteration, accumulating into a new value.
    @param Callback function
]]
function Iterator.prototype.Fold<Item, Accumulator>(self: Iterator<Item>, Callback: (Accumulator, Item) -> (Accumulator), InitialAccumulator: Accumulator): (Accumulator)
    local Accumulator = InitialAccumulator;
    for Item in self.next do
        Accumulator = Callback(Accumulator, Item);
    end;
    return (Accumulator);
end;

--[[
    Executes a callback function on each `Item` of the `Iterator` and passes the return value from the calculation to the preceding `Item`.
    @param Reducer function
]]
function Iterator.prototype.Reduce<Item>(self: Iterator<Item>, Reducer: (Item, Item) -> (Item)): (Item?)
    local InitialAccumulator = self.next();
    if (not InitialAccumulator) then
        return;
    end;
    return (self:Fold(Reducer, InitialAccumulator));
end;

--[[
    Unzips the `Iterator` into two collections
]]
function Iterator.prototype.Unzip<First, Second>(self: Iterator<IPair<First, Second>>): ({First}, {Second})
    local First, Second = ({}), ({});
    for IPair: IPair<First, Second> in self.next do
        First[#First + 1] = IPair.First;
        Second[#Second + 1] = IPair.Second;
    end;
    return (First), (Second);
end;

return (Iterator :: IteratorClass);