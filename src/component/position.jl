struct Position
    x::Int8
    y::Int8
end

function Position(mino::Mino)
    if mino == TetrisMino.o_mino
        return Position(5, 3)
    end
    return Position(4, 3)
end