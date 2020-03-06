// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.SnapshotManager : Object {
	private Game game;
	private string core_id;

	private Savestate[] snapshots;

	public SnapshotManager (Game game, string core_id) throws Error {
		this.game = game;
		this.core_id = core_id;

		var dir_path = get_snapshots_dir ();
		var dir_file = File.new_for_path (dir_path);

		if (!dir_file.query_exists ()) {
			dir_file.make_directory_with_parents ();

			snapshots = {};
			return;
		}

		var dir = Dir.open (dir_path);

		snapshots = {};
		string snapshot_name = null;

		while ((snapshot_name = dir.read_name ()) != null) {
			var snapshot_path = Path.build_filename (dir_path, snapshot_name);
			snapshots += Savestate.load (game.platform, core_id, snapshot_path);
		}

		qsort_with_data (snapshots, sizeof (Savestate), Savestate.compare);
	}

	private string get_snapshots_dir () throws Error {
		var uid = game.uid;
		var core_id_prefix = core_id.replace (".libretro", "");

		return Path.build_filename (Application.get_data_dir (),
		                            "savestates",
		                            @"$uid-$core_id_prefix");
	}

	public Savestate[] get_snapshots () {
		return snapshots;
	}
}
