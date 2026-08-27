#ifndef FLUTTER_FLOATING_LYRIC_PLUGIN_H_
#define FLUTTER_FLOATING_LYRIC_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

typedef struct _FloatingLyricPlugin FloatingLyricPlugin;
typedef struct {
  GObjectClass parent_class;
} FloatingLyricPluginClass;

GType floating_lyric_plugin_get_type();

void floating_lyric_plugin_register_with_registry(FlPluginRegistry* registry);

G_END_DECLS

#endif  // FLUTTER_FLOATING_LYRIC_PLUGIN_H_
