using Printf
# ANSIエスケープシーケンス
Color = Dict(
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

colored(str::String, sym) = string(Color[sym], str, Color[:end])
colored(str::String, i::Integer) = string(@sprintf("\e[48;2;%s;%s;%sm", block_color[(i-1)%11+1]...), str, Color[:end])
col = 10  # 10 columns
row = 20  # 20 rows

function open_terminal()
    run(`cmd /c start  powershell "Get-Content .\\bord.txt -Wait -Tail 24"`, wait=false)
end

struct WINDOW
end
struct PDCCOLOR
    r::Int16
    g::Int16
    b::Int16
    mapped::Bool
end
curses = "./pdcurses.dll"
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

function init_screen()::Ptr{WINDOW}
    window = initscr()
    if (window == C_NULL)
        throw(ErrorException("can't init"))
    end
    start_color()
    noecho()
    curs_set(0)
    for (i, c) in enumerate(block_color)
        # 標準の色番号とかぶらないように100番目からセット
        init_color(100 + i, (c .* (1000 / 255) |> x -> floor.(Int, x))...)
        init_pair(100 + i, 0, 100 + i)
    end
    timeout(1)
    window
end

function draw_game(bord; score=0, last_score=0)
    io = IOBuffer()
    # 先頭荷カーソル移動
    print(io, "\e[1;1f")
    # カーソルよりあとを削除
    print(io, "\e[0J")
    for i in 1:row
        for j in 1:col
            print(io, colored("  ", bord[i, j] + 1))
        end
        # カーソルに位置を一行下に
        print(io, "\e[1E")
    end
    print(io, "\e[3;24f", "score", score)
    # カーソル位置を一番下に
    print(io, "\e[17E")
    println(String(take!(io)))
end

function coloerd_mvaddstr(x, y, text, color)
    color_set(color + 100)
    mvaddstr(x, y, text)
    attrset(0)
end

function draw_game(state::GameState; last_score=0)
    mino = state.current_mino
    bord = state.current_game_board.color
    pos_x = state.current_position.x
    pos_y = state.current_position.y
    bord_h, bord_w = size(bord)
    h, w = size(mino.block)
    current_mino = zeros(Int, bord_h + 2, bord_w + 4)
    current_mino[pos_y:pos_y+h-1, pos_x+2:pos_x+w-1+2] += mino.block * mino.color

    clear()
    for i in 1:row
        for j in 1:col
            coloerd_mvaddstr(i, 8 + j * 2, "  ", bord[5:end, :][i, j] + 1 + current_mino[1:end-2, 3:end-2][5:end, :][i, j])
        end

    end
    # NEXT描画
    mvaddstr(2, 34, "next")
    coloerd_mvaddstr(3, 34, "$(state.mino_list[end].name)", state.mino_list[end].color + 1)
    for i in 1:4
        coloerd_mvaddstr(i + 4, 34, "$(state.mino_list[end-i+1].name)", state.mino_list[end-i+1].color + 1)
    end
    # HOLD描画
    mvaddstr(2, 2, "hold")
    !isnothing(state.hold_mino) && coloerd_mvaddstr(3, 2, "$(state.hold_mino.name)", state.hold_mino.color + 1)
    mvaddstr(10, 34, string("score: ", state.score))
    mvaddstr(12, 34, string("REN: ", state.combo))
    refresh()
    # gamec.game_over_flag && print(io, "\e[14;34f", "BtB")
end

function draw_game2file(bord; score=0, last_score=0)
    # open("bord.txt", "w") do io
    #     # 先頭荷カーソル移動
    #     print(io, "\e[1;1f")
    #     # カーソルよりあとを削除
    #     print(io, "\e[0J")
    #     for i in 1:row
    #         for j in 1:col
    #             print(io, colored("  ", bord[i, j] + 1))
    #         end
    #         println(io, i == 4 ? "         score $score" : "")
    #     end
    # end
    io = IOBuffer()
    # 先頭荷カーソル移動
    print(io, "\e[1;1f")
    # カーソルよりあとを削除
    print(io, "\e[0J")
    for i in 1:row
        for j in 1:col
            print(io, colored("  ", bord[i, j] + 1))
        end
        # カーソルに位置を一行下に
        print(io, "\e[1E")
    end
    print(io, "\e[3;24f", "score", score)
    # カーソル位置を一番下に
    print(io, "\e[17E")
    open(f -> println(f, String(take!(io))), "bord.txt", "w")
end

function getc1()
    ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    ret == 0 || error("unable to switch to raw mode")
    c = read(stdin, Char)
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, false)
    c
end