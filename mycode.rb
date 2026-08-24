class Mycode < Formula
  include Language::Python::Virtualenv

  desc "My Python CLI tool"
  homepage "https://github.com/marsdevx/mycode"
  url "https://github.com/marsdevx/mycode/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "a0ec995d9dfa273390ce3e10285755e9fa109c8ccc2f10e7f99758de915fa2c7"
  license "MIT"

  depends_on "python@3.12"

  resource "argcomplete" do
    url "https://files.pythonhosted.org/packages/95/c0/c8e94135e66fabf89a120d9b4b123fe6993506beca6c1938a74c24cfa5fd/argcomplete-3.7.0.tar.gz"
    sha256 "afde224f753f874807b1dc1414e883ab8fe0cda9c04807b6047dcb8e1ac23913"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/ac/c3/e2a2b89f2d3e2179abd6d00ebd70bff6273f37fb3e0cc209f48b39d00cbf/requests-2.34.2.tar.gz"
    sha256 "f288924cae4e29463698d6d60bc6a4da69c89185ad1e0bcc4104f584e960b9ed"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/a3/c2/24167ea9858356b47a87a50d39908bfdb72ceeefe0041586e704e5376b3a/certifi-2026.7.22.tar.gz"
    sha256 "741e2c3b351ddf169a738da9f2c048608ff7f2c5cc02f1ebc6b118bb090d5d55"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/bd/2a/23f34ec9d04624958e137efdc394888716353190e75f25dd22c7a2c7a8aa/charset_normalizer-3.4.9.tar.gz"
    sha256 "673611bbd43f0810bec0b0f028ddeaaa501190339cac411f347ac76917c3ae7b"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/cd/63/9496c57188a2ee585e0f1db071d75089a11e98aa86eb99d9d7618fc1edce/idna-3.18.tar.gz"
    sha256 "ffb385a7e039654cef1ab9ef32c6fafe283c0c0467bba1d9029738ce4a14a848"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/53/0c/06f8b233b8fd13b9e5ee11424ef85419ba0d8ba0b3138bf360be2ff56953/urllib3-2.7.0.tar.gz"
    sha256 "231e0ec3b63ceb14667c67be60f2f2c40a518cb38b03af60abc813da26505f4c"
  end

  def install
    # Dependencies live in a private virtualenv rather than relying on whatever
    # `python3` happens to be first on the user's PATH.
    venv = virtualenv_create(libexec/"venv", "python3.12")
    venv.pip_install resources

    libexec.install "mycode.py", "create_proj.py", "parse.py"

    # Pin the interpreter explicitly. A bare `python3` here resolves through the
    # user's PATH, which may be a pyenv or framework build without these deps.
    (bin/"mycode").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/venv/bin/python" "#{libexec}/mycode.py" "$@"
    EOS
    chmod 0755, bin/"mycode"

    generate_completions
  end

  # argcomplete ships the shell-side completion driver, but only as something you
  # generate at runtime via `register-python-argcomplete`. Generate it at build
  # time instead so the installed completion is self-contained: no dependency on
  # argcomplete being installed globally, and no subprocess on every shell start.
  def generate_completions
    script = Utils.safe_popen_read(libexec/"venv/bin/register-python-argcomplete", "mycode")

    # Bash gets argcomplete's script verbatim -- it already ends by registering
    # itself with `complete`.
    (bash_completion/"mycode").write script

    # Zsh needs the custom wrapper below, so keep argcomplete's function
    # definitions and drop the registration block it appends after them.
    marker = "\nif [[ -z \"${ZSH_VERSION-}\" ]]; then"
    odie "argcomplete's generated script changed shape; update generate_completions" unless script.include?(marker)
    functions = script.split(marker).first

    # Zsh filters argcomplete's candidates a second time, and that pass is
    # case-sensitive -- `mycode home<TAB>` would drop "HomeLab" even though
    # mycode itself already offered it. A per-command `matcher-list` zstyle
    # cannot fix that: the style is read before the command is known, so the
    # only form that takes effect would change matching for every command the
    # user completes. Reimplement `_python_argcomplete`'s zsh branch instead
    # and hand the match spec straight to compadd via -M.
    #
    # Single-quoted heredoc on purpose: the body is zsh, and Ruby would
    # otherwise eat the backslashes in `$'\013'` and the line continuations.
    wrapper = <<~'ZSH'
      _mycode_argcomplete() {
        local IFS=$'\013'
        local -a completions nosort nospace
        completions=($(IFS="$IFS" \
            COMP_LINE="$BUFFER" \
            COMP_POINT="$CURSOR" \
            _ARGCOMPLETE=1 \
            _ARGCOMPLETE_SHELL="zsh" \
            _ARGCOMPLETE_SUPPRESS_SPACE=1 \
            __python_argcomplete_run "${words[1]}"))
        if is-at-least 5.8; then
          nosort=(-o nosort)
        fi
        if [[ "${completions-}" =~ ([^\\]): && "${match[1]}" =~ [=/:] ]]; then
          nospace=(-S '')
        fi
        _describe "${words[1]}" completions "${nosort[@]}" "${nospace[@]}" \
            -M 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
      }

      _mycode() {
        # `-c <project_name> <target_dir>`: the name is freeform, the target is a path.
        if (( CURRENT > 2 )) &&
            [[ ${words[CURRENT-2]} == --create || ${words[CURRENT-2]} == -c ]]; then
          _files
          return
        fi

        if (( CURRENT > 1 )) &&
            [[ ${words[CURRENT-1]} == --create || ${words[CURRENT-1]} == -c ]]; then
          return
        fi

        _mycode_argcomplete "$@"
      }

      _mycode "$@"
    ZSH

    (zsh_completion/"_mycode").write <<~ZSH
      #compdef mycode
      autoload -Uz is-at-least
      #{functions}
      #{wrapper}
    ZSH
  end

  def caveats
    <<~EOS
      Completion is installed automatically. It only needs the completion system
      initialized in your ~/.zshrc:

        autoload -Uz compinit
        compinit

      No `register-python-argcomplete` line and no hand-written `_mycode` function
      are needed any more. If you added those for an earlier version, remove them.
    EOS
  end

  test do
    assert_match "mycode", shell_output("#{bin}/mycode --help")
    # Dependencies must resolve from the bundled venv, not the ambient PATH.
    system libexec/"venv/bin/python", "-c", "import argcomplete, requests"
  end
end
