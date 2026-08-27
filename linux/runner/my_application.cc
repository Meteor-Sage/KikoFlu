#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "flutter/generated_plugin_registrant.h"
#include "floating_lyric_plugin.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Flutter already bundles the shared icon under flutter_assets. Resolve it
// from the running executable so the icon works for both debug bundles and
// relocatable release archives.
static gchar* application_icon_path() {
  g_autofree gchar* executable_path =
      g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path == nullptr) {
    return nullptr;
  }

  g_autofree gchar* executable_directory =
      g_path_get_dirname(executable_path);
  return g_build_filename(executable_directory, "data", "flutter_assets",
                          "assets", "icons", "app_icon_opaque.png", nullptr);
}

static void apply_application_icon(GtkWindow* window) {
  g_autofree gchar* icon_path = application_icon_path();
  if (icon_path == nullptr ||
      !g_file_test(icon_path, G_FILE_TEST_IS_REGULAR)) {
    g_warning("KikoFlu application icon is not available in the bundle");
    return;
  }

  g_autoptr(GError) error = nullptr;
  if (!gtk_window_set_icon_from_file(window, icon_path, &error)) {
    g_warning("Unable to set KikoFlu application icon: %s",
              error == nullptr ? "unknown error" : error->message);
    return;
  }

  // Secondary windows are created by desktop_multi_window after the main
  // window. Set the GTK default as well so they use the same application icon.
  gtk_window_set_default_icon_from_file(icon_path, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// desktop_multi_window creates its GtkWindow before its Flutter view. Select
// an RGBA visual at that point so transparent Flutter pixels remain transparent
// on composited X11 desktops as well as Wayland.
static void secondary_window_added(GtkApplication*,
                                   GtkWindow* window,
                                   gpointer) {
  apply_application_icon(window);
  GtkWidget* widget = GTK_WIDGET(window);
  if (gtk_widget_get_realized(widget)) {
    return;
  }

  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(screen);
  if (rgba_visual != nullptr) {
    gtk_widget_set_visual(widget, rgba_visual);
  }
  gtk_widget_set_app_paintable(widget, TRUE);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  apply_application_icon(window);
  g_signal_connect(application, "window-added",
                   G_CALLBACK(secondary_window_added), nullptr);

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "KikoFlu");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "KikoFlu");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  desktop_multi_window_plugin_set_window_created_callback(
      [](FlPluginRegistry* registry) {
        if (FL_IS_VIEW(registry)) {
          GdkRGBA transparent;
          gdk_rgba_parse(&transparent, "#00000000");
          fl_view_set_background_color(FL_VIEW(registry), &transparent);
        }

        floating_lyric_plugin_register_with_registry(registry);
        fl_register_plugins(registry);
      });

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
