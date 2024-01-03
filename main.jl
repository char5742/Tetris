include("src/Tetris.jl")
using .Tetris
function main()
    try
        game_state = GameState()
        move_state = MoveState()
        init_screen()
        manual(game_state, move_state)
    catch e
        # 現在の例外のスタックトレースを取得
        open("error.log", "w") do io
            showerror(io, e, catch_backtrace())
        end

    finally
        endwin()
    end
end

function manual(game_state::GameState, move_state::MoveState)
    # ゲームオーバーになるまで繰り返す
    draw_game(game_state)
    start_time = time_ns()
    pre_action = nothing
    while !game_state.game_over_flag
        action = key_to_action()
        if pre_action == action && isa(action, HorizontalMoveAction)
            # 同じアクションを繰り返している場合はDAS処理を行う
            process_das!(move_state, game_state)
        else
            reset_auto_set_delay_on_move!(move_state, action)
            action!(game_state, action)
        end

        pre_action = action
        fall!(move_state, game_state)
        put_mino!(move_state, game_state)

        sleep60fps(start_time)
        start_time = time_ns()
        draw_game(game_state)
    end
end

function key_to_action()::AbstractAction
    state = get_current_key_state()
    x = -is_pushed(state, :VK_LEFT) + is_pushed(state, :VK_RIGHT)
    y = is_pushed(state, :VK_DOWN)
    turn_right = is_pushed(state, :VK_UP) + is_pushed(state, :VK_Z) + is_pushed(state, :VK_D)
    turn_left = is_pushed(state, :VK_CONTROL) + is_pushed(state, :VK_S)
    r = -turn_right + turn_left
    is_pushed(state, :VK_ESCAPE) == 1 && exit()
    hard_drop = is_pushed(state, :VK_SPACE) == 1
    hold = is_pushed(state, :VK_SHIFT) + is_pushed(state, :VK_A) != 0

    hold && return HoldAction()
    hard_drop && return HardDropAction()
    x != 0 && return HorizontalMoveAction(x)
    y != 0 && return DownwardMoveAction()
    r != 0 && return RotateAction(r)
    EmptyAction()
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end