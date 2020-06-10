// This file is part of GNOME Games. License: GPL-3.0+

public interface Games.Core : Object {
	public abstract string[] get_all_firmware (Platform platform) throws Error;

	public abstract bool has_firmware_md5 (string firmware) throws Error;

	public abstract bool has_firmware_sha512 (string firmware) throws Error;

	public abstract string? get_firmware_md5 (string firmware) throws Error;

	public abstract string? get_firmware_sha512 (string firmware) throws Error;

	public abstract bool get_is_firmware_mandatory (string firmware) throws Error;

	public abstract string? get_firmware_path (string firmware) throws Error;
}
