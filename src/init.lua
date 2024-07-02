--!native
--!optimize 2

type IPair<Key = any, Value = any> = {
	Key: Key;
	Value: Value;
};

type BaseIter<Item = any> = {
	Next: () -> (Item?)
};

type IterImpl = {
	--// Map
	Map: <Item, NewItem>(
		self: IterImpl,
		Mapper: (Item) -> (NewItem)
	) -> (BaseIter<NewItem> & IterImpl);
	
	--// Filter
	Filter: <Item>(
		self: IterImpl,
		Filter: (Item) -> (boolean?)
	) -> (IterImpl);
	
	--// Take
	Take: <Item>(
		self: IterImpl,
		Count: number?
	) -> (IterImpl);
	
	--// Zip
	Zip: <Key, Value>(
		self: BaseIter<Key> & IterImpl,
		rhs: BaseIter<Value> & IterImpl
	) -> (BaseIter<IPair<Key, Value>> & IterImpl);
	
	--// Enumerate
	Enumerate: <Item>(
		self: IterImpl
	) -> (BaseIter<IPair<number, Item>> & IterImpl);
	
	--// Iterator Consumers
	
	--// Any
	Any: <Item>(
		self: IterImpl,
		Callback: (Item) -> (boolean?)
	) -> (boolean?);
	
	--// All
	All: <Item>(
		self: IterImpl,
		Callback: (Item) -> (boolean?)
	) -> (boolean?);
	
	--// Find
	Find: <Item>(
		self: IterImpl,
		Filter: (Item) -> (boolean?)
	) -> ({Item});
	
	--// ForEach
	ForEach: <Item>(
		self: IterImpl,
		Callback: (Item) -> ()
	) -> ();
	
	--// Count
	Count: <Item>(
		self: IterImpl
	) -> (number);
	
	--// Position
	Position: <Item>(
		self: IterImpl,
		Callback: (Item) -> (boolean?)
	) -> ({number?});
	
	--// Collect
	Collect: <Item>(
		self: IterImpl
	) -> ({Item});
	
	--// Unzip
	Unzip: <Key, Value>(
		self: BaseIter<IPair<Key, Value>> & IterImpl
	) -> ({Key}, {Value});
};

type Iter<Item = any> = BaseIter<Item> & IterImpl;

type IterClass = {
	new: <Item>(Next: () -> (Item?)) -> Iter<Item>;
	Iota: (Start: number?, Step: number?) -> (Iter<number>);
	Keys: <Key, Value>(Iterable: { [Key]: Value }) -> (Iter<Key>);
	Values: <Key, Value>(Iterable: { [Key]: Value }) -> (Iter<Value>);
};

local Iterator = ({});
Iterator.__index = Iterator;

Iterator.prototype = ({});
Iterator.prototype.__index = Iterator.prototype;

function Iterator.prototype:__len(): ()
    return (self:Count());
end;

--[[
    Returns a new `Iter` object consisting of mapped `Item`s by a mapping function.
    ```lua
    local Details = {
        [1] = "Name";
        [2] = "Age";
    };
    local Iter = Iterator.Keys(Details); --// Iter<number>
    local Mapper = function(Item)
        return (tostring(Item))
    end;

    local Mapped = Iter:Map(Mapper) --// Iter<string>
    ```
]]
function Iterator.prototype.Map<Item, NewItem>(self: Iter<Item>, Mapper: (Item) -> (NewItem)): (Iter<NewItem>)
	return (Iterator.new(function(): ()
		local Item = self.Next();
		return (Mapper(Item));
	end));
end;

--[[
    Returns a new `Iter` object consisting of `Item`s whose `Callback` function returned `true`
    ```lua
    local IsEven = function(x) return (x % 2 == 0) end;
    local Filtered = Iter:Filter(IsEven); --// Returns only even numbers
    ```
]]
function Iterator.prototype.Filter<Item>(self: Iter<Item>, Filter: (Item) -> (boolean?)): (Iter<Item>)
	return (Iterator.new(function(): ()
		for Item in self.Next do
			if (Filter(Item)) then
				return (Item);
			end;
		end;
		return;
	end));
end;

--[[
    Returns a new `Iter` object consisting of `n` `Item`s from the start.
    ```lua
    Iter:Take(5); --// 5 items from the start
    ```
]]
function Iterator.prototype.Take<Item>(self: Iter<Item>, Count: number): (Iter<Item>)
	return (Iterator.new(function(): ()
		if (not Count) then
			return;
		end;
		Count -= 1;
		return (self.Next());
	end));
end;

--[[
    Returns a new `Iter` object consisting of `IPair`s (Key-Value pair).
    ```lua
    -- Key = Iter<Item>
    -- Value = AnotherIter<Item>
    local Zipped = Iter:Zip(AnotherIter) --// Iter<IPair<Key, Value>>
    ```
]]
function Iterator.prototype.Zip<Key, Value>(self: Iter<Key>, rhs: Iter<Value>): (Iter<IPair<Key, Value>>)
	return (Iterator.new(function(): ()
		local Key: Key?, Value: Value?;
		Key = self.Next();
		Value = rhs.Next();
		if (not Key) or (not Value) then
			return;
		end;
		return ({
			Key = Key;
			Value = Value;
		});
	end));
end;

--[[
    Returns an `Iter` object of `IPair`s with the index as the key, and the `Item` as the value.
    ```lua
    local Iter = Iterator.Keys({
        Name = "GalladeR475";
        Age = 17;
    });
    local Enumerated = Iter:Enumerate(); --// { Key = 1, Value = "Name" }, { Key = 2, Value = "Age" }
    ```
]]
function Iterator.prototype.Enumerate<Item>(self: Iter<Item>): (Iter<IPair<number, Item>>)
	return (Iterator.Iota():Zip(self));
end;

--[[
    Calls a function `Callback` for each `Item` in the Iterator.
    ```lua
    local Iter = Iterator.Keys({
        Name = "GalladeR475";
        Age = 17;
    });
    Iter:ForEach(print); --// prints "Name" and "Age"
    ```
]]
function Iterator.prototype.ForEach<Item>(self: BaseIter<Item> & IterImpl, Callback: (Item) -> ())
	for Item in self.Next do
		Callback(Item);
	end;
end;

--[[
    Returns true if the `Callback` function of ANY `Item` in the Iterator returns `true`.
    ```lua
    local Iter = Iterator.Iota(); --// Iter<number>
    Iter:Any(IsEven); --// returns `true`
    ```
]]
function Iterator.prototype.Any<Item>(self: BaseIter<Item> & IterImpl, Callback: (Item) -> ()): (boolean?)
	for Item in self.Next do
		if (Callback(Item)) then
			return (true);
		end;
	end;
	return;
end;

--[[
    Returns true if the `Callback` function of ALL `Item`s in the Iterator returns `true`, else returns `false`.
    ```lua
    local Iter = Iterator.Iota(); --// Iter<number>
    Iter:All(IsEven); --// returns `false` as all number values are not even
    ```
]]
function Iterator.prototype.All<Item>(self: BaseIter<Item> & IterImpl, Callback: (Item) -> ()): (boolean?)
	for Item in self.Next do
		if (not Callback(Item)) then
			return (false);
		end;
	end;
	return;
end;

--[[
    Returns a list of `Item`s in the `Iter` object whose `Callback` function returned `true`, else `false`.
    ```lua
    local Iter = Iterator.Iota(); --// Iter<number>
    local ExtractedItems = Iter:Find(IsEven) --// returns a list of even numbers
    ```
]]
function Iterator.prototype.Find<Item>(self: Iter<Item>, Callback: (Item) -> ()): ({Item?})
    local FoundItems = ({});
    for Item in self.Next do
        if (Callback(Item)) then
            FoundItems[#FoundItems + 1] = Item;
        end;
    end;
    return (FoundItems);
end;

--[[
    Returns the count (length) of the `Iter` object.
]]
function Iterator.prototype.Count<Item>(self: Iter<Item>): (number)
    local Count = 0;
    for Item in self.Next do
        Count += 1;
    end;
    return (Count);
end;

--[[
    Returns a list of indices of `Item`s in the `Iter` object whose `Callback` function returned `true`, else `false`.
    ```lua
    local Iter = Iterator.Iota(); --// Iter<number>
    local ExtractedItems = Iter:Position(IsEven) --// returns a list of positions of even numbers
    ```
]]
function Iterator.prototype.Position<Item>(self: Iter<Item>, Callback: (Item) -> (boolean?)): ({number?})
    local FoundPositions = ({});
    local CurrentPosition = 0;
    for Item in self.Next do
        CurrentPosition += 1;
        if (Callback(Item)) then
            FoundPositions[#FoundPositions + 1] = CurrentPosition;
        end;
    end;
    return (FoundPositions);
end;

--[[
    Returns a list of all `Item`s in the `Iter` object.
    ```lua
    local Iter = Iterator.Keys({
        Name = "GalladeR475";
        Age = 17;
    });
    local Collected = Iter:Collect(); --// { "Name", "Age" }
    ```
]]
function Iterator.prototype.Collect<Item>(self: Iter<Item>): ({Item})
    local Collected = ({});
    for Item in self.Next do
        Collected[#Collected + 1] = Item;
    end;
    return (Collected);
end;

--[[
    Returns a list of `Keys` and a list of `Values` from an `IPair`
    ```lua
    -- Key = Iter<Item>
    -- Value = AnotherIter<Item>
    local Zipped = Iter:Zip(AnotherIter) --// Iter<IPair<Key, Value>>
	local Keys, Values = Zipped:Unzip(); --// {Key}, {Value}
    ```
]]
function Iterator.prototype.Unzip<Key, Value>(self: Iter<IPair<Key, Value>>): ({Key}, {Value})
    local First, Second = ({}), ({});
    for IPair: IPair<Key, Value> in self.Next do
        First[#First + 1] = IPair.First;
        Second[#Second + 1] = IPair.Second;
    end;
    return (First), (Second);
end;

--[[
    Creates a new `Iter` object.

    ```lua
    local Iter = Iterator.new(NextFunction);
    ```
]]
function Iterator.new<Item>(Next: () -> (Item?)): (Iter<Item> & any)
	local self = setmetatable({
		Next = Next;
	}, Iterator.prototype);
	return (self :: Iter<Item> & any);
end;

--[[
    Creates a new `Iter` object with sequential number values.

    ```lua
    Iterator.Iota(Start: number? or 0, Step: number? or 1);
    ```
]]
function Iterator.Iota(Start: number?, Step: number?): (Iter<number>) 
	local Count = Start or 0;
	return (Iterator.new(function(): ()
		Count += Step or 1;
		return (Count);
	end));
end;

--[[
    Creates a new `Iter` object from the `Keys` of the given iterable.

    ```lua
    local Details = {
        ["Name"] = "GalladeR475";
        ["Age"] = 17;
    }
    Iterator.Keys(Details); --// Iter<string>
    ```
]]
function Iterator.Keys<Key, Value>(Iterable: { [Key]: Value }): (Iter<Key>)
	local Key: Key?, Value: Value;
	return Iterator.new(function(): ()
		Key, _ = next(Iterable, Key);
		return (Key);
	end);
end;

--[[
    Creates a new `Iter` object from the `Values` of the given iterable.

    ```lua
    local Details = {
        ["Name"] = "GalladeR475";
        ["Age"] = 17;
    }
    Iterator.Keys(Details); --// Iter<string|number>
    ```
]]
function Iterator.Values<Key, Value>(Iterable: { [Key]: Value }): (Iter<Value>)
	local Key: Key?, Value: Value;
	return Iterator.new(function(): ()
		Key, Value = next(Iterable, Key);
		return (Value);
	end);
end;

return (Iterator :: IterClass);