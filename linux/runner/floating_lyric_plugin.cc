#include "floating_lyric_plugin.h"

#include <stdio.h>
#include <time.h>
#include <unistd.h>

#include <gtk/gtk.h>

#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#define FLOATING_LYRIC_PLUGIN(obj)                                    \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), floating_lyric_plugin_get_type(), \
                              FloatingLyricPlugin))

struct _FloatingLyricPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
};

G_DEFINE_TYPE(FloatingLyricPlugin,
              floating_lyric_plugin,
              g_object_get_type())

static GtkWindow* get_window(FloatingLyricPlugin* self) {
  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  if (view == nullptr) {
    return nullptr;
  }

  GtkWidget* window = gtk_widget_get_toplevel(GTK_WIDGET(view));
  return GTK_IS_WINDOW(window) ? GTK_WINDOW(window) : nullptr;
}

// Keep lifecycle diagnostics outside Flutter's in-memory log screen. These
// events are intentionally limited to window operations, so this file is not
// touched by the lyric update loop.
static gchar* diagnostic_log_path() {
  return g_build_filename(g_get_user_data_dir(), "KikoFlu", "logs",
                          "floating_lyric_linux.log", nullptr);
}

static void write_diagnostic(const gchar* event,
                             const gchar* details = nullptr) {
  g_autofree gchar* path = diagnostic_log_path();
  g_autofree gchar* directory = g_path_get_dirname(path);
  if (g_mkdir_with_parents(directory, 0700) != 0) {
    return;
  }

  FILE* file = fopen(path, "a");
  if (file == nullptr) {
    return;
  }

  time_t now = time(nullptr);
  struct tm local_time;
  localtime_r(&now, &local_time);
  char timestamp[32];
  strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", &local_time);
  if (details == nullptr || details[0] == '\0') {
    fprintf(file, "%s pid=%d event=%s\n", timestamp,
            static_cast<int>(getpid()), event);
  } else {
    fprintf(file, "%s pid=%d event=%s %s\n", timestamp,
            static_cast<int>(getpid()), event, details);
  }
  fflush(file);
  fsync(fileno(file));
  fclose(file);
}

static const gchar* get_backend_name(GdkDisplay* display) {
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_DISPLAY(display)) {
    return "x11";
  }
#endif
#ifdef GDK_WINDOWING_WAYLAND
  if (GDK_IS_WAYLAND_DISPLAY(display)) {
    return "wayland";
  }
#endif
  return "unknown";
}

static void set_widget_pass_through(GtkWidget* widget, gboolean pass_through) {
  GdkWindow* window = gtk_widget_get_window(widget);
  if (window != nullptr) {
    gdk_window_set_pass_through(window, pass_through);
  }

  if (GTK_IS_CONTAINER(widget)) {
    gtk_container_forall(
        GTK_CONTAINER(widget),
        [](GtkWidget* child, gpointer data) {
          const gboolean child_pass_through =
              *static_cast<const gboolean*>(data);
          set_widget_pass_through(child, child_pass_through);
        },
        &pass_through);
  }
}

static FlValue* build_capabilities(GtkWindow* window) {
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkDisplay* display = gdk_screen_get_display(screen);
  const gchar* backend = get_backend_name(display);
  GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(screen);
  GdkVisual* window_visual = gtk_widget_get_visual(GTK_WIDGET(window));

  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(result, "backend", fl_value_new_string(backend));
  fl_value_set_string_take(
      result, "supportsClickThrough",
      fl_value_new_bool(gtk_check_version(3, 18, 0) == nullptr));
  fl_value_set_string_take(
      result, "supportsTransparency",
      fl_value_new_bool(rgba_visual != nullptr &&
                        window_visual == rgba_visual &&
                        gdk_screen_is_composited(screen)));
  fl_value_set_string_take(
      result, "reliableAlwaysOnTop",
      fl_value_new_bool(g_strcmp0(backend, "x11") == 0));
  g_autofree gchar* log_path = diagnostic_log_path();
  fl_value_set_string_take(result, "diagnosticLogPath",
                           fl_value_new_string(log_path));
  return fl_value_ref(result);
}

static FlMethodResponse* configure_window(FloatingLyricPlugin* self) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    write_diagnostic("configure_window_failed", "reason=window_unavailable");
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unavailable", "Unable to resolve the GTK window", nullptr));
  }

  GtkWidget* widget = GTK_WIDGET(window);
  gtk_widget_set_app_paintable(widget, TRUE);
  gtk_window_set_decorated(window, FALSE);
  // Utility windows are treated as overlay-like by common X11 WMs and are
  // more consistently kept above normal application windows.
  gtk_window_set_type_hint(window, GDK_WINDOW_TYPE_HINT_UTILITY);
  gtk_window_set_keep_above(window, TRUE);
  gtk_window_set_skip_taskbar_hint(window, TRUE);
  gtk_window_set_skip_pager_hint(window, TRUE);
  gtk_window_stick(window);

  GdkWindow* gdk_window = gtk_widget_get_window(widget);
  if (gdk_window != nullptr) {
    gdk_window_set_opaque_region(gdk_window, nullptr);
  }

  GdkScreen* screen = gtk_window_get_screen(window);
  const gchar* backend = get_backend_name(gdk_screen_get_display(screen));
  g_autofree gchar* details =
      g_strdup_printf("backend=%s window=%p", backend, window);
  write_diagnostic("configure_window", details);

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(build_capabilities(window)));
}

static FlMethodResponse* set_ignore_mouse_events(FloatingLyricPlugin* self,
                                                  FlValue* args) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    write_diagnostic("set_ignore_mouse_events_failed",
                     "reason=window_unavailable");
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unavailable", "Unable to resolve the GTK window", nullptr));
  }

  FlValue* ignore_value =
      args == nullptr ? nullptr : fl_value_lookup_string(args, "ignore");
  if (ignore_value == nullptr ||
      fl_value_get_type(ignore_value) != FL_VALUE_TYPE_BOOL) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid_arguments", "ignore must be a boolean", nullptr));
  }

  const gboolean ignore = fl_value_get_bool(ignore_value);
  GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_window == nullptr) {
    write_diagnostic("set_ignore_mouse_events_failed",
                     "reason=window_unrealized");
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unrealized", "The GTK window is not realized", nullptr));
  }

  set_widget_pass_through(GTK_WIDGET(window), ignore);
  gtk_window_set_accept_focus(window, !ignore);
  g_autofree gchar* details =
      g_strdup_printf("ignore=%s window=%p", ignore ? "true" : "false",
                      window);
  write_diagnostic("set_ignore_mouse_events", details);

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static gboolean on_window_delete_event(GtkWidget*, GdkEvent*, gpointer data) {
  static_cast<void>(data);
  write_diagnostic("delete_event", "action=forward_to_window_manager");
  // Let window_manager's prevent-close handler receive the event. Its Dart
  // listener hides the window instead of destroying the secondary engine.
  return FALSE;
}

static FlMethodResponse* hide_window(FloatingLyricPlugin* self) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    write_diagnostic("hide_window_failed", "reason=window_unavailable");
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unavailable", "Unable to resolve the GTK window", nullptr));
  }

  // Closing a secondary engine through gtk_window_close()/destroy can trigger
  // the Flutter engine removal race reported by desktop_multi_window users.
  // Hiding keeps the engine alive and is sufficient for the floating lyric UI.
  gtk_widget_hide(GTK_WIDGET(window));
  write_diagnostic("hide_window", "result=hidden");
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(TRUE)));
}

static void floating_lyric_plugin_handle_method_call(
    FloatingLyricPlugin* self,
    FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "configureWindow") == 0) {
    response = configure_window(self);
  } else if (g_strcmp0(method, "destroyWindow") == 0 ||
             g_strcmp0(method, "hideWindow") == 0) {
    // Keep destroyWindow as a compatibility alias for older Dart code. It is
    // intentionally implemented as hide on Linux.
    response = hide_window(self);
  } else if (g_strcmp0(method, "getCapabilities") == 0) {
    GtkWindow* window = get_window(self);
    if (window == nullptr) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "window_unavailable", "Unable to resolve the GTK window", nullptr));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(build_capabilities(window)));
    }
  } else if (g_strcmp0(method, "setIgnoreMouseEvents") == 0) {
    response = set_ignore_mouse_events(self, args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void floating_lyric_plugin_dispose(GObject* object) {
  FloatingLyricPlugin* self = FLOATING_LYRIC_PLUGIN(object);
  g_clear_object(&self->registrar);
  G_OBJECT_CLASS(floating_lyric_plugin_parent_class)->dispose(object);
}

static void floating_lyric_plugin_class_init(FloatingLyricPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = floating_lyric_plugin_dispose;
}

static void floating_lyric_plugin_init(FloatingLyricPlugin*) {}

static void method_call_cb(FlMethodChannel*,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  FloatingLyricPlugin* plugin = FLOATING_LYRIC_PLUGIN(user_data);
  floating_lyric_plugin_handle_method_call(plugin, method_call);
}

void floating_lyric_plugin_register_with_registry(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) registrar =
      fl_plugin_registry_get_registrar_for_plugin(
          registry, "KikoFluFloatingLyricPlugin");
  FloatingLyricPlugin* plugin = FLOATING_LYRIC_PLUGIN(
      g_object_new(floating_lyric_plugin_get_type(), nullptr));
  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  GtkWindow* window = get_window(plugin);
  if (window != nullptr) {
    g_signal_connect(GTK_WIDGET(window), "delete-event",
                     G_CALLBACK(on_window_delete_event), plugin);
    g_autofree gchar* details = g_strdup_printf("window=%p", window);
    write_diagnostic("plugin_registered", details);
  } else {
    write_diagnostic("delete_handler_registration_failed",
                     "reason=window_unavailable");
  }

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.kikoeru.flutter/floating_lyric_linux", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
