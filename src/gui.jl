
module GUI

using Printf
include("const.jl")
# ANSIエスケープシーケンス
const Color = Dict(
    :black => "\e[30m",
    :red => "\e[31m",
    :blue => "\e[34m",
    :green => "\e[32m",
    :yellow => "\e[33m",
    :purple => "\e[35m",
    :cyan => "\e[36m",
    :white => "\e[37m",
    :end => "\e[0m",
    :bold => "\038[1m",
    :underline => "\e[4m",
    :invisible => "\e[08m",
    :reverce => "\e[07m",
)

const block_color = [
    (50, 50, 50),
    (150, 150, 150),
    (255, 0, 0),  # red
    (0, 0, 255),  # blue
    (255, 165, 0),  # orange
    (255, 0, 255),  # purple
    (0, 255, 0),  # green
    (0, 255, 255),  # light blue
    (255, 255, 0),  # yellow
    (200, 200, 200),
    (100, 100, 100),
]

const col = 10  # 10 columns
const row = 20  # 20 rows


colored(str::String, sym) = string(Color[sym], str, Color[:end])
colored(str::String, i::Integer) = string(@sprintf("\e[48;2;%s;%s;%sm", block_color[(i-1)%11+1]...), str, Color[:end])


function open_terminal()
    run(`cmd /c start  powershell "Get-Content .\\board.txt -Wait -Tail 24"`, wait=false)
end

struct WINDOW
end
struct PDCCOLOR
    r::Int16
    g::Int16
    b::Int16
    mapped::Bool
end
curses = joinpath(PROJECT_ROOT, "pdcurses.dll")
chmod(curses, filemode(curses) | 0o755)
initscr() = ccall((:initscr, curses), Ptr{WINDOW}, ())
endwin() = ccall((:endwin, curses), Cint, ())
noecho() = ccall((:noecho, curses), Cint, ())
curs_set(n::Int) = ccall((:curs_set, curses), Cint, (Cint,), n)
start_color() = ccall((:start_color, curses), Cint, ())
init_color(n::Int, r::Int, g::Int, b::Int) = ccall((:init_color, curses), Cint, (Cshort, Cshort, Cshort, Cshort), n, r, g, b)
init_pair(pair::Int, fg::Int, bg::Int) = ccall((:init_pair, curses), Cint, (Cshort, Cshort, Cshort), pair, fg, bg)
clear() = ccall((:clear, curses), Cint, ())
mvaddstr(x::Int, y::Int, text::String) = ccall((:mvaddstr, curses), Cint, (Cint, Cint, Cstring), x, y, text)
refresh() = ccall((:refresh, curses), Cint, ())
napms(t::Int) = ccall((:napms, curses), Cint, (Cint,), t)
wgetch(window) = ccall((:wgetch, curses), Cint, (Ptr{WINDOW},), window)
flushinp() = ccall((:flushinp, curses), Cint, ())
timeout(t::Int) = ccall((:timeout, curses), Cint, (Cint,), t)
attrset(color::PDCCOLOR) = ccall((:attrset, curses), Cint, (PDCCOLOR,), color)
attrset(n::Int) = ccall((:attrset, curses), Cint, (Cint,), n)
color_set(n::Int) = ccall((:color_set, curses), Cint, (Cshort, Ptr{Cvoid}), n, C_NULL)

end

import .GUI

function init_screen()::Ptr{GUI.WINDOW}
    window = GUI.initscr()
    if (window == C_NULL)
        throw(ErrorException("can't init"))
    end
    GUI.start_color()
    GUI.noecho()
    GUI.curs_set(0)
    for (i, c) in enumerate(GUI.block_color)
        # 標準の色番号とかぶらないように100番目からセット
        GUI.init_color(100 + i, (c .* (1000 / 255) |> x -> floor.(Int, x))...)
        GUI.init_pair(100 + i, 0, 100 + i)
    end
    GUI.timeout(1)
    window
end

function endwin()
    GUI.endwin()
end

function draw_game(board; score=nothing, ren=nothing, hold=nothing, next=nothing, step=1)

    GUI.clear()
    for i in 1:GUI.row
        for j in 1:GUI.col
            coloerd_mvaddstr(i, 8 + j * 2, "  ", board[5:end, :][i, j] + 1)
        end

    end
    # NEXT描画
    GUI.mvaddstr(2, 34, "next")
    coloerd_mvaddstr(3, 34, "$(next[end].name)", next[end].color + 1)
    for i in 1:4
        coloerd_mvaddstr(i + 4, 34, "$(next[end-i].name)", next[end-i].color + 1)
    end
    # HOLD描画
    GUI.mvaddstr(2, 2, "hold")
    !isnothing(hold) && coloerd_mvaddstr(3, 2, "$(hold.name)", hold.color + 1)
    !isnothing(score) && GUI.mvaddstr(10, 34, string("score: ", score))
    !isnothing(score) && GUI.mvaddstr(11, 34, string("mscore: ", score / step))
    !isnothing(ren) && GUI.mvaddstr(13, 34, string("REN: ", ren))
    GUI.refresh()
    # gamec.game_over_flag && print(io, "\e[14;34f", "BtB")
end

function coloerd_mvaddstr(x, y, text, color)
    GUI.color_set(color + 100)
    GUI.mvaddstr(x, y, text)
    GUI.attrset(0)
end

function draw_game(state::GameState; step=1)
    mino = state.current_mino
    board = state.current_game_board.color
    pos_x = state.current_position.x
    pos_y = state.current_position.y
    board_h, board_w = size(board)
    h, w = size(mino.block)
    current_mino = zeros(Int, board_h + 2, board_w + 4)
    current_mino[pos_y:pos_y+h-1, pos_x+2:pos_x+w-1+2] += mino.block * mino.color
    draw_game(board + current_mino[1:end-2, 3:end-2]; score=state.score, ren=state.combo, hold=state.hold_mino, next=state.mino_list[end-4:end], step=step)
end

function draw_game2file(board; score=0, last_score=0)
    io = IOBuffer()
    # 先頭荷カーソル移動
    print(io, "\e[1;1f")
    # カーソルよりあとを削除
    print(io, "\e[0J")
    for i in 1:GUI.row
        for j in 1:GUI.col
            print(io, GUI.colored("  ", board[i, j] + 1))
        end
        # カーソルに位置を一行下に
        print(io, "\e[1E")
    end
    print(io, "\e[3;24f", "score", score)
    # カーソル位置を一番下に
    print(io, "\e[17E")
    open(f -> println(f, String(take!(io))), "board.txt", "w")
end

function getc1()
    ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    ret == 0 || error("unable to switch to raw mode")
    c = read(stdin, Char)
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, false)
    c
end

