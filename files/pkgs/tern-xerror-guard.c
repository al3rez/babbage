/* Tern's embedded browser (WebKitGTK inside Tern's own, non-GTK X window) makes GTK ask the X
 * server for the pointer position over a window that is already gone, when Tern's window gets
 * focus (gtk_window_focus_in_event -> gdk_x11_device_xi2_query_state -> XIQueryPointer). The
 * server answers BadWindow and whatever X error handler is installed at that moment ends the
 * program: GTK's prints "BadWindow (invalid Window parameter) ... XInputExtension minor 40" and
 * exits; Xlib's default one calls exit() from inside the X reply, where NVIDIA's EGL exit handler
 * then waits forever on the X lock the same thread holds (Tern freezes, ignores Super+Q).
 *
 * Preloaded into the tern process only (the variable is cleared for its children). It wraps
 * XIQueryPointer itself: for the duration of that one round trip a handler ignores a BadWindow
 * caused by it (logged), and passes every other error to the handler that was installed, which
 * is put back afterwards. XIQueryPointer then just returns False, which GTK already handles as
 * "pointer not over this window". Nothing else in the process changes. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

typedef unsigned long Window;
typedef struct {
  int type;
  void *display;
  unsigned long resourceid;
  unsigned long serial;
  unsigned char error_code;
  unsigned char request_code;
  unsigned char minor_code;
} XErrorEvent;
typedef int (*XErrorHandler)(void *display, XErrorEvent *event);
typedef int (*QueryPointer)(void *, int, Window, Window *, Window *, double *, double *, double *,
                            double *, void *, void *, void *);

#define BAD_WINDOW 3
#define XI_QUERY_POINTER 40
#define FIRST_EXTENSION_OPCODE 128

static XErrorHandler outer;   /* the handler that was installed when the query started */

static int during_query(void *display, XErrorEvent *e) {
  if (e->error_code == BAD_WINDOW && e->request_code >= FIRST_EXTENSION_OPCODE &&
      e->minor_code == XI_QUERY_POINTER) {
    fprintf(stderr, "tern-xerror-guard: ignored BadWindow 0x%lx from XIQueryPointer\n", e->resourceid);
    return 0;
  }
  return outer ? outer(display, e) : 0;
}

int XIQueryPointer(void *display, int deviceid, Window win, Window *root, Window *child,
                   double *root_x, double *root_y, double *win_x, double *win_y,
                   void *buttons, void *mods, void *group) {
  static QueryPointer real;
  static XErrorHandler (*set_handler)(XErrorHandler);
  if (!real) real = (QueryPointer)dlsym(RTLD_NEXT, "XIQueryPointer");
  if (!set_handler) set_handler = (XErrorHandler (*)(XErrorHandler))dlsym(RTLD_DEFAULT, "XSetErrorHandler");
  if (!real) return 0;
  if (!set_handler)
    return real(display, deviceid, win, root, child, root_x, root_y, win_x, win_y, buttons, mods, group);
  XErrorHandler saved_outer = outer;   /* GTK's main loop is single-threaded; keep nesting safe */
  outer = set_handler(during_query);
  int ok = real(display, deviceid, win, root, child, root_x, root_y, win_x, win_y, buttons, mods, group);
  set_handler(outer);
  outer = saved_outer;
  return ok;
}

__attribute__((constructor)) static void keep_to_this_process(void) {
  unsetenv("LD_PRELOAD");   /* WebKit helper processes and anything Tern launches don't need it */
}
