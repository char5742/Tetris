const VK_SHIFT = 0x10
const VK_CONTROL = 0x11
const VK_ESCAPE = 0x1B
const VK_SPACE = 0x20
const VK_LEFT = 0x25
const VK_UP = 0x26
const VK_RIGHT = 0x27
const VK_DOWN = 0x28
const VK_Z = 0x5A

const _key_state_source= joinpath(PROJECT_ROOT,"game.so")
chmod(_key_state_source, filemode(_key_state_source) | 0o755)
get_key_state(key::Symbol) = ccall((:getkeystate, _key_state_source), Int32, (Int32,), eval(key))
