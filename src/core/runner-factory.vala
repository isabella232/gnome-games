// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.RunnerFactory : Object {
	public virtual Platform[] get_platforms () {
		return {};
	}

	public abstract Runner? create_runner (Game game) throws Error;
}
