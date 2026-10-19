if status is-interactive
    # No "Welcome to fish" message
    set -g fish_greeting

    # fastfetch when a new Alacritty or Kitty window opens (config: ~/.config/fastfetch/config.jsonc).
    # FETCH_SHOWN is exported, so shells started inside that window skip it.
    if begin; set -q ALACRITTY_WINDOW_ID; or set -q KITTY_WINDOW_ID; end
            and not set -q FETCH_SHOWN; and type -q fastfetch
        set -gx FETCH_SHOWN 1
        fastfetch
    end

    # Prompt: Starship, coloured by Noctalia's palette in ~/.config/starship.toml
    type -q starship; and starship init fish | source

    # zoxide: "z foo" jumps to the most used folder matching foo, "zi" picks with fzf
    type -q zoxide; and zoxide init fish | source

    # fzf (and fzf.fish: Ctrl+R history, Ctrl+Alt+F files, Ctrl+Alt+L git log)
    # uses the terminal's 16 ANSI colours, so it follows Noctalia via Alacritty
    set -gx FZF_DEFAULT_OPTS "--color=16 --height=40% --layout=reverse --border=rounded --info=inline"

    # bat: "ansi" theme = terminal colours (Noctalia); also used for fzf.fish previews
    set -gx BAT_THEME ansi

    # eza/bat instead of ls/cat (abbreviations expand when you press space)
    abbr -a ls eza --icons --group-directories-first
    abbr -a ll eza -l --icons --git --group-directories-first
    abbr -a la eza -la --icons --git --group-directories-first
    abbr -a lt eza --tree --level=2 --icons
    abbr -a cat bat --paging=never
end
