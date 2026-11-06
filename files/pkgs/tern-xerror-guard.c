/* Tern's embedded browser (WebKitGTK inside Tern's own, non-GTK X window) can make GTK ask the X
 * server for the pointer position over a window that is already gone. The server answers
 * BadWindow and GTK's default X error handler then exits the whole program: Tern vanished on a
 * click once its browser had been opened ("BadWindow (invalid Window parameter)", request
 * XInputExtension minor 40 = XIQueryPointer, in the session journal).
 *
 * Preloaded into the tern process only (the variable is cleared for its children). It wraps
 * whichever X error handler the program installs: a BadWindow from XIQueryPointer (XInput2
 * minor 40) or core QueryPointer (38) is logged and ignored; GTK already treats a failed pointer
 * query as "pointer not over this window" and carries on. Every other error goes to the
 * original handler unchanged, so GTK's error traps and real failures behave as before.
 * No libX11 link: the handler types are declared here and the real XSetErrorHandler is
 * looked up at run time. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

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

#define BAD_WINDOW 3
#define X_QUERY_POINTER 38
#define XI_QUERY_POINTER 40
#define FIRST_EXTENSION_OPCODE 128

static XErrorHandler original;

static int guarded_handler(void *display, XErrorEvent *e) {
  int pointer_query = e->request_code == X_QUERY_POINTER ||
                      (e->request_code >= FIRST_EXTENSION_OPCODE && e->minor_code == XI_QUERY_POINTER);
  if (e->error_code == BAD_WINDOW && pointer_query) {
    fprintf(stderr, "tern-xerror-guard: ignored BadWindow 0x%lx from pointer query (request %u.%u)\n",
            e->resourceid, e->request_code, e->minor_code);
    return 0;
  }
  return original ? original(display, e) : 0;
}

XErrorHandler XSetErrorHandler(XErrorHandler handler) {
  static XErrorHandler (*real)(XErrorHandler);
  if (!real) real = (XErrorHandler (*)(XErrorHandler))dlsym(RTLD_NEXT, "XSetErrorHandler");
  if (!real) return NULL;
  XErrorHandler previous_original = original;
  original = handler;
  XErrorHandler previous = real(handler ? guarded_handler : NULL);
  return previous == guarded_handler ? previous_original : previous;
}

__attribute__((constructor)) static void keep_to_this_process(void) {
  unsetenv("LD_PRELOAD");   /* WebKit helper processes and anything Tern launches don't need it */
}
