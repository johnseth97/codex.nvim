-- .luacheckrc
std = "luajit"
globals = { "vim" }
ignore = {
  "plugin/*", -- plugin loader shim
}

max_line_length = false      -- or turn it off completely

