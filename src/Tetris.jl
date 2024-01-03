module Tetris
using LinearAlgebra
include("const.jl")
include("utils/Utils.jl")
export mysleep, sleep60fps, get_key_state
include("component/direction_component.jl")
using .Direction
include("component/mino_component.jl")
include("component/position_component.jl")
include("component/action_component.jl")
include("component/game_board_component.jl")
export Mino, GameBoard, Position, Action,
    AbstractAction, HorizontalMoveAction, DownwardMoveAction, SoftDropAction, RotateAction,
    HoldAction, HardDropAction, EmptyAction, Actionflow
include("srs.jl")
export action!, move, rotate
include("game.jl")
export GameState, put_mino!, check_tspin, game_end!
include("move.jl")
export MoveState, reset_auto_set_delay_on_move!, fall!, put_mino!, process_das!
include("gui.jl")
export draw_game, draw_game2file, init_screen, endwin, get_current_key_state, is_pushed
end # module Tetris
