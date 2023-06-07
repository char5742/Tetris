# 落下タイミングや速度など、リアルタイムで操作する際に扱う構造体
mutable struct MoveState
    fall_count::Int8
    set_count::Int8
    set_safe_cout::Int8
    das_count::Int8
    MoveState() = new(0, 0, 0, 0)
end