
"行動の最小単位"
struct Action
    "-1~1"
    x::Int8
    "-1~1"
    y::Int8
    "-1, 1"
    rotate::Int8
    hold::Bool
    hard_drop::Bool
end
Action(x::Int8, y::Int8, rotate::Int8) = Action(x, y, rotate, false, false)
Action(x::Int64, y::Int64, rotate::Int64) = Action(x |> Int8, y  |> Int8, rotate |> Int8, false, false)
Action(x::Int64, y::Int64, rotate::Int64, hold::Bool, hard_drop::Bool) = Action(x |> Int8, y  |> Int8, rotate |> Int8, hold, hard_drop)
struct Actionflow
    flow::Vector{Action}
    after_bord::Matrix{Int8}
    mino::Mino
    pos_x::Int8
    pos_y::Int8
    direction::Int8
end