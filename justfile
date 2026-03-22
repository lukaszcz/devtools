set shell := ["bash", "-euo", "pipefail", "-c"]

default_prefix := env_var_or_default("HOME", "") + "/.local"
prefix := default_prefix
symlink := "false"
scripts := "brsync.sh cpconfig.sh git-rm-branches.sh mkwt.sh prlog.sh prsync.sh rmwt.sh tmux-4.sh pm.sh sandbox.sh"

install p=prefix s=symlink:
    @bin_dir="{{p}}/bin"; \
    sandbox_dir="$HOME/.sandbox"; \
    mkdir -p "$bin_dir"; \
    mkdir -p "$sandbox_dir"; \
    for script in {{scripts}}; do \
      src="{{justfile_directory()}}/scripts/$script"; \
      dst="$bin_dir/$script"; \
      if [ "{{s}}" = "1" ] || [ "{{s}}" = "true" ] || [ "{{s}}" = "yes" ]; then \
        ln -sfn "$src" "$dst"; \
        echo "Symlinked $dst -> $src"; \
      else \
        install -m 0755 "$src" "$dst"; \
        echo "Installed $dst"; \
      fi; \
    done; \
    sandbox_src="{{justfile_directory()}}/sandbox/default.json"; \
    sandbox_dst="$sandbox_dir/default.json"; \
    if [ "{{s}}" = "1" ] || [ "{{s}}" = "true" ] || [ "{{s}}" = "yes" ]; then \
      ln -sfn "$sandbox_src" "$sandbox_dst"; \
      echo "Symlinked $sandbox_dst -> $sandbox_src"; \
    else \
      install -m 0644 "$sandbox_src" "$sandbox_dst"; \
      echo "Installed $sandbox_dst"; \
    fi
