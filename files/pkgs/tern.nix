# Tern (Stencil) from its prebuilt Linux tarball. The download needs a signed-in Stencil
# account, so Nix can't fetch it; add it to the store once with
#   nix-store --add-fixed sha256 ~/Downloads/Tern-0.9.10-linux-x86_64.tar.gz
# A single binary that loads WebKitGTK, EGL/GLES, Vulkan, xcb/Wayland, xkbcommon, PulseAudio,
# PipeWire and PAM at run time
# (dlopen), so those go on LD_LIBRARY_PATH; wrapGAppsHook3 adds the GTK/GIO environment.
{ lib, stdenv, requireFile, autoPatchelfHook, wrapGAppsHook3, makeWrapper
, webkitgtk_4_1, gtk3, glib, libGL, libxkbcommon, libpulseaudio, pam, glib-networking
, gsettings-desktop-schemas, libxcb, vulkan-loader, wayland, pipewire, glibcLocales }:

stdenv.mkDerivation rec {
  pname = "tern";
  version = "0.9.10";

  src = requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    hash = "sha256-W9eCMo3w7iMw809gxAei8CUrrG6AbmINIrdEvOrUxtU=";
    message = ''
      Tern's download needs a signed-in Stencil account (build.stencil.so, invite only).
      Download Tern-${version}-linux-x86_64.tar.gz in a browser, then run:
        nix-store --add-fixed sha256 ~/Downloads/Tern-${version}-linux-x86_64.tar.gz
    '';
  };

  nativeBuildInputs = [ autoPatchelfHook wrapGAppsHook3 makeWrapper ];
  buildInputs = [ stdenv.cc.cc.lib gtk3 glib glib-networking gsettings-desktop-schemas webkitgtk_4_1 ];

  dontWrapGApps = true;   # wrapped once below, together with the library path

  installPhase = ''
    runHook preInstall
    install -Dm755 tern $out/libexec/tern/tern
    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/libexec/tern/tern $out/bin/tern \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ webkitgtk_4_1 gtk3 glib libGL libxkbcommon libpulseaudio pam libxcb vulkan-loader wayland pipewire ]} \
      --set-default LOCALE_ARCHIVE ${glibcLocales}/lib/locale/locale-archive
  '';

  meta = {
    description = "Tern by Stencil";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    mainProgram = "tern";
  };
}
