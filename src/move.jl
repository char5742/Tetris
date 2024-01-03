"落下タイミングや速度など、リアルタイムで操作する際に扱う構造体"
mutable struct MoveState
    fall_count::Int8
    set_count::Int8
    "設置までの猶予回数"
    set_safe_cout::Int8
    das_count::Int8
    MoveState() = new(0, 0, 0, 0)
end

function reset_auto_set_delay_on_move!(::MoveState, ::AbstractAction)
    nothing
end

function reset_auto_set_delay_on_move!(move_state::MoveState, ::HorizontalMoveAction)
    reset_auto_set_delay_if_possible!(move_state)
end

function reset_auto_set_delay_on_move!(move_state::MoveState, ::RotateAction)
    reset_auto_set_delay_if_possible!(move_state)
end

function reset_auto_set_delay_if_possible!(move_state::MoveState)
    if move_state.set_count > 0 &&
       move_state.set_safe_cout < 15
        move_state.set_safe_cout += 1
        move_state.set_count = 0
    end
end

"自由落下"
function fall!(move_state::MoveState, game_state::GameState, fall_speed=1)
    move_state.fall_count += fall_speed
    if move_state.fall_count == 60
        move_state.fall_count = 0
        new_position, is_valid = move(game_state.current_mino,
            game_state.current_position,
            game_state.current_game_board.binary,
            0 |> Int8,
            1 |> Int8)
        if is_valid
            game_state.current_position = new_position
            move_state.set_count = 0
        end
    end
end

"設置"
function put_mino!(move_state::MoveState, game_state::GameState)
    _, is_valid = move(game_state.current_mino,
        game_state.current_position,
        game_state.current_game_board.binary,
        0 |> Int8,
        1 |> Int8)
    if !is_valid
        move_state.set_count += 1
    end
    if move_state.set_count == 30 || game_state.hard_drop_flag
        move_state.set_count = 0
        move_state.set_safe_cout = 0
        put_mino!(game_state)
    end
end

"DAS処理"
function process_das!(move_state::MoveState, game_state::GameState)
    move_state.das_count += 1
    if move_state.das_count >= 18 &&
        (move_state.das_count-18)÷3==0
        action = HorizontalMoveAction(x |> Int8)
        reset_auto_set_delay_on_move!(move_state, action)
        action!(game_state, action)
    end
end