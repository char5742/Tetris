include("src/Tetris.jl")
using .Tetris
function main()
    game_state = GameState()
    move_state = MoveState()
    init_screen()
    manual(game_state, move_state)
    endwin()
end

function manual(game_state::GameState, move_state::MoveState)
    # ゲームオーバーになるまで繰り返す
    draw_game(game_state)
    start_time = time_ns()
    while !game_state.game_over_flag
        x = -get_key_state(:VK_LEFT) + get_key_state(:VK_RIGHT)
        y = get_key_state(:VK_DOWN)
        r = -get_key_state(:VK_UP) - get_key_state(:VK_Z) + get_key_state(:VK_CONTROL)
        get_key_state(:VK_ESCAPE) == 1 && exit()
        hard_drop = get_key_state(:VK_SPACE) == 1
        hold = get_key_state(:VK_SHIFT) == 1
        action = Action(x  |> Int8, y  |> Int8, r  |> Int8, hold  |> Int8, hard_drop  |> Int8)

        if move_state.set_count > 0 && (action.x != 0 || action.y != 0 || action.rotate != 0) && move_state.set_safe_cout < 15
            move_state.set_safe_cout += 1
            move_state.set_count = 0
        end
        action!(game_state, action)


        move_state.fall_count += 1
        if move_state.fall_count == 60
            move_state.fall_count = 0
            action = Action(0  |> Int8, 1  |> Int8, 0  |> Int8)
            if valid_movement(game_state.current_mino, game_state.current_position, game_state.current_game_board.binary, 0 |> Int8, 1 |> Int8)
                game_state.current_position = move(game_state.current_position, 0 |> Int8, 1 |> Int8)
                move_state.set_count = 0
            end
        end

        if !valid_movement(game_state.current_mino, game_state.current_position, game_state.current_game_board.binary, 0 |> Int8, 1 |> Int8)
            move_state.set_count += 1
        end
        if move_state.set_count == 30 || game_state.hard_drop_flag
            move_state.set_count = 0
            move_state.set_safe_cout = 0
            put_mino!(game_state)

        end

        sleep60fps(start_time)
        start_time = time_ns()
        draw_game(game_state)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()

end