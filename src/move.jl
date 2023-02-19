# 落下タイミングや速度など、リアルタイムで操作する際に扱う構造体
mutable struct MoveState
    fall_count::Int64
    set_count::Int64
    set_safe_cout::Int64
    das_count::Int64
    MoveState() = new(0, 0, 0, 0)
end