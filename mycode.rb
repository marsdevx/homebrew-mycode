class Mycode < Formula
  desc "My Python CLI tool"
  homepage "https://github.com/marsdevx/mycode"
  url "https://github.com/marsdevx/mycode/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "b0556f0e4e4c14ec10afef0e3ce3a2f10facdb1fe3e29d53b11b3926d907c5ee"
  license "MIT"

  depends_on "python@3.12"

  def install
    libexec.install "mycode.py", "create_proj.py", "parse.py"

    (bin/"mycode").write <<~EOS
      #!/bin/bash
      exec python3 "#{libexec}/mycode.py" "$@"
    EOS
    chmod 0755, bin/"mycode"
  end

  def caveats
    <<~EOS
      To enable Zsh/Bash autocompletion for 'mycode', add the following to your ~/.zshrc, ~/.bashrc:

        # Homebrew app 'mycode'
        autoload -Uz compinit bashcompinit
        compinit
        bashcompinit

        eval "$(register-python-argcomplete mycode)"

        _mycode() {
          if (( CURRENT > 2 )) &&
             [[ ${words[CURRENT-2]} == --create || ${words[CURRENT-2]} == -c ]]; then
            _files
            return
          fi

          if (( CURRENT > 1 )) &&
             [[ ${words[CURRENT-1]} == --create || ${words[CURRENT-1]} == -c ]]; then
            return
          fi

          _python_argcomplete "$@"
        }

        compdef _mycode mycode

      Then run:
        source ~/.zshrc
        source ~/.bashrc
    EOS
  end

  test do
    system "#{bin}/mycode", "--help"
  end
end