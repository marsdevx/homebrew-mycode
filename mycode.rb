class Mycode < Formula
  desc "My Python CLI tool"
  homepage "https://github.com/marsdevx/mycode"
  url "https://github.com/marsdevx/mycode/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "f2091f915ebd2c793b85f27449729481332d66f6d921ab1aedda05bfad99907c"
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