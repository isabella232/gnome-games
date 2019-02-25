// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-plugins-item.ui")]
private class Games.PreferencesPagePluginsItem : Gtk.Box {
	[GtkChild]
	private Gtk.Label plugin_name;
	[GtkChild]
	private Gtk.Label plugin_description;

	public PluginRegistrar plugin_registrar {
		construct {
			plugin_name.label = value.name;
			plugin_description.label = value.description;
		}
	}

	public PreferencesPagePluginsItem (PluginRegistrar plugin_registrar) {
		Object (plugin_registrar: plugin_registrar);
	}
}
