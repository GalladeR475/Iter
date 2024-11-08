--!native
--!optimize 2

local _MAX_IOTA_ITERATION_COUNT = 9999

--[=[
    Blazingly-fast lazy iterator module for luau

    author: GalladeR475
]=]

--// Iterator: table containing all methods for iteration
local Iterator = {}
Iterator.__index = Iterator
Iterator.__tostring = function() 
    return "Iterator"
end

local Iter = {}
Iter.__index = Iter

--//----------------------------------------------------------------------------------//--
--                                       Types                                          --
--//----------------------------------------------------------------------------------//--

type Iterable<Key, Value> = { [Key]: Value }
type Pair<Key, Value> = { Key: Key, Value: Value }

export type Iter<Item> = typeof(setmetatable(
    {} :: { Next: () -> Item? },
    {} :: typeof(Iterator)
))

--//----------------------------------------------------------------------------------//--
--                               Function Definitions                                   --
--//----------------------------------------------------------------------------------//--

type Map =
	& (<Item1, Item2>(self: Iter<Item1>, Mapper: (Item1) -> Item2) -> Iter<Item2>)
	& (<Item1, Item2>(self: Iter<Item1>, Mapper: (Item1, ...any) -> Item2, ...any) -> Iter<Item2>)

--[=[
    Returns a new `Iter` object consisting of mapped `Item`s by a mapping function.
    ```lua
    local Details = {
        [1] = "Name",
        [2] = "Age",
    } 
    local Iter = Iterator.Keys(Details)  --// Iter<number>
    local Mapper = function(Item)
        return (tostring(Item)) --// converts it to a string
    end 

    local Mapped = Iter:Map(Mapper) --// Iter<string>
    ```
]=]
Iterator.Map = function<Item1, Item2>(self: Iter<Item1>, Mapper: (Item1, ...any?) -> Item2, ...: any?): Iter<Item2>
	local args = { ... }

	return Iter.new(function(): ()
		local Item = self.Next()
		return (Mapper(Item, table.unpack(args)))
	end)
end :: Map

--//----------------------------------------------------------------------------------//--

type Filter =
	& (<Item>(self: Iter<Item>, Filterer: (Item) -> boolean) -> Iter<Item>)
	& (<Item>(self: Iter<Item>, Filterer: (Item, ...any) -> boolean, ...any) -> Iter<Item>)

--[=[
    Returns a new `Iter` object consisting of `Item`s whose `Filterer` function returned `true`
    ```lua
    local IsEven = function(x) return (x % 2 == 0) end 
    local Filtered = Iter:Filter(IsEven)  --// Returns only even numbers
    ```
]=]
Iterator.Filter = function<Item>(self: Iter<Item>, Filterer: (Item, ...any) -> boolean, ...: any?): Iter<Item>
	local args = { ... }

	return (
		Iter.new(function(): ()
			for Item in self.Next do
				if Filterer(Item, table.unpack(args)) then
					return Item
				end
			end
			return
		end)
	)
end :: Filter

--//----------------------------------------------------------------------------------//--

type Take = <Item>(self: Iter<Item>, Count: number) -> Iter<Item>

--[=[
    Returns a new `Iter` object consisting of `n` `Item`s from the start.
    ```lua
    Iter:Take(5) --// 5 items from the start
    ```
]=]
Iterator.Take = function<Item>(self: Iter<Item>, Count: number): Iter<Item>
	return Iter.new(function(): ()
		if not Count then
			return
		end
		Count -= 1
		return (self.Next())
	end)
end :: Take

--//----------------------------------------------------------------------------------//--

type Zip = <Key, Value>(self: Iter<Key>, Operand: Iter<Value>) -> Iter<Pair<Key, Value>>

--[=[
    Returns a new `Iter` object consisting of `Pair`s (Key-Value pair).
    ```lua
    -- Key = Iter<Item>
    -- Value = AnotherIter<Item>
    local Zipped = Iter:Zip(AnotherIter) --// Iter<IPair<Key, Value>>
    ```
]=]
Iterator.Zip = function<Key, Value>(self: Iter<Key>, Operand: Iter<Value>): Iter<Pair<Key, Value>>
	return Iter.new(function(): ()
		local Key: Key?, Value: Value?
		Key = self.Next()
		Value = Operand.Next()

		if (not Key) or not Value then
			return
		end

		return {
			Key = Key,
			Value = Value,
		}
	end)
end :: Zip

--//----------------------------------------------------------------------------------//--

type Enumerate = <Item>(self: Iter<Item>) -> Iter<Pair<number, Item>>

--[=[
    Returns an `Iter` object of `Pair`s with the index as the key, and the `Item` as the value.
    @return Iter<Pair<number, Item>>
    
    ```lua
    local Iter = Iterator.Keys({
        Name = "GalladeR475" 
        Age = 17 
    }) 
    local Enumerated = Iter:Enumerate()  --// { Key = 1, Value = "Name" }, { Key = 2, Value = "Age" }
    ```
]=]
Iterator.Enumerate = function<Item>(self: Iter<Item>): Iter<Pair<number, Item>>
	return (Iter.Iota():Zip(self))
end :: Enumerate

--//----------------------------------------------------------------------------------//--

type ForEach =
	& (<Item>(self: Iter<Item>, Callback: (Item) -> ()) -> ())
	& (<Item>(self: Iter<Item>, Callback: (Item, ...any) -> (), ...any) -> ())

--[=[
    Calls a function `Callback` for each `Item` in the Iterator.
    ```lua
    local Iter = Iterator.Keys({
        Name = "GalladeR475",
        Age = 17,
    }) 
    Iter:ForEach(print) --// prints "Name" and "Age"
    ```
]=]
Iterator.ForEach = function<Item>(self: Iter<Item>, Callback: (Item, ...any) -> (), ...: any?): ()
	for Item in self.Next do
		Callback(Item, ...)
	end
end :: ForEach

--//----------------------------------------------------------------------------------//--

type Any =
	& (<Item>(self: Iter<Item>, Callback: (Item) -> boolean) -> boolean)
	& (<Item>(self: Iter<Item>, Callback: (Item, ...any) -> boolean, ...any) -> boolean)

--[=[
    Returns true if the `Callback` function of **ANY** `Item` in the Iterator returns `true`.
    @param Callback Function to be called on every item.
    @param ... any values to be passed into the callback. 
    @return boolean

    ```lua
    local Iter = Iterator.Iota() --// Iter<number>
    Iter:Any(IsEven) --// returns `true`
    ```
]=]
Iterator.Any = function<Item>(self: Iter<Item>, Callback: (Item, ...any) -> (), ...: any?): boolean
	for Item in self.Next do
		if Callback(Item, ...) then
			return true
		end
	end
	return false
end :: Any

--//----------------------------------------------------------------------------------//--

type All =
	& (<Item>(self: Iter<Item>, Callback: (Item) -> boolean) -> boolean)
	& (<Item>(self: Iter<Item>, Callback: (Item, ...any) -> boolean, ...any) -> boolean)

--[=[
    Returns true if the `Callback` function of **ALL** `Item`s in the Iterator returns `true`, else returns `false`.
    @param Callback Function to be called on every item.
    @param ... any values to be passed into the callback. 
    @return boolean

    ```lua
    local Iter = Iterator.Iota() --// Iter<number>
    Iter:All(IsEven) --// returns `false` as all number values are not even
    ```
]=]
Iterator.All = function<Item>(self: Iter<Item>, Callback: (Item, ...any) -> (), ...: any?): boolean
	for Item in self.Next do
		if not Callback(Item, ...) then
			return false
		end
	end
	return true
end :: All

--//----------------------------------------------------------------------------------//--

type Find =
	& (<Item>(self: Iter<Item>, Finder: (Item) -> boolean) -> { Item? })
	& (<Item>(self: Iter<Item>, Finder: (Item, ...any) -> boolean, ...any) -> { Item? })

--[=[
    Returns a list of `Item`s in the `Iter` object whose `Finder` function returned `true`.
    @param Finder Sorting function to be called on every item.
    @param ... any values to be passed into the callback. 
    @return {number}

    ```lua
    local Iter = Iterator.Iota() --// Iter<number>
    local ExtractedItems = Iter:Find(IsEven) --// returns a list of even numbers
    ```
]=]
Iterator.Find = function<Item>(self: Iter<Item>, Finder: (Item, ...any?) -> (), ...: any?): { Item? }
	local FoundItems = {}
	local Index = 1
	for Item in self.Next do
		if Finder(Item, ...) then
			FoundItems[Index] = Item
		end
	    Index += 1
	end
	return FoundItems
end :: Find

--//----------------------------------------------------------------------------------//--

type Position =
	& (<Item>(self: Iter<Item>, Finder: (Item) -> boolean) -> { number? })
	& (<Item>(self: Iter<Item>, Finder: (Item, ...any) -> boolean, ...any) -> { number? })

--[=[
    Returns a list of indices of `Item`s in the `Iter` object whose `Callback` function returned `true`, else `false`.
    @param Callback Function to be called on every item.
    @param ... any values to be passed into the callback. 
    @return {number}

    ```lua
    local Iter = Iterator.Iota() --// Iter<number>
    local ExtractedItems = Iter:Position(IsEven) --// returns a list of positions of even numbers
    ```
]=]
Iterator.Position = function<Item>(self: Iter<Item>, Callback: (Item, ...any) -> boolean?, ...: any?): { number? }
	local FoundPositions = {}
	local Index = 1
	for Item in self.Next do
		if Callback(Item, ...) then
			FoundPositions[#FoundPositions + 1] = Index
		end
		Index += 1
	end
	return FoundPositions
end :: Position

--//----------------------------------------------------------------------------------//--

type Collect = <Item>(self: Iter<Item>) -> { Item }

--[=[
    Returns a list of all `Item`s in the `Iter` object.
    ```lua
    local Iter = Iterator.Keys({
        Name = "GalladeR475",
        Age = 17,
    }) 
    local Collected = Iter:Collect() --// { "Name", "Age" }
    ```
]=]
Iterator.Collect = function<Item>(self: Iter<Item>): { Item? }
	local Collected = {}
	for Item in self.Next do
		Collected[#Collected + 1] = Item
	end
	return Collected
end :: Collect

--//----------------------------------------------------------------------------------//--

type Unzip = <Key, Value>(self: Iter<Pair<Key, Value>>) -> ({ Key }, { Value })

--[=[
    Returns a list of `Keys` and a list of `Values` from an `IPair`
    ```lua
    -- Key = Iter<Item>
    -- Value = Iter<AnotherItem>
    local Zipped = Iter:Zip(AnotherIter) --// Iter<IPair<Key, Value>>
	local Keys, Values = Zipped:Unzip() --// {Key}, {Value}
    ```
    @return Iter
]=]
Iterator.Unzip = function<Key, Value>(self: Iter<Pair<Key, Value>>): ({ Key }, { Value })
	local Keys, Values = {}, {}
	for Pair: Pair<Key, Value> in self.Next do
		Keys[#Keys + 1] = Pair.Key
		Values[#Values + 1] = Pair.Value
	end
	return Keys, Values
end :: Unzip

--//----------------------------------------------------------------------------------//--

type Drain = <Item>(self: Iter<Item>) -> ()

--[=[
    Drains the `Iter` completely, making it unusable.
]=]
Iterator.Drain = function<Item>(self: Iter<Item>): ()
    for _ in self.Next do
    end
end :: Drain

--//----------------------------------------------------------------------------------//--

type Fold = <Item, Accumulator>(self: Iter<Item>, Folder: (Accumulator: Accumulator, NextItem: Item) -> Accumulator, Initial: Accumulator) -> Accumulator

--[=[
    Applies a `Folder` function to each element of the `Iter`, accumulating the result into a new value
    @param Folder Folding function
    @param Initial Initial Value of the accumulation
]=]
Iterator.Fold = function<Item, Accumulator>(self: Iter<Item>, Folder: (Accumulator, Item) -> Accumulator, Initial: Accumulator): Accumulator
    local Accumulator = Initial
    for Item in self.Next do
        Accumulator = Folder(Accumulator, Item)
    end
    return Accumulator
end :: Fold

--//----------------------------------------------------------------------------------//--

type Reduce = <Item>(self: Iter<Item>, Reducer: (Item, Item) -> Item) -> Item?

--[=[
    Reduces all the `Item`s in the `Iter` into a single value.
    @param Reducer Reducing function
    @param Initial Initial Value of the accumulation
]=]
Iterator.Reduce = function<Item>(self: Iter<Item>, Reducer: (Item, Item) -> Item): Item?
    local Initial = self.Next()
    if not Initial then
        return
    end
    return self:Fold(Reducer, Initial)
end :: Reduce

--//----------------------------------------------------------------------------------//--
--                                   Main Module                                        --
--//----------------------------------------------------------------------------------//--

--[=[
    Creates a new Iterator with a custom `Next` function.
    @param Next Iterator function
]=]
function Iter.new<Item>(Next: () -> Item?): Iter<Item>
	local self = setmetatable({
		Next = Next,
	}, Iterator)

	return self
end

--[=[
    Creates a new Iterator from the keys of a given iterable.
    @param Iterable Table or Dictionary
]=]
function Iter.Keys<Key, Value>(Iterable: Iterable<Key, Value>): Iter<Key>
	local Key: Key?, _: Value?

	return Iter.new(function(): Key?
		Key, _ = next(Iterable, Key)
		return Key
	end)
end

--[=[
    Creates a new Iterator from the values of a given iterable.
    @param Iterable Table or Dictionary
]=]
function Iter.Values<Key, Value>(Iterable: Iterable<Key, Value>): Iter<Value>
	local Key: Key?, Value: Value?

	return Iter.new(function(): Value?
		Key, Value = next(Iterable, Key)
		return Value
	end)
end

--[=[
    Creates a new Iterator of sequential numbers.
    @param Start Starting value of the iterator.
    @param Step Amount to be increased to the starting value every iteration.
    @return Iter
]=]
function Iter.Iota(Start: number?, Step: number?): Iter<number>
	local Count = Start or 0
	return (Iter.new(function(): number
		Count += Step or 1
		return Count
	end))
end

return Iter
