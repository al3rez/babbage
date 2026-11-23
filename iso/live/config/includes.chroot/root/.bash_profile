# Babbage live installer: the first console runs the installer; leaving it gives a root shell
# (run babbage-install to start again)
if [ "$(tty)" = /dev/tty1 ]; then
  babbage-install
fi
