# The Homebrew formula for Algol-24.
#
# Lives here so it is versioned with the thing it packages; the tap that serves
# it is a separate repository, github.com/schildawg/homebrew-algol24, whose
# Formula/algol24.rb is a copy of this file with the url and sha256 for the
# release being published.
#
# ⚠️ THE DEPENDENCY IS LINUX-ONLY, and the asymmetry is the operating system's.
# A --ffi build links the foreign-call library; macOS ships one in /usr/lib, so
# a mac bottle needs nothing beyond the OS, and Linux has to be told.  That is
# the only thing the two platforms do not share here.
#
# ⚠️ Naming that library in the ordinary way inside a COMMENT fails
# 'brew style': the audit reads it as a dependency someone commented out.  It
# is named for real below, where it belongs.
class Algol24 < Formula
  desc "Retro-modern, gradually typed, self-hosting language"
  homepage "https://github.com/schildawg/algol24"
  url "https://github.com/schildawg/algol24/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "74725884c4ab13469e9091501dcfa181195642b3666f26fc20e48361c6b4d7cd"
  license "MIT"
  head "https://github.com/schildawg/algol24.git", branch: "main"

  bottle do
    root_url "https://github.com/schildawg/homebrew-algol24/releases/download/algol24-0.4.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "e72c0f4a29975bc4d87ce7977daaf2aaa8e410c76bed4e85ae87ad72beb31b66"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "15fe396c63238ab67c9cf87490381ece868e03c15d7b0ea7b3fed0a51e6ff044"
    sha256 cellar: :any,                 x86_64_linux:  "275e72d6bd7408a62080a476bcf74b9fd6a2818d101c0346954a5ffbf40beac9"
  end

  on_linux do
    depends_on "libffi"
  end

  def install
    # Foreign calls are part of the language, so the packaged build has them.
    # The bootstrap stays buildable with a C compiler and nothing else -- that
    # is what ./bootstrap/build.sh with no argument is for.
    system "./bootstrap/build.sh", "--ffi"

    # ⚠️ INTO libexec, WITH THE RUNTIME BESIDE IT.  'algc --compile' copies
    # algol.c and algol.h into the directory it emits, so that the result
    # compiles on its own -- and it finds them beside the executable.
    libexec.install "bootstrap/algc"
    libexec.install "bootstrap/algol.c", "bootstrap/algol.h"

    # ⚠️ A wrapper rather than a symlink.  The runtime resolves argv[0] to a
    # real path, so a symlink would work too -- this is belt and braces, and
    # costs one line.
    (bin/"algc").write <<~SHELL
      #!/bin/sh
      exec "#{libexec}/algc" "$@"
    SHELL

    doc.install "README.md", "spec/ALGOL-24.md", "spec/LIBRARY.md"
    pkgshare.install "examples"
  end

  test do
    assert_match "algc", shell_output("#{bin}/algc --version")

    (testpath/"hello.a24").write "WriteLn ('hello, ' + Str (2 + 2));\n"
    assert_equal "hello, 4\n", shell_output("#{bin}/algc hello.a24")

    # ⚠️ ErrorLn [RT-030] must not reach STANDARD OUTPUT, which is the whole of
    # what it is for: a diagnostic has to survive `prog > results.txt` without
    # corrupting what the program produced.  shell_output captures stdout only,
    # so stdout holding the FIRST line and nothing else is the assertion.
    (testpath/"streams.a24").write <<~ALGOL
      WriteLn ('to output');
      ErrorLn ('to the error stream');
    ALGOL
    assert_equal "to output\n", shell_output("#{bin}/algc streams.a24")

    # The emitted directory must build on its own, which is the whole point of
    # shipping the runtime beside the binary.
    #
    # ⚠️ --out names a directory that must ALREADY EXIST.  algc does not create
    # it and exits 70 when it cannot write, so the mkpath is part of the test
    # rather than tidiness.
    (testpath/"build").mkpath
    system bin/"algc", "--compile", "--out=#{testpath}/build", "hello.a24"
    system ENV.cc, "-std=c11", "-O2", "-o", "#{testpath}/hello",
           *Dir["#{testpath}/build/*.c"]
    assert_equal "hello, 4\n", shell_output("#{testpath}/hello")
  end
end
