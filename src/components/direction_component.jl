module Direction
abstract type AbstractDirection end

struct North <: AbstractDirection end

struct East <: AbstractDirection end

struct South <: AbstractDirection end

struct West <: AbstractDirection end

const north = North()
const east = East()
const south = South()
const west = West()

function Base.:(+)(d::AbstractDirection, i::Integer)
    for _ in 1:mod(i, 4)
        d = _next_direction(d)
    end
    d
end

function _next_direction(::North)
    west
end

function _next_direction(::East)
    north
end

function _next_direction(::South)
    east
end

function _next_direction(::West)
   south
end

function Base.Int(d::AbstractDirection)
    if d == north
        return 0
    elseif d == west
        return 1
    elseif d == south
        return 2
    elseif d == east
        return 3

    end
end

export AbstractDirection, North, East, South, West
end