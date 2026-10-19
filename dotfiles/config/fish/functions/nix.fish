# "nix buildswap" / "nix buildboot" = nixos-rebuild switch / boot for the flake config;
# everything else goes to the real nix
function nix --wraps nix --description 'nix, plus "nix buildswap" (switch) and "nix buildboot" (boot)'
    switch "$argv[1]"
        case buildswap
            sudo nixos-rebuild switch --flake ~/.nixsysconf#myMachine $argv[2..-1]
        case buildboot
            sudo nixos-rebuild boot --flake ~/.nixsysconf#myMachine $argv[2..-1]
        case '*'
            command nix $argv
    end
end
