// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericRunnerFactory : Object, RunnerFactory {
	public delegate Runner? CreateRunner (Game game) throws Error;

	private Platform[] platforms;
	private CreateRunner callback;

	public GenericRunnerFactory (owned CreateRunner callback) {
		this.callback = (owned) callback;
		platforms = {};
	}

	public void add_platform (Platform platform) {
		platforms += platform;
	}

	public override Platform[] get_platforms () {
		return platforms;
	}

	public Runner? create_runner (Game game) throws Error {
		return callback (game);
	}
}
