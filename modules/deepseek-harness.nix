{ pkgs, desk, ... }:

# DeepSeek Harness as a desktop app: `dsh web` runs as a user service (started on demand by the
# pinned launcher, then left running), and its Web UI opens in a Chromium app window with its
# own profile and window class, so the pin finds this window and not WhatsApp's or Chrome's.
# The server's access token is new on every start and only printed, so the launcher reads the
# URL the running service printed and opens that; Chromium keeps the session cookie after.
let
  open = pkgs.writeShellScript "deepseek-harness-open" ''
    set -u
    unit=dsh-web.service
    systemctl --user start "$unit" || exit 1
    url=
    for _ in $(seq 150); do      # up to ~30s: the first run downloads the npm release
      id=$(systemctl --user show -p InvocationID --value "$unit")
      url=$(journalctl --user -q -o cat "_SYSTEMD_INVOCATION_ID=$id" 2>/dev/null \
        | grep -o 'http://127\.0\.0\.1:3080/?token=[A-Za-z0-9_-]*' | tail -n 1)
      [ -n "$url" ] && break
      sleep 0.2
    done
    if [ -z "$url" ]; then
      ${pkgs.libnotify}/bin/notify-send -a "DeepSeek Harness" "DeepSeek Harness didn't start" \
        "journalctl --user -u $unit"
      exit 1
    fi
    exec ${desk.chromium}/bin/chromium --user-data-dir="$HOME/.local/share/deepseek-harness-app" \
      --class=DeepSeek --no-first-run --no-default-browser-check --app="$url"
  '';
in
{
  systemd.user.services.dsh-web = {
    Unit.Description = "DeepSeek Harness Web UI (dsh web) on 127.0.0.1:3080";
    Service = {
      ExecStart = "${desk.dsh}/bin/dsh web --no-open";
      WorkingDirectory = "%h";
      Restart = "on-failure";
      RestartSec = "3";
    };
  };

  xdg.dataFile."applications/deepseek-harness.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DeepSeek Harness
    Comment=DeepSeek's agent harness (Web UI) in its own window
    Exec=${open}
    Icon=deepseek-mac
    StartupWMClass=DeepSeek
    Terminal=false
    Categories=Development;
  '';
}
