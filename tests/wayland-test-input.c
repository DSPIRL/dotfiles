// Private virtual KWin only; the runner builds the protocol bindings in /tmp.
#include <linux/input-event-codes.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "fake-input-client.h"

static struct org_kde_kwin_fake_input *input;
static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version) {
    (void)data;
    if (!strcmp(interface, "org_kde_kwin_fake_input") && version >= 4)
        input = wl_registry_bind(registry, name, &org_kde_kwin_fake_input_interface, 4);
}
static void removed(void *data, struct wl_registry *registry, uint32_t name) {
    (void)data; (void)registry; (void)name;
}
int main(int argc, char **argv) {
    const char *socket = getenv("WAYLAND_DISPLAY");
    if (!socket || strcmp(socket, "surface-test")) return 2;
    if (!((argc == 4 && !strcmp(argv[1], "click")) ||
          (argc == 3 && !strcmp(argv[1], "key")))) return 2;
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) return 3;
    struct wl_registry *registry = wl_display_get_registry(display);
    const struct wl_registry_listener listener = {global, removed};
    wl_registry_add_listener(registry, &listener, NULL);
    if (wl_display_roundtrip(display) < 0 || !input) return 4;
    org_kde_kwin_fake_input_authenticate(input, "surface geometry test", "private virtual compositor only");
    if (argc == 4) {
        org_kde_kwin_fake_input_pointer_motion_absolute(input,
            wl_fixed_from_int(atoi(argv[2])), wl_fixed_from_int(atoi(argv[3])));
        wl_display_roundtrip(display);
        usleep(50000);
        org_kde_kwin_fake_input_button(input, BTN_LEFT, 1);
    } else {
        org_kde_kwin_fake_input_keyboard_key(input, atoi(argv[2]), 1);
    }
    wl_display_roundtrip(display);
    usleep(50000);
    if (argc == 4) org_kde_kwin_fake_input_button(input, BTN_LEFT, 0);
    else org_kde_kwin_fake_input_keyboard_key(input, atoi(argv[2]), 0);
    int result = wl_display_roundtrip(display) < 0;
    wl_display_disconnect(display);
    return result;
}
