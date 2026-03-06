set shell := ["bash", "-euo", "pipefail", "-c"]

default_prefix := env_var_or_default("HOME", "") + "/.local"
scripts := "brsync.sh git-rm-branches.sh mkwt.sh prlog.sh prsync.sh rmwt.sh"

install prefix=default_prefix symlink="false":
    @bin_dir="{{prefix}}/bin"; \
    mkdir -p "$bin_dir"; \
    for script in {{scripts}}; do \
      src="$(pwd)/$script"; \
      dst="$bin_dir/$script"; \
      if [ "{{symlink}}" = "1" ] || [ "{{symlink}}" = "true" ] || [ "{{symlink}}" = "yes" ]; then \
        ln -sfn "$src" "$dst"; \
        echo "Symlinked $dst -> $src"; \
      else \
        install -m 0755 "$src" "$dst"; \
        echo "Installed $dst"; \
      fi; \
    done
