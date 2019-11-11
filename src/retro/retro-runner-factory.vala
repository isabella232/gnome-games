// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroRunnerFactory : Object, RunnerFactory {
	private RetroPlatform platform;

	public RetroRunnerFactory (RetroPlatform platform) {
		this.platform = platform;
	}

	public override Platform[] get_platforms () {
		return { platform };
	}

	public Runner? create_runner (Game game) throws Error {
		var core_source = new RetroCoreSource (platform);

		var builder = new RetroRunnerBuilder ();
		builder.core_source = core_source;
		builder.uri = game.get_uri ();
		builder.uid = game.get_uid ();
		builder.title = game.name;
		var runner = builder.to_runner ();

		return runner;
	}
}
