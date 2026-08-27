#include "floating_lyric_plugin.h"

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
  return fl_value_ref(result);
}

static FlMethodResponse* configure_window(FloatingLyricPlugin* self) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unavailable", "Unable to resolve the GTK window", nullptr));
  }

  GtkWidget* widget = GTK_WIDGET(window);
  gtk_widget_set_app_paintable(widget, TRUE);
  gtk_window_set_decorated(window, FALSE);
  gtk_window_set_keep_above(window, TRUE);
  gtk_window_set_skip_taskbar_hint(window, TRUE);
  gtk_window_set_skip_pager_hint(window, TRUE);
  gtk_window_stick(window);

  GdkWindow* gdk_window = gtk_widget_get_window(widget);
  if (gdk_window != nullptr) {
    gdk_window_set_opaque_region(gdk_window, nullptr);
  }

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(build_capabilities(window)));
}

static FlMethodResponse* set_ignore_mouse_events(FloatingLyricPlugin* self,
                                                  FlValue* args) {
  GtkWindow* window = get_window(self);
  if (window == nullptr) {
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
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "window_unrealized", "The GTK window is not realized", nullptr));
  }

  set_widget_pass_through(GTK_WIDGET(window), ignore);
  gtk_window_set_accept_focus(window, !ignore);

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

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.kikoeru.flutter/floating_lyric_linux", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
