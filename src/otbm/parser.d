/**
 * Authors: Mariusz 'shd' Gliwiński.
 * License: GNU Lesser General Public License
 */
module otbm.parser;

public {
	import std.typecons : Nullable, Tuple;
}
private {
	import std.conv : text;
//	import std.variant;
	import std.exception : Exception;
}

alias Tuple!(uint, "major", uint, "minor") Version;

/**
 General file-version
 */
alias Version VersionGeneral;

/**
 Specific file-version
 */
alias Version VersionFormat;
		
		
/**
 Checks whether otbm file format version is supported by library (it's not a map version)
 TODO: refactor
 */
bool isSupported(Version otbm)
{
	return otbm.major == 0;
}

/**
 Checks whether map version supported by library (it's not an otbm version)
 TODO: refactor
 */
bool isSupported(Nullable!Version map, Nullable!Version item)
{
	if (!map.isNull)
	{
		if (map.major <= 0 || map.major > 2)
			return false;
	}
	if (!item.isNull)
	{
		if (item.major < 3 || item.minor < 8 || item.minor == 16)
			return false;
	}
	return true;
}

immutable NODE_START	= 0xfe;
immutable NODE_END		= 0xff;
immutable NODE_ESCAPE	= 0xfd;

public:
// Exceptions
class ExceptionOTBM : Exception
{
	this(string msg, string file, size_t line)
	{
		super("libotbm: "~msg, file, line);
	}
}

class OTBMVersionNotSupported : ExceptionOTBM {
	this(string msg, string file, size_t line)
	{
		super("OTBM version isn't supported. Try using the latest map editor version to be able to load correctly. "
			~msg, file, line);
	}
}

class MapVersionNotSupported : ExceptionOTBM {
	this(string msg, string file, size_t line)
	{
		super("Map version isn't supported. Try using the latest map editor version to be able to load correctly. "
			~msg, file, line);
	}
}

class MapFormatBroken : ExceptionOTBM {
	this(string msg, string file, size_t line)
	{
		super("File format is broken. Try recover previous version or fix it manually. "
			~msg, file, line);
	}
}
