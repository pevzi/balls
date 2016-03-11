--[[
A collection for storing ordered unique elements that allows to:
- access previous/next elements by specifying a value
- insert an element after another element specified by value
- remove an element or a range of elements specified by value
All operations are done with constant time.
]]

local Object = require "libs.class"

local Chain = Object:inherit()

function Chain:init()
    self.links = setmetatable({}, {__mode = "k"})
    self.head = nil
    self.tail = nil
end

function Chain:insert(item, prevItem)
    local prevLinks = self.links[prevItem]

    assert(prevItem == nil or prevLinks)
    assert(self.links[item] == nil)

    local itemLinks = {}
    local nextItem

    if prevItem then
        nextItem = prevLinks.next
        prevLinks.next = item
    else
        nextItem = self.head
        self.head = item
    end

    if nextItem then
        self.links[nextItem].prev = item
    else
        self.tail = item
    end

    itemLinks.next = nextItem
    itemLinks.prev = prevItem

    self.links[item] = itemLinks
end

function Chain:remove(item)
    return self:removeRange(item, item)
end

function Chain:removeRange(from, to)
    -- "from" must go before "to" or else this
    -- function will screw up everything

    local fromLinks = self.links[from]
    local toLinks = self.links[to]

    assert(fromLinks)
    assert(toLinks)

    if from == self.head then
        self.head = toLinks.next
    else
        self.links[fromLinks.prev].next = toLinks.next
    end

    if to == self.tail then
        self.tail = fromLinks.prev
    else
        self.links[toLinks.next].prev = fromLinks.prev
    end

    return fromLinks.prev, toLinks.next
end

function Chain:iter()
    local function f(head, item)
        if item then
            local nextItem = self.links[item].next
            return nextItem, self.links[nextItem]
        else
            return head
        end
    end

    return f, self.head, nil
end

function Chain:reverseIter()
    local function f(tail, item)
        if item then
            local prevItem = self.links[item].prev
            return prevItem, self.links[prevItem]
        else
            return tail
        end
    end

    return f, self.tail, nil
end

return {Chain = Chain}
