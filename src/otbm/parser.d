/**
 * Authors: Mariusz 'shd' Gliwiński.
 * License: GNU Lesser General Public License
 */
module otbm.parser;

public {
	import std.stream;
	import std.typecons : Nullable, Tuple;
}
private {
	import std.variant;
	import std.exception : enforceEx, Exception;
	import std.conv : text, to;
	import std.stdio : writeln;
	import std.bitmanip;
	import std.array;
	import std.algorithm;
}

//struct OTBMParser
//{
/**
 Version identifier type
 */
alias Tuple!(uint, "major", uint, "minor") Version;

/**
 Called after reading file header
 */
void delegate(in Version map, in ushort width, in ushort height, in Version items) onHeader;

/**
 Called with human-provided map description
 */
void delegate(in char[] description) onMapDescription;
/**
 Provides user with path to file containing spawn description.
 */
void delegate(in char[] spawn) onMapSpawnFile;
/**
 Provides user with path to file that describes houses.
 */
void delegate(in char[] houses) onMapHousesFile;

/**
 Called every time when parser will encounter town definition.
 */
void delegate(in Town) onTown;
/**
 Called every time when parser will encounter waypoint definition.
 */
void delegate(in Waypoint) onWaypoint;

/**
 Called for every map tile filled with data.
 */
void delegate(in Tile) onTile;
/**
 Called every time, that parser encounters item definition
 
 Bugs:OTBM-1 Tile, and parent here might not be fully filled with its data
 */
void delegate(in Tile, in Item, in Item* parent) onItem;
//void delegate(in uint id, in ushort x, in ushort y, in ubyte z, uint flags, in ushort itemId) onHouseTile;


/**
 Checks whether otbm file format version is supported by library (it's not an map version)
 */
bool isSupported(Version otbm)
{
	return otbm.major == 0;
}

/**
 Checks whether map version supported by library (it's not an otbm version)
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

/**
 Describes position on map
 */
struct Position
{
	/// 0 to max-width / max-height coordinate
	ushort x, y;
	/// 0 to 16 coordinate
	ubyte z;
}

/**
 Describes a Tile
 */
struct Tile
{
	Position pos;
	uint flags;
}

/**
 Describes an item on map
 */
struct Item
{
	uint id;
	ushort type;
	ubyte count = 1;
	ushort aid;
	ushort uid;
	string text;
	ushort charges;

	bool isPortal;
	Position portal_exit;
	
	bool isDepot;
	ushort depot_id;
}

/**
 Describes waypoint on map
 */
struct Waypoint
{
	string name;
	Position pos;
}

/**
 Describes town on map
 */
struct Town
{
	uint id;
	string name;
	Position pos;
}



/**
 Describes group of item.
 */
enum ItemGroup : ubyte
{
  NONE = 0,
  GROUND,
  CONTAINER,
  WEAPON,    /*deprecated*/
  AMMUNITION,  /*deprecated*/
  ARMOR,   /*deprecated*/
  CHARGES,
  ITEM_GROUP_TELEPORT,  /*deprecated*/
  ITEM_GROUP_MAGICFIELD,  /*deprecated*/
  ITEM_GROUP_WRITEABLE, /*deprecated*/
  ITEM_GROUP_KEY,     /*deprecated*/
  ITEM_GROUP_SPLASH,
  ITEM_GROUP_FLUID,
  ITEM_GROUP_DOOR,    /*deprecated*/
  ITEM_GROUP_DEPRECATED,
  ITEM_GROUP_LAST
};

enum ItemAttribute : ubyte
{
  ServerId = 0x10,
  ClientId,
  Name,
  Descr,
  Speed,
  Slot,
  MaxItems,
  Weight,
  Weapon,
  Ammunition,
  Armor,
  MagLevel,
  MagFieldType,
  Writeable,
  RotateTo,
  Decay,
  SpriteHash,
  MiniMapColor,
  Attribute07,
  Attribute08,
  Light,
  Decay2,
  Weapon2,
  Ammunition2,
  Armor2,
  Writeable2,
  Light2,
  TopOrder,
  Writeable3,
  WareId,
};


/**
 Item type flags
 */
union ItemFlags
{
	uint f;
	mixin(bitfields!(
		bool, "BlockSolid", 1,
		bool, "BlockProjectile", 1,
		bool, "BlockPathFind", 1,
		bool, "HasHeight", 1,
		bool, "Usable", 1,
		bool, "Pickupable", 1,
		bool, "Movable", 1,
		bool, "Stackable", 1,
		bool, "FloorChangeDown", 1,
		bool, "FloorChangeNorth", 1,
		bool, "FloorChangeEast", 1,
		bool, "FloorChangeSouth", 1,
		bool, "FloorChangeWest", 1,
		bool, "AlwaysOnTop", 1,
		bool, "Readable", 1,
		bool, "Rotable", 1,
		bool, "Hangable", 1,
		bool, "Vertical", 1,
		bool, "Horizontal", 1,
		bool, "CannotDecay", 1,
		bool, "AllowDistRead", 1,
		bool, "Unused", 1,
		bool, "ClientCharges", 1, //deprecated
		bool, "LookThrough", 1,
		bool, "Animation", 1,
		bool, "WalkStack", 1,
		uint, "", 6
	));
	
	template stringize(Ts...)
	{
	    static if (Ts.length < 2)
	        enum stringize = "this."~Ts[0]~" ? \""~Ts[0]~"\" : \"\"";
	    else
	        enum stringize = stringize!(Ts[0]) ~ "," ~stringize!(Ts[1..$]);
	}
	
	const string toString() //templated names
	{
		enum string ret = stringize!("BlockSolid", "BlockProjectile", "BlockPathFind", "HasHeight", "Usable", 
				"Pickupable", "Movable", "Stackable", "FloorChangeDown", "FloorChangeNorth",
				"FloorChangeEast", "FloorChangeSouth", "FloorChangeWest", "AlwaysOnTop", "Readable",
				"Rotable", "Hangable", "Vertical", "Horizontal", "CannotDecay", "AllowDistRead", 
				"Unused", "ClientCharges", "LookThrough", "Animation", "WalkStack");
		return text(f," (",join(filter!(s => s.length > 0)(mixin("["~ret~"]")), ", "),")");
	}
}

/**
 Describes light source
 */
struct Light
{
	align(1)
	ushort level;
	ushort color;
	
	const string toString()
	{
		return text("Level:",level,"\tColor:",color);
	}
}

/**
 Describes OTB format Version
 */
struct VersionInfo
{
	align(1)
	uint otb_version;
	uint client_version;
	uint build;
	char[128] csd;
}
/**
 Informs user about OTB Version
 */
void delegate(VersionInfo) onOTBVersion;

/**
 Item type definition
 */
struct ItemType
{
	string name;
	ItemGroup group;
	ItemFlags flags;
	ushort serverId;
	ushort clientId;
	ushort speed;
	Light light2;
	ubyte topOrder;
	ushort wareId;
	ubyte[16] hash;
	ushort miniMapColor;
}
/**
 Informs user about item type definition
 */
void delegate(ItemType) onItemType;

/**
 Start to parse OTB file from stream (make sure you configured your callbacks before invocation)
 */
void parseOTB(Stream stream)
{
	enum RootAttrib : ubyte
	{
		VERSION = 0x1
	}
	alias ushort DataSize;
	
	
	ubyte cb;
	ushort len;
	RootAttrib ra;
	OTBMFilter otb = new OTBMFilter(stream);
	
	Version vOtb;
	otb.read(vOtb.major);
	enforceEx!OTBMVersionNotSupported(isSupported(vOtb), text("version=",vOtb));
	otb.read(cb);
	enforceEx!MapFormatBroken(cb == NODE_START);
	otb.read(cb);
	switch(cb)
	{
		case 0:
			uint flags;
			otb.read(flags);
			otb.read(cast(ubyte) ra);
			switch(ra)
			{
				case RootAttrib.VERSION:
					immutable GENERIC_OTB = 0xffffffff;
					DataSize ds;
					otb.read(ds);
					enforceEx!MapFormatBroken(ds == VersionInfo.sizeof);
					VersionInfo vi;
					otb.read(vi.otb_version);
					otb.read(vi.client_version);
					otb.read(vi.build);
					otb.readString(128);
					enforceEx!MapVersionNotSupported(vi.otb_version == GENERIC_OTB || vi.otb_version == 3);
					if (onOTBVersion !is null)
					{
						onOTBVersion(vi);
					}
				break;
				default:
					enforceEx!MapFormatBroken(false);
			}
		break;
		default:
			enforceEx!MapFormatBroken(false);
	}
	for(otb.read(cb); cb != NODE_END; otb.read(cb) )
	{
		ItemType it;
		otb.read(cast(ubyte) it.group);
		otb.read(it.flags.f);
		
		ushort size;
		otb.read(cb);
		while (cb != NODE_END)
		{
			otb.read(size);
			switch(cb)
			{
				case ItemAttribute.ServerId:
					enforceEx!MapFormatBroken(size == it.serverId.sizeof);
					otb.read(it.serverId);
				break;
				case ItemAttribute.ClientId:
					enforceEx!MapFormatBroken(size == it.clientId.sizeof);
					otb.read(it.clientId);
				break;
				case ItemAttribute.Speed:
					enforceEx!MapFormatBroken(size == it.speed.sizeof);
					otb.read(it.speed);
				break;
				case ItemAttribute.Light2:
					enforceEx!MapFormatBroken(size == it.light2.sizeof);
					otb.read(it.light2.level);
					otb.read(it.light2.color);
				break;
				case ItemAttribute.TopOrder:
					enforceEx!MapFormatBroken(size == it.topOrder.sizeof);
					otb.read(it.topOrder);
				break;
				case ItemAttribute.WareId:
					enforceEx!MapFormatBroken(size == it.wareId.sizeof);
					otb.read(it.wareId);
				break;
				case ItemAttribute.Name:
					it.name = to!string(otb.readString(size));
				break;
				case ItemAttribute.SpriteHash:
					enforceEx!MapFormatBroken(size == it.hash.sizeof);
					otb.read(it.hash);
				break;
				case ItemAttribute.MiniMapColor:
					enforceEx!MapFormatBroken(size == it.miniMapColor.sizeof);
					otb.read(it.miniMapColor);
				break;
				case ItemAttribute.Attribute07:
					otb.seekCur(size);
				break;
				case ItemAttribute.Attribute08:
					otb.seekCur(size);
				break;
				default:
					enforceEx!MapFormatBroken(false);
			}
			otb.read(cb);
		}
		if (onItemType !is null)
		{
			onItemType(it);
		}
	}
	enforceEx!MapFormatBroken(otb.eof);
}

/**
 Start to parse OTBM map file from stream (make sure you configured your callbacks before invocation)
 */
void parse(Stream stream)
{	
	ubyte type, curByte;
	uint item_count;
	OTBMFilter otbm = new OTBMFilter(stream);
	
	void parseTileArea(OTBMFilter buffer)
	{
		ubyte parseTile(OTBMFilter buffer, ushort x, ushort y, ubyte z)
		{
			void readFlags(OTBMFilter buffer, out uint flags)
			{
				uint validFlags;
				
				buffer.read(flags);
				if (flags & TileState.PROTECTIONZONE)
				{
					validFlags |= TileState.PROTECTIONZONE;
				}
				if (flags & TileState.NOPVPZONE)
				{
					validFlags |= TileState.NOPVPZONE;
				}
				if (flags & TileState.PVPZONE)
				{
					validFlags |= TileState.PVPZONE;
				}
				if (flags & TileState.NOLOGOUT)
				{
					validFlags |= TileState.NOLOGOUT;
				}
				if (flags & TileState.REFRESH)
				{
					validFlags |= TileState.REFRESH;
				}
				enforceEx!MapFormatBroken(validFlags == flags);
			}
			ubyte parseItem(OTBMFilter buf, in Tile tile, in Item* parent = null)
			{
				ubyte ub;
				Item i = Item();
				i.id = ++item_count;
				
				buf.read(i.type);
				buf.read(ub);
				while(ub != NODE_END)
				{
					switch(ub)
					{
						case NODE_START:
							buffer.read(ub);
							switch(ub)
							{
								case NodeType.ITEM:
									parseItem(buf, tile, &i);
									buf.read(ub);
								break;
								default:
									enforceEx!MapFormatBroken(false);
							}
						break;
						case DataType.COUNT:
							buffer.read(i.count);
							buffer.read(ub);
						break;
						case DataType.TELE_DEST:
							i.isPortal = true;
							buffer.read(i.portal_exit.x);
							buffer.read(i.portal_exit.y);
							buffer.read(i.portal_exit.z);
							buffer.read(ub);
						break;
						case DataType.DEPOT_ID:
							i.isDepot = true;
							buffer.read(i.depot_id);
							buffer.read(ub);
						break;
						case DataType.TEXT:
							i.text = to!string(readStr(buffer));
							buffer.read(ub);
						break;
						case DataType.CHARGES:
							buffer.read(i.charges);
							buffer.read(ub);
						break;
						case DataType.ACTION_ID:
							buffer.read(i.aid);
							buffer.read(ub);
						break;
						case DataType.UNIQUE_ID:
							buffer.read(i.uid);
							buffer.read(ub);
						break;
						default:
							enforceEx!MapFormatBroken(false);
					}
				}
				if (onItem !is null)
				{
					onItem(tile, i, parent);
				}
				
				return ub;
			}
			ubyte curByte, type, dx, dy;
			Tile t;
			
			buffer.read(dx); t.pos.x = to!ushort(x+dx);
			buffer.read(dy); t.pos.y = to!ushort(y+dy);
			t.pos.z = z;
		
			buffer.read(curByte);
			while(curByte != NODE_END)
			{
				switch(curByte)
				{
					case DataType.ITEM:
						curByte = parseItem(buffer,t);
					break;
					case DataType.TILE_FLAGS:
						readFlags(buffer, t.flags);
						buffer.read(curByte);
					break;
					case NODE_START:
						otbm.read(curByte);
						while(curByte != NODE_END)
						{
							switch(curByte)
							{
								case NodeType.ITEM:
									curByte = parseItem(buffer,t);
								break;
								default:
									enforceEx!MapFormatBroken(false);
							}
						}
						otbm.read(curByte);
					break;
					default:
						enforceEx!MapFormatBroken(curByte == NODE_END);
				}
			}
			if (onTile !is null)
			{
				onTile(t);
			}
			buffer.read(curByte);
			return curByte;
		}
		ushort x, y;
		ubyte curByte, z;
		buffer.read(x);
		buffer.read(y);
		buffer.read(z);
		enforceEx!MapFormatBroken(z < 16);
		
		buffer.read(curByte);
		enforceEx!MapFormatBroken(curByte == NODE_START);
		while(curByte != NODE_END)
		{
			buffer.read(curByte);
			switch(curByte)
			{
				case NodeType.TILE:
					curByte = parseTile(buffer, x,y,z);
				break;
//				case NodeType.HOUSETILE:
//					buffer.doDebug();
//	//				TileHouse(buffer);
//				break;
				default:
					enforceEx!MapFormatBroken(false);
			}
		}
	}
	void parseTowns(OTBMFilter buf)
	{
		ubyte ub;
		buf.read(ub);
		enforceEx!MapFormatBroken(ub == NODE_START);
		while(ub != NODE_END)
		{
			buf.read(ub);
			switch(ub)
			{
				case NodeType.TOWN:
					Town t;
					buf.read(t.id);
					t.name = to!string(readStr(buf));
					buf.read(t.pos.x);
					buf.read(t.pos.y);
					buf.read(t.pos.z);
					if (onTown !is null)
						onTown(t);
					buf.read(ub);
				break;
				default:
					enforceEx!MapFormatBroken(false);
			}
		}
	}
	
	Version vOtbm;
	otbm.read(vOtbm.major);
	enforceEx!OTBMVersionNotSupported(isSupported(vOtbm), text("version=",vOtbm));
	
	otbm.onNodeChildNext!(NodeType.ROOT, parseHeader);
	otbm.onNodeChildNext!(NodeType.MAP_DATA, parseMapData);
	curByte = otbm._peekedByte;
	while(curByte != NODE_END)
	{
		enforceEx!MapFormatBroken(curByte == NODE_START);
		otbm.read(curByte);
		switch(curByte)
		{
			case NodeType.TILE_AREA:
				parseTileArea(otbm);
			break;
			case NodeType.TOWNS:
				parseTowns(otbm);
				otbm.read(curByte);
			break;
			case NodeType.WAYPOINTS:
				otbm.read(curByte);
				while(curByte != NODE_END)
				{
					switch(curByte)
					{
						case NodeType.WAYPOINT:
							Waypoint wp;
							wp.name = to!string(readStr(otbm));
							
							otbm.read(wp.pos.x);
							otbm.read(wp.pos.y);
							otbm.read(wp.pos.z);
							if (onWaypoint !is null)
								onWaypoint(wp);
						break;
						default:
							enforceEx!MapFormatBroken(false);
					}
				}
			break;
			default:
				enforceEx!MapFormatBroken(false);
		}
		otbm.read(curByte);
	}
}

private:
immutable NODE_START	= 0xfe;
immutable NODE_END		= 0xff;
immutable NODE_ESCAPE	= 0xfd;
class OTBMFilter : FilterStream
{
	ubyte _curNode;
	bool _hasPeekedByte;
	ubyte _peekedByte;
	
	this(Stream otbm)
	{
		super(otbm);
	}
	
	// read from source
	override size_t readBlock(void* buffer, size_t size)
	{
		auto ret = super.readBlock(buffer,size);
		auto b = cast(ubyte[])buffer[0 .. ret];
		auto j = 0, i = 0;
		auto escape = false;

		while(true)
		{
			for(; j < ret; j++)
			{
				if (b[j] == NODE_ESCAPE)
				{
					if (ret <= j+1)
					{
						escape = true;
						break;
					}
					b[i++] = b[++j];
				}
	//			else if (b[j] == NODE_START || b[j] == NODE_END)
	//			{
	//				enforceEx!MapFormatBroken(false);
	//			}
				else
					b[i++] = b[j];
			}
			if (i < ret)
			{
				if (0 == super.readBlock(buffer+i, ret-i))
					break;
				if (escape)
				{
					i++;
					escape = false;
				}
				j = i;
			}
			else
			{
				break;
			}
		}

		return i;
	}
	
	void _readByte()
	{
		if (!_hasPeekedByte)
			source.read(_peekedByte);
		else
			_hasPeekedByte = false;
	}
	public:
	auto onNodeChildNext(NodeType nt, alias h, A...)(A args)
	{
		_readByte();
		enforceEx!MapFormatBroken(_peekedByte == NODE_START);
		source.read(_curNode);
		enforceEx!MapFormatBroken(_curNode == nt);
		return h(this, args);
	}
	/**
		even: NodeType.Foo
		odd: handler(FilterOTBM)
	**/
	void onAnyNodeChildNext(A...)()
	{
		static assert(A.length % 2 == 0 && A.length != 0,
			"each NodeType have to pair with corresponding handler");
		_readByte();
		foreach(i, t; A)
		{
			static if (i % 2 == 1)
			{
				if (A[i-1] == _peekedByte)
				{
					A[i](this);
				}
			}
		}
	}
	/**
		even: DataType.Foo
		odd: handler(FilterOTBM)
	**/
	auto onNodeAttribute(A...)()
	{
		static assert(A.length % 2 == 0 && A.length != 0,
			"each DataType have to pair with corresponding handler");
		_readByte();
		while(_peekedByte != NODE_END && _peekedByte != NODE_START)
		{
			foreach(i, t; A)
			{
				static if (i % 2 == 1)
				{
					if (A[i-1] == _peekedByte)
					{
						A[i](this);
					}
				}
			}
			source.read(_peekedByte);
		}
		_hasPeekedByte = true;
	}
	
	auto doDebug(uint lines = 6)
	{
		auto cmd = text(
				"hexdump -C /home/shd/Downloads/trunk.r5673/trunk.r5673/data/items/items.otb -s "
				,source.position > 16 ? source.position-16 : source.position
				," | head -n",lines);
		system(cmd.ptr);
	}
}

enum NodeType : ubyte
{
	ROOT		= 0x0,
	ROOTV1		= 0x1,
	MAP_DATA	= 0x2,
	ITEM_DEF	= 0x3,
	TILE_AREA	= 0x4,
	TILE		= 0x5,
	ITEM		= 0x6,
	TILE_SQUARE = 0x7,
	TILE_REF	= 0x8,
	SPAWNS		= 0x9,
	SPAWN_AREA	= 0xA,
	MONSTER		= 0xB,
	TOWNS		= 0xC,
	TOWN		= 0xD,
	HOUSETILE	= 0xE,
	WAYPOINTS	= 0xF,
	WAYPOINT	= 0x10
}
enum DataType : ubyte
{
	DESCRIPTION		= 0x1,
	EXT_FILE		= 0x2,
	TILE_FLAGS		= 0x3,
	ACTION_ID		= 0x4,
	UNIQUE_ID		= 0x5,
	TEXT			= 0x6,
	DESC			= 0x7,
	TELE_DEST		= 0x8,
	ITEM			= 0x9,
	DEPOT_ID		= 0xA,
	EXT_SPAWN_FILE	= 0xB,
	RUNE_CHARGES 	= 0xC,
	EXT_HOUSE_FILE	= 0xD,
	HOUSEDOORID 	= 0xE,
	COUNT 			= 0xF,
	DURATION 		= 0x10,
	DECAYING_STATE	= 0x11,
	WRITTENDATE		= 0x12,
	WRITTENBY		= 0x13,
	SLEEPERGUID		= 0x14,
	SLEEPSTART		= 0x15,
	CHARGES			= 0x16
}


enum TileState : ubyte
{
	NONE				= 0,
	PROTECTIONZONE		= 1 << 0,
	DEPRECATED_HOUSE	= 1 << 1,
	NOPVPZONE			= 1 << 2,
	NOLOGOUT			= 1 << 3,
	PVPZONE				= 1 << 4,
	REFRESH				= 1 << 5,
}

void parseDescription(OTBMFilter buffer)
{
	char[] desc = readStr(buffer);
	if (onMapDescription !is null)
		onMapDescription(desc);
}
void parseSpawns(OTBMFilter buffer)
{
	char[] spawn = readStr(buffer);
	if (onMapSpawnFile !is null)
		onMapSpawnFile(spawn);
}
void parseHouses(OTBMFilter buffer)
{
	char[] houses = readStr(buffer);
	if (onMapHousesFile !is null)
		onMapHousesFile(houses);
}
void parseMapData(OTBMFilter buffer)
{
	buffer.onNodeAttribute!(
		DataType.DESCRIPTION, parseDescription,
		DataType.EXT_SPAWN_FILE, parseSpawns,
		DataType.EXT_HOUSE_FILE, parseHouses
	);
}

void parseHeader(OTBMFilter buffer)
{
	uint ver;			buffer.read(ver);
	ushort width;		buffer.read(width);
	ushort height;		buffer.read(height);
	uint itemsVerMajor;	buffer.read(itemsVerMajor);
	uint itemsVerMinor;	buffer.read(itemsVerMinor);
	
	Nullable!Version map = Version(ver, 0);
	Nullable!Version items = Version(itemsVerMajor, itemsVerMinor);
	enforceEx!MapVersionNotSupported(isSupported(map, items));
	
	if (onHeader !is null)
		onHeader(map, width, height, items);
}

char[] readStr(Stream buffer)
{
	ushort len;
	buffer.read(len);
	return buffer.readString(len);
}
	
//}

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
