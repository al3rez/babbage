{ lib, ... }:

{
  # minimal prompt: dir, git branch, venv, exit code, duration, ❯
  xdg.configFile."bash/prompt.sh".source = ../files/bash/prompt.sh;

  # keep Debian's ~/.bashrc and just make sure it loads the prompt
  home.activation.bashPrompt = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.bashrc" ] && ! grep -q 'config/bash/prompt.sh' "$HOME/.bashrc"; then
      run printf '\n# custom prompt\n[ -f ~/.config/bash/prompt.sh ] && . ~/.config/bash/prompt.sh\n' >> "$HOME/.bashrc"
    fi
  '';
}
