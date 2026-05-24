if (which fzf | is-not-empty) {
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
                      let line = (commandline)
                      let cursor = (commandline get-cursor)
                      let before = if $cursor == 0 { '' } else { $line | str substring 0..($cursor - 1) }
                      let after = if $cursor >= ($line | str length) { '' } else { $line | str substring $cursor..-1 }
                      let token = ($before | str replace --regex '^.*\\s' '')
                      let prefix_len = (($before | str length) - ($token | str length))
                      let prefix = if $prefix_len == 0 { '' } else { $before | str substring 0..($prefix_len - 1) }
                      let script = ($env.HOME | path join '.local' 'scripts' 'fzf-path-widget')
                      let fzf = (^$script $token | complete)
                      let result = ($fzf.stdout | lines | str join ' ')

                      if $fzf.exit_code == 0 and ($result | is-not-empty) {
                          commandline edit --replace $'($prefix)($result)($after)'
                          commandline set-cursor (($prefix | str length) + ($result | str length))
                      }
                  "
              }
          ]
      }
  ]
}

$env.config.keybindings ++= [
    {
        name: tmux_sessions
        modifier: alt
        keycode: char_s
        mode: [emacs, vi_normal, vi_insert]
        event: [
            {
                send: executehostcommand
                cmd: "
                    let script = ($env.HOME | path join '.local' 'scripts' 'tmux-session-fzf')
                    run-external $script
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
