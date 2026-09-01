# homebrew-algol24

The Homebrew tap for [Algol-24](https://github.com/schildawg/algol24) — a
retro-modern language with classic syntax over unbounded integers, full
Unicode, gradual types, closures and a foreign function interface, whose
compiler is written in Algol-24 and compiles itself.

```sh
brew tap schildawg/algol24
brew install algol24
```

```sh
algc --version
echo "WriteLn ('hello, ' + Str (2 + 2));" > hello.a24
algc hello.a24
```

The formula builds with foreign calls enabled and links against the libffi
macOS ships, so it needs nothing beyond the operating system. The specification
and the language reference are installed alongside it, and the examples land in
the tap's share directory.

Formulae here are generated from `packaging/` in the main repository, which is
where changes belong.
