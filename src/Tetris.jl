module Tetris
using LinearAlgebra
include("const.jl")

include("../lib/curses.jl")
include("../lib/key_input.jl")
export get_key_state

include("utils/sleep.jl")
export mysleep, sleep60fps

include("component/direction_component.jl")
using .Direction
include("component/mino_component.jl")
include("component/position_component.jl")
include("component/action_component.jl")
include("component/game_board_component.jl")
export AbstractMino, Mino, GameBoard, Position, Action,
    AbstractAction, HorizontalMoveAction, DownwardMoveAction, SoftDropAction, RotateAction,
    HoldAction, HardDropAction, EmptyAction, Actionflow
include("srs.jl")
export action!, move, rotate, is_valid_mino_movement
include("game.jl")
export GameState, put_mino!, check_tspin, game_end!, get_ghost_position
include("move.jl")
export MoveState, reset_auto_set_delay_on_move!, fall!, put_mino!, process_das!
include("gui.jl")
export  AbstractModel, CursesModel, draw_game2file, update, init, fin, set_state!, get_current_key_state, is_pushed
end # module Tetris
