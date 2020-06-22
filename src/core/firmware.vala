// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Firmware : Object {
	public abstract bool get_is_mandatory ();

	public abstract void check_is_valid (Platform platform) throws FirmwareError;
}
