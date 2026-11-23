{ pkgs, config, desk, ... }:

# LINE has no Linux app and no web version; its official desktop client for Linux is the LINE
# Chrome extension. It runs here in a Chromium app window with its own profile and window
# class (like WhatsApp and DeepSeek Harness), so the pin finds this window. Chromium installs
# the extension from the Chrome Web Store into that profile by itself (External Extensions).
let
  id = "ophjlpahpchlmihnnnihgmmeilfjmjjc";   # LINE in the Chrome Web Store
  profile = "${config.xdg.dataHome}/line-app";
  chromium = "${desk.chromium}/bin/chromium --user-data-dir=${profile} --class=LINE --no-first-run --no-default-browser-check";
  open = pkgs.writeShellScript "line-open" ''
    # First run: the extension isn't installed yet, and opening its page fails with
    # ERR_BLOCKED_BY_CLIENT until Chromium restarts with it installed. So open a placeholder
    # window (Chromium quits with no window open, before it installs anything), wait for the
    # install, quit it cleanly (it saves the install), then open LINE.
    if [ ! -d "${profile}/Default/Extensions/${id}" ]; then
      ${chromium} --app="data:text/html,<title>LINE</title><body style='margin:0;height:100vh;display:grid;place-items:center;font:16px sans-serif;color:%2306c755'>Installing LINE…</body>" &
      pid=$!
      for _ in $(seq 240); do
        [ -d "${profile}/Default/Extensions/${id}" ] && break
        sleep 0.5
      done
      sleep 3
      kill -TERM "$pid"
      wait "$pid"
    fi
    exec ${chromium} --app=chrome-extension://${id}/index.html
  '';
in
{
  xdg.dataFile."line-app/External Extensions/${id}.json".text =
    builtins.toJSON { external_update_url = "https://clients2.google.com/service/update2/crx"; };

  xdg.dataFile."applications/line.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=LINE
    Comment=LINE messenger (its Chrome extension) in its own window
    Exec=${open}
    Icon=line-mac
    StartupWMClass=LINE
    Terminal=false
    Categories=Network;InstantMessaging;
  '';
}
