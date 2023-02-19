
"行動の最小単位"
struct Action
    "-1~1"
    x::Int64
    "-1~1"
    y::Int64
    "-1, 1"
    rotate::Int64
    hold::Bool
    hard_drop::Bool
end
Action(x::Int64, y::Int64, rotate::Int64) = Action(x, y, rotate, false, false)

struct Actionflow
    flow::Vector{Action}
    after_bord::Matrix{Int64}
    mino::Mino
    pos_x::Int64
    pos_y::Int64
    direction::Int64
end