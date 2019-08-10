private class Games.SavestatesListState : Object {
	public signal void load_clicked ();
	public signal void delete_clicked ();
	public signal void on_revealer_transition_end ();

	public bool is_revealed { get; set; }
	public Savestate? selected_savestate { get; set; }
}
