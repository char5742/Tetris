struct GameBoard
    color::Matrix{Int64}
    binary::Matrix{Int64}
    GameBoard() = new(zeros(Int64, 24, 10), zeros(Int64, 24, 10))
end

"""
MINOをセットする
ここでは配置可能性を考慮しない
"""
function set_mino!(board::GameBoard, mino::Mino, position::Position)
    mino_height, mino_width = size(mino.block)
    for j in 1:mino_width, i in 1:mino_height
        if checkbounds(Bool, board.color, position.y + i - 1, position.x + j - 1)
            board.color[position.y+i-1, position.x+j-1] += mino.block[i, j] * mino.color
        end
    end
    board.binary .= (x -> x > 0 ? 1 : 0).(board.color)
end

function delete_line!(board::GameBoard, y::Int)
    color_board = board.color
    color_board[y, :] .= 0
    color_board[2:y, :] .= color_board[1:y-1, :]  # 1ラインづつずれる
    color_board[1, :] .= 0  # new line
    board.binary .= (x -> x > 0 ? 1 : 0).(board.color)
end