
module TetrisMino
import Base
using ..Direction

export Mino

"テトリミノ"
struct Mino
    name::String
    color::Int8
    "北:0 西:1 南:2 東:3"
    direction::DirectionEnum
    block::Matrix{Int8}
end

function Mino(mino::Mino)::Mino
    if mino == i_mino
        return i_mino
    elseif mino == o_mino
        return o_mino
    elseif mino == s_mino
        return s_mino
    elseif mino == z_mino
        return z_mino
    elseif mino == j_mino
        return j_mino
    elseif mino == l_mino
        return l_mino
    else
        return t_mino
    end
end

Base.:(==)(a::Mino, b::Mino) = a.name == b.name

const i_mino = Mino(
    "Imino",
    7,
    Direction.north,
    [
        0 0 0 0
        1 1 1 1
        0 0 0 0
        0 0 0 0
    ]
)
const o_mino = Mino(
    "Omino",
    8,
    Direction.north,
    [
        0 1 1
        0 1 1
    ]
)
const s_mino = Mino(
    "Smino",
    6,
    Direction.north,
    [
        0 1 1
        1 1 0
        0 0 0
    ]
)
const z_mino = Mino(
    "Zmino",
    2,
    Direction.north,
    [
        1 1 0
        0 1 1
        0 0 0
    ]
)
const j_mino = Mino(
    "Jmino",
    3,
    Direction.north,
    [
        1 0 0
        1 1 1
        0 0 0
    ]
)
const l_mino = Mino(
    "Lmino",
    4,
    Direction.north,
    [
        0 0 1
        1 1 1
        0 0 0
    ]
)

const t_mino = Mino(
    "Tmino",
    5,
    Direction.north,
    [
        0 1 0
        1 1 1
        0 0 0
    ]
)
minos = [i_mino, o_mino, s_mino, z_mino, j_mino, l_mino, t_mino]



end