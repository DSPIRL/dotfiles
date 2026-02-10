$env.config.keybindings ++= [
    {
        name: fzf_files
        modifier: control
        keycode: char_t
        mode: [emacs, vi_normal, vi_insert]
        event: [
            {
                send:executehostcommand
                cmd: "
                    let fzf_ctrl_t_command = \"fd --type=file | fzf --preview 'bat --color=always --style=full --line-range=:500 {}'\";
                    let result = nu -c $fzf_ctrl_t_command;
                    commandline edit --append $result;
                    commandline set-cursor --end
                "
            }
        ]
    }
]

$env.config.keybindings ++= [
    {
        name: "working_dirs_cd_menu"
        modifier: alt_shift
        keycode: char_r
        mode: emacs
        event: { send: menu name: working_dirs_cd_menu}
    }
]
