# DeepSeek Harness (github.com/deepseek-ai/deepseek-harness), developer preview: `dsh` runs the
# pinned npm release; npx caches it in ~/.npm/_npx on first run. It needs Node >= 24.9 and
# nodejs.org's own build: its native loader disassembles node's internals and rejects nixpkgs'
# build ("x64 sysv getter is not a recognized this->field accessor"). The binary is used
# unpatched (code bytes must stay as shipped) with Debian's loader; Debian's nodejs is too old.
{ stdenvNoCC, fetchurl, writeShellScriptBin }:

let
  version = "0.2.2-rc.1";
  node = stdenvNoCC.mkDerivation rec {
    pname = "nodejs-official";
    version = "24.21.0";
    src = fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz";
      hash = "sha256-/Y5Z1aURUQ9qKYr7VI8Yx9KxvkBNi0on2U++SfVsstY=";   # SHASUMS256.txt
    };
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = "cp -r . $out";
  };
in
writeShellScriptBin "dsh" ''
  export PATH=${node}/bin:$PATH
  exec npx --yes @deepseek-ai/dsh@${version} "$@"
''
