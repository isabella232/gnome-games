// This file is part of GNOME Games. License: GPL-3.0+

public interface Games.Core : Object {
	public abstract Firmware[] get_all_firmware (Platform platform) throws Error;
}
