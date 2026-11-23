/* Preloaded into xfce4-clipman (modules/clipman.nix): keeps its tray icon (a GtkStatusIcon)
 * invisible, so it never docks in the tray. The bar's clipboard glyph is files/bin/menubar-popovers'
 * instead (resizable by files/bin/bar-icons); it opens Clipman's menu with xfce4-popup-clipman.
 * Clipman has no setting for this, and the tray can't hide its icon by name (Clipman titles it
 * only after it docks). Only these two GTK calls are wrapped; types are opaque here. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdlib.h>

/* apps Clipman starts (its actions) shouldn't inherit this */
__attribute__((constructor)) static void forget_preload(void) {
    unsetenv("LD_PRELOAD");
}

typedef void *(*new_fn)(const char *);
typedef void (*visible_fn)(void *, int);

static visible_fn real_set_visible(void) {
    static visible_fn fn;
    if (!fn)
        fn = (visible_fn)dlsym(RTLD_NEXT, "gtk_status_icon_set_visible");
    return fn;
}

void gtk_status_icon_set_visible(void *icon, int visible) {
    (void)visible;
    real_set_visible()(icon, 0);
}

void *gtk_status_icon_new_from_icon_name(const char *name) {
    static new_fn real;
    if (!real)
        real = (new_fn)dlsym(RTLD_NEXT, "gtk_status_icon_new_from_icon_name");
    void *icon = real(name);
    real_set_visible()(icon, 0);
    return icon;
}
