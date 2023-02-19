const LEFT_ROTATION::Int64 = 1

"""
現在のMINOの位置にあるエリアを切り出す
"""
function target_bord_area(mino::Mino,  binary_board::Matrix{Int64}, pos_x::Int64, pos_y::Int64)::Matrix{Int64}
    mino_height, mino_width = size(mino.block)
    return @view binary_board[2+pos_y:2+pos_y+mino_height-1, pos_x+3:pos_x+mino_width-1+3]
end

function valid_movement(mino::Mino, position::Position,  binary_board::Matrix{Int64}, mv_x::Int64, mv_y::Int64)
    cnt = 0
    height, width = size(mino.block)
    for j in 1:width, i in 1:height
        if !checkbounds(Bool, binary_board, position.y + i - 1 + mv_y, position.x + j - 1 + mv_x)
            cnt += mino.block[i, j]
        else
            cnt += binary_board[position.y+i-1+mv_y, position.x+j-1+mv_x] * mino.block[i, j]
        end
    end
    return cnt == 0
end

function is_collide(x, y)::Bool
    if sum(x .* y) > 0
        return true
    end
    return false
end


function move(position::Position, x::Int64, y::Int64)::Position
    Position(position.x + x, position.y + y)
end

"rotate: -1~1"
function rotate_mino(mino::Mino, rotate::Int64)::Mino
    if rotate == LEFT_ROTATION
        mino_block = rotl90(mino.block)
    else
        mino_block = rotr90(mino.block)
    end
    direction = DirectionEnum(mod(Int(mino.direction) + rotate, 4))
    return Mino(mino.name, mino.color, direction, mino_block)
end

function rotate(mino::Mino, position::Position, binary_board::Matrix{Int64}, rotate::Int64)::Tuple{Mino,Position,Bool}
    mino_height, _ = size(mino.block)
    # Oミノは回転しない
    if mino_height == 2
        return mino, position, false
    end
    new_mino = rotate_mino(mino, rotate)
    if valid_movement(new_mino, position, binary_board, 0,0)
        return new_mino, position, true
    end
    res = (() -> begin
        # Iミノ以外
        if mino_height == 3
            mv_x, mv_y = _rotate1(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
            mv_x, mv_y = _rotate2(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
            mv_x, mv_y = _rotate3(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
            mv_x, mv_y = _rotate4(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
        else
            mv_x, mv_y = _rotate1_i(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
            mv_x, mv_y = _rotate2_i(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
            mv_x, mv_y = _rotate3_i(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
            mv_x, mv_y = _rotate4_i(mino, rotate)
            valid_movement(new_mino, position, binary_board, mv_x, mv_y) && return (mv_x, mv_y)
        end
        return (0, 0)
    end)()
    if res[1] != 0
        new_position = move(position, res[1], res[2])
        return new_mino, new_position, true
    else
        return mino, position, false
    end
end

function check_rotate(mino, block, safty_bord, pos_x, pos_y)
    current_bord_area = target_bord_area(mino, safty_bord, pos_x, pos_y)
    !is_collide(block, current_bord_area)
end



function _rotate1(mino::Mino, rotate::Int64)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    if dir == 1 || dir == 3
        mv_x = (dir - 2) * -1
    else
        mv_x = (Int(mino.direction) - 2) * 1
    end
    (mv_x, 0)
end

function _rotate2(
    mino::Mino, rotate::Int64
)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    mv_x, mv_y = _rotate1(mino, rotate)
    if dir == 1 || dir == 3
        mv_y -= 1
    else
        mv_y += 1
    end
    (mv_x, mv_y)
end

function _rotate3(
    mino::Mino, rotate::Int64
)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    if dir == 1 || dir == 3
        mv_y = 2
    else
        mv_y = -2
    end
    (0, mv_y)
end

function _rotate4(
    mino::Mino,
    rotate::Int64,
)::Tuple{Int64,Int64}
    mv_x, mv_y = _rotate3(mino, rotate)
    mv_x1, mv_y1 = _rotate1(mino, rotate)
    (mv_x + mv_x1, mv_y + mv_y1)
end

function _rotate1_i(
    mino::Mino, rotate::Int64
)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    if Int(mino.direction) == 0
        mv_x = -(dir == 1 ? 1 : 2)
    elseif Int(mino.direction) == 2
        mv_x = dir == 1 ? 2 : 1
    else
        mv_x = (rotate) * (dir == 0 ? 2 : 1)
    end
    (mv_x, 0)
end

function _rotate2_i(
    mino::Mino, rotate::Int64
)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    if Int(mino.direction) == 0
        mv_x = dir == 1 ? 2 : 1
    elseif Int(mino.direction) == 2
        mv_x = -(dir == 1 ? 1 : 2)
    else
        mv_x = -(rotate) * (dir == 0 ? 1 : 2)
    end
    (mv_x, 0)
end


function _rotate3_i(
    mino::Mino, rotate::Int64
)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    if dir == 1 || dir == 3
        mv = rotate == LEFT_ROTATION ? 2 : 1
        mv_x, mv_y = _rotate1_i(mino, rotate)
        if dir == 3
            mv_y += mv
        else
            mv_y -= mv
        end
    else
        mv = rotate == LEFT_ROTATION ? 1 : 2
        if Int(mino.direction) == 3
            mv_x, mv_y = _rotate1_i(mino, rotate)
            mv_y -= mv
        else
            mv_x, mv_y = _rotate2_i(mino, rotate)
            mv_y += mv
        end
    end
    (mv_x, mv_y)
end

function _rotate4_i(
    mino::Mino, rotate::Int64
)::Tuple{Int64,Int64}
    dir = mod((Int(mino.direction) + rotate), 4)
    if dir == 1 || dir == 3
        mv = rotate == LEFT_ROTATION ? 1 : 2
        mv_x, mv_y = _rotate2_i(mino, rotate)
        if dir == 3
            mv_y -= mv
        else
            mv_y += mv
        end
    else
        mv = rotate == LEFT_ROTATION ? 2 : 1
        if Int(mino.direction) == 3
            mv_x, mv_y = _rotate2_i(mino, rotate)
            mv_y += mv
        else
            mv_x, mv_y = _rotate1_i(mino, rotate)
            mv_y -= mv
        end
    end
    (mv_x, mv_y)
end
