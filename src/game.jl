using Random
"ゲームの状態"
mutable struct GameState
    current_game_board::GameBoard
    current_mino::Mino
    current_position::Position
    hold_mino::Union{Mino,Nothing}
    mino_list::Vector{Mino}
    score::Float64
    combo::Int
    "コンボが発生するかどうか。この値がtrueのときのみcomboが加算される"
    combo_flag::Bool
    back_to_back_flag::Bool
    game_over_flag::Bool
    hold_flag::Bool
    hard_drop_flag::Bool
    "最後のアクションがTSPIN条件を満たしているかどうか"
    t_spin_flag::Bool

    function GameState()
        current_game_board = GameBoard()
        mino_list = append!(generate_mino_list(), generate_mino_list())
        currnet_mino = pop!(mino_list)
        hold_mino = nothing
        current_position = Position(currnet_mino)
        score = 0.0
        combo = 0
        combo_flag = false
        back_to_back_flag = false
        game_over_flag = false
        hold_flag = true
        hard_drop_flag = false
        t_spin_flag = false
        return new(current_game_board, currnet_mino, current_position, hold_mino, mino_list, score, combo, combo_flag, back_to_back_flag, game_over_flag, hold_flag, hard_drop_flag, t_spin_flag)
    end
end


"""
1巡のMINOを生成
"""
function generate_mino_list()::Vector{Mino}
    mino_list::Vector{Mino} = [e for e in TetrisMino.minos]
    shuffle!(mino_list)
    return mino_list
end

"""
操作
"""
function action!(state::GameState, action::Action)
    x, y, r = action.x, action.y, action.rotate
    if r != 0
        new_mino, new_position, _ = rotate(state.current_mino, state.current_position, state.current_game_board.binary, r)
        state.current_mino = new_mino
        state.current_position = new_position
    end
    valid = valid_movement(state.current_mino, state.current_position, state.current_game_board.binary, x, y)
    if (valid)
        state.current_position = move(state.current_position, x, y)
    end
    action.hold && hold!(state)
    action.hard_drop && hard_drop!(state)
    # 最後に行った有効な操作でtspinを判定
    if valid && action.x != 0 || action.y != 0 || action.rotate != 0
        # 移動、回転操作で回転であれば TSPIN 可と判定
        state.t_spin_flag = action.rotate != 0
    end
end

"ハードドロップ 行ける限り下まで移動させる"
function hard_drop!(state::GameState)
    while valid_movement(state.current_mino, state.current_position, state.current_game_board.binary, 0, 1)
        state.current_position = move(state.current_position, 0, 1)
    end
    state.hard_drop_flag = true
end

"ホールド"
function hold!(state::GameState)
    # ホールドをまだ使用していない場合
    if isnothing(state.hold_mino)
        state.hold_mino = Mino(state.current_mino)
        set_current_mino!(state)
        state.current_position = Position(state.current_mino)
    end
    if state.hold_flag
        state.current_mino, state.hold_mino = Mino(state.hold_mino), Mino(state.current_mino)
        state.current_position = Position(state.current_mino)
    end
    state.hold_flag = false
end

"""
NEXTをセット
"""
function set_current_mino!(state::GameState)
    state.current_mino = pop!(state.mino_list)
    if length(state.mino_list) < 8
        state.mino_list = append!(generate_mino_list(), state.mino_list)
    end
    currnet_minoblock = state.current_mino.block
    spawn_position = Position(state.current_mino)
    h, w = size(currnet_minoblock)
    if sum(state.current_game_board.binary[spawn_position.y:spawn_position.y+h-1, spawn_position.x:spawn_position.x+w-1] .* currnet_minoblock) != 0
        game_end!(state)
    end
    state.current_position = Position(state.current_mino)
end

function game_end!(state::GameState)
    state.game_over_flag = true
end

"""
現在のMINOの位置を固定
"""
function put_mino!(state::GameState)
    state.hold_flag = true
    state.hard_drop_flag = false
    set_mino!(state.current_game_board, state.current_mino, state.current_position)
    tspin = check_tspin(state)
    deleted_line_count = delete_line!(state)
    add_score!(state, deleted_line_count, tspin)
    set_current_mino!(state)
end

"""
一列揃っているラインを消去
"""
function delete_line!(state::GameState)::Int
    delete_line = sum(state.current_game_board.binary, dims=2)
    deleted_line_count = 0
    for (i, v) in enumerate(delete_line)
        if v == 10
            delete_line!(state.current_game_board, i)
            deleted_line_count += 1
        end
    end
    deleted_line_count
end

function add_score!(state::GameState, deleted_line_num::Int, tspin::Int)
    score = 0
    if deleted_line_num == 0
        state.combo_flag = false
        state.combo = 0
        return
    end
    if deleted_line_num == 1
        if tspin != 0
            score = tspin == 1 ? 0 : 200
        else
            score = 0
            state.back_to_back_flag = false
        end
    elseif deleted_line_num == 2
        if tspin != 0
            score = tspin == 1 ? 0 : 400
        else
            score = 100
            state.back_to_back_flag = false
        end
    elseif deleted_line_num == 3
        if tspin != 0
            score = tspin == 1 ? 0 : 600
        else
            score = 200
            state.back_to_back_flag = false
        end
    elseif deleted_line_num == 4
        score = 400
        if state.back_to_back_flag
            score += 100
        end
        state.back_to_back_flag = true
    end
    if tspin != 0
        if state.back_to_back_flag
            score += 100
        end
        state.back_to_back_flag = true
    end

    if sum(state.current_game_board.binary) == 0
        score += 1000
    end
    score += combo_power(state.combo) * 100
    state.score += score
    if state.combo_flag
        state.combo += 1
    end
    state.combo_flag = true
end

function combo_power(combo::Int)
    if combo < 2
        0
    elseif combo < 4
        1
    elseif combo < 6
        2
    elseif combo < 8
        3
    elseif combo < 11
        4
    else
        5
    end
end

"""
t-spin判定\\
0 not t-psin\\
1 t-spin mini\\
2 t-spin
"""
function check_tspin(state::GameState)::Int
    check_tspin(state.current_mino, state.current_position.x, state.current_position.y, state.current_mino.direction, state.current_game_board.binary, state.t_spin_flag)
end


"""
t-spin判定\\
0 not t-psin\\
1 t-spin mini\\
2 t-spin
"""
function check_tspin(mino::Mino, pos_x, pos_y, direction::DirectionEnum, gamebord, t_spin_flag)::Int
    if mino != TetrisMino.t_mino || !t_spin_flag
        return 0
    end
    left = pos_x + 1
    right = left + 2
    upper = pos_y + 1
    lower = upper + 2
    height, width = size(gamebord)
    bord = ones(height + 2, width + 2)
    bord[2:end-1, 2:end-1] = gamebord
    lu = bord[upper, left]
    ll = bord[lower, left]
    ru = bord[upper, right]
    rl = bord[lower, right]
    if lu + ll + ru + rl >= 3
        if direction == Direction.nort
            return lu == ru ? 2 : 1
        elseif direction == Direction.west
            return lu == ll ? 2 : 1
        elseif direction == Direction.south
            return ll == rl ? 2 : 1
        elseif direction == Direction.east
            return ru == rl ? 2 : 1
        end
    end
    return 0
end