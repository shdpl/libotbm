module otbm.otbm;

public {
	import otbm.parser;
}
private {
	import std.string;
	import std.conv : text;
	import otbm.common;
}
debug
{
	private import std.stdio;
}

extern(C)
{
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

	/*
		 Describes a Tile in the House
	 */
	struct HouseTile
	{
		uint house_id;
		Tile tile;
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
		
		bool isHouseDoor;
		ubyte door_id;
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

	private:	
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
		RUNE_CHARGES	= 0xC,
		EXT_HOUSE_FILE	= 0xD,
		HOUSEDOORID		= 0xE,
		COUNT			= 0xF,
		DURATION		= 0x10,
		DECAYING_STATE	= 0x11,
		WRITTENDATE		= 0x12,
		WRITTENBY		= 0x13,
		SLEEPERGUID		= 0x14,
		SLEEPSTART		= 0x15,
		CHARGES			= 0x16
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
	
	
	public:
	
	/**
	 OTBM file format parser instance
	 */
	struct ParserOTBM
	{
		/**
		 Called after reading file header
		 */
		void function(in Nullable!Version map, in ushort width, in ushort height, in Nullable!Version items) onHeader;
		
		/**
		 Called with human-provided map description
		 */
		void function(in char* description) onMapDescription;
		/**
		 Provides user with path to file containing spawn description.
		 */
		void function(in char* spawn) onMapSpawnFile;
		/**
		 Provides user with path to file that describes houses.
		 */
		void function(in char* houses) onMapHousesFile;
		
		/**
		 Called every time when parser will encounter town definition.
		 */
		void function(in Town) onTown;
		/**
		 Called every time when parser will encounter waypoint definition.
		 */
		void function(in Waypoint) onWaypoint;
		
		/**
		 Called for every map tile filled with data.
		 */
		void function(in Tile) onTile;
		/**
		 Called every time, that parser encounters item definition
		 
		 Bugs:OTBM-1 Tile, and parent here might not be fully filled with its data
		 */
		void function(in Tile, in Item, in Item* parent) onItem;
		
//		void function(in uint id, in ushort x, in ushort y, in ubyte z, uint flags, in ushort itemId) onHouseTile;

		
		/**
		 Start to parse OTBM map file from stream (make sure you configured your callbacks before invocation)
		 */
		void parse(void[] data)
		{	
			ubyte type, curByte;
			uint item_count;
			auto otbm = Stream(data);
			
			Version vOtbm;
			otbm.read(vOtbm.major);
			enforce!OTBMVersionNotSupported(isSupported(vOtbm), text("version=",vOtbm));
			
			required!(NodeType.ROOT, parseOTBM)(otbm);
		}
		private:
		string readStr(ref Stream buffer)
		{
			ushort length;
			buffer.read(length);
			return buffer.readString(length);
		}
		
		void parseDescription(ref Stream buffer)
		{
			string desc = readStr(buffer);
			if (onMapDescription !is null)
				onMapDescription(desc.toStringz);
		}
		void parseSpawns(ref Stream buffer)
		{
			string spawn = readStr(buffer);
			if (onMapSpawnFile !is null)
				onMapSpawnFile(spawn.toStringz);
		}
		void parseHouses(ref Stream buffer)
		{
			string houses = readStr(buffer);
			if (onMapHousesFile !is null)
				onMapHousesFile(houses.toStringz);
		}
		void parseMapData(ref Stream buffer)
		{
			multiple!(DataType.DESCRIPTION, parseDescription)(buffer);
			required!(DataType.EXT_SPAWN_FILE, parseSpawns)(buffer);
			required!(DataType.EXT_HOUSE_FILE, parseHouses)(buffer);
			
			multiple!(NodeType.TILE_AREA, parseTileArea)(buffer);
			required!(NodeType.TOWNS, parseTowns)(buffer);
			required!(NodeType.WAYPOINTS, parseWaypoints)(buffer);
		}
		void parseOTBM(ref Stream buffer)
		{
			uint ver;			buffer.read(ver);
			ushort width;		buffer.read(width);
			ushort height;		buffer.read(height);
			uint itemsVerMajor;	buffer.read(itemsVerMajor);
			uint itemsVerMinor;	buffer.read(itemsVerMinor);
			
			Nullable!Version map = Version(ver, 0);
			Nullable!Version items = Version(itemsVerMajor, itemsVerMinor);
			enforce!MapVersionNotSupported(isSupported(map, items));
			
			if (onHeader !is null)
				onHeader(map, width, height, items);
				
			required!(NodeType.MAP_DATA, parseMapData)(buffer);
		}
		void parseWaypoint(ref Stream otbm)
		{
			Waypoint wp;
			wp.name = to!string(readStr(otbm));
			
			otbm.read(wp.pos.x);
			otbm.read(wp.pos.y);
			otbm.read(wp.pos.z);
			if (onWaypoint !is null)
				onWaypoint(wp);
		}
		void parseWaypoints(ref Stream otbm)
		{
			multiple!(NodeType.WAYPOINT, parseWaypoint)(otbm);
		}
		void parseTown(ref Stream buffer)
		{
			Town t;
			buffer.read(t.id);
			t.name = to!string(readStr(buffer));
			buffer.read(t.pos.x);
			buffer.read(t.pos.y);
			buffer.read(t.pos.z);
			if (onTown !is null)
				onTown(t);
		}
		void parseTowns(ref Stream buffer)
		{
			multiple!(NodeType.TOWN, parseTown)(buffer);
		}
		void parseHouseTile(ref Stream buffer, ushort x, ushort y, ubyte z)
		{
			ubyte curByte, type, dx, dy;
			HouseTile t;
			
			buffer.read(dx); t.tile.pos.x = to!ushort(x+dx);
			buffer.read(dy); t.tile.pos.y = to!ushort(y+dy);
			t.tile.pos.z = z;
			
			buffer.read(t.house_id);

			//TODO: onHouseTile
			
			bool cont = true;
			while( cont )
			{
				// Tuples cannot be nested, so make it manual
				cont = false;
				cont |= optional!(DataType.ITEM, parseItem)(buffer,&t.tile);
				cont |= optional!(DataType.TILE_FLAGS, readFlags)(buffer, t.tile.flags);
				cont |= optional!(NodeType.ITEM, parseItem)(buffer,&t.tile);
			}
			//0006907e
		}
		void parseTileArea(ref Stream buffer)
		{
			ushort x, y;
			ubyte curByte, z;
			buffer.read(x);
			buffer.read(y);
			buffer.read(z);
			enforce!MapFormatBroken(z < 16);
			
			auto cont = true;
			while ( cont )
			{
				cont = false;
				cont |= optional!(NodeType.TILE, parseTile)(buffer, x,y,z);
				cont |= optional!(NodeType.HOUSETILE, parseHouseTile)(buffer, x,y,z);
			}
		}
		void itemCount(ref Stream buffer, ref Item i)
		{
			buffer.read(i.count);
		}
		void itemTeleport(ref Stream buffer, ref Item i)
		{
			i.isPortal = true;
			buffer.read(i.portal_exit.x);
			buffer.read(i.portal_exit.y);
			buffer.read(i.portal_exit.z);
		}
		void itemInDepot(ref Stream buffer, ref Item i)
		{
			i.isDepot = true;
			buffer.read(i.depot_id);
		}
		void itemText(ref Stream buffer, ref Item i)
		{
			i.text = to!string(readStr(buffer));
		}
		void itemCharges(ref Stream buffer, ref Item i)
		{
			buffer.read(i.charges);
		}
		void itemAid(ref Stream buffer, ref Item i)
		{
			buffer.read(i.aid);
		}
		void itemUid(ref Stream buffer, ref Item i)
		{
			buffer.read(i.uid);
		}
		void itemDoorId(ref Stream buffer, ref Item i)
		{
			i.isHouseDoor = true;
			buffer.read(i.door_id);
		}
		void parseItem(ref Stream buffer, Tile* tile, Item* parent = null)
		{
			Item i = Item();
			
			buffer.read(i.type);
			
			bool cont = true;
			while( cont )
			{
				cont = false;
				// Tuples cannot be nested, so make it manual
				cont |= optional!(NodeType.ITEM, parseItem)(buffer,tile,&i);
				cont |= optional!(DataType.COUNT, itemCount)(buffer,i);
				cont |= optional!(DataType.TELE_DEST, itemTeleport)(buffer,i);
				cont |= optional!(DataType.DEPOT_ID, itemInDepot)(buffer,i);
				cont |= optional!(DataType.TEXT, itemText)(buffer,i);
				cont |= optional!(DataType.CHARGES, itemCharges)(buffer,i);
				cont |= optional!(DataType.ACTION_ID, itemAid)(buffer,i);
				cont |= optional!(DataType.UNIQUE_ID, itemUid)(buffer,i);
				cont |= optional!(DataType.HOUSEDOORID, itemDoorId)(buffer,i);
			}
			
			if (onItem !is null)
			{
				onItem(*tile, i, parent);
			}
		}
		void readFlags(ref Stream buffer, out uint flags)
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
//			enforce!MapFormatBroken(validFlags == flags);
		}
		void parseTile(ref Stream buffer, ushort x, ushort y, ubyte z)
		{
			ubyte curByte, type, dx, dy;
			Tile t;
			
			buffer.read(dx); t.pos.x = to!ushort(x+dx);
			buffer.read(dy); t.pos.y = to!ushort(y+dy);
			t.pos.z = z;
			
			if (onTile !is null)
			{
				onTile(t);
			}
			
			bool cont = true;
			while( cont )
			{
				// Tuples cannot be nested, so make it manual
				cont = false;
				cont |= optional!(DataType.ITEM, parseItem)(buffer,&t);
				cont |= optional!(DataType.TILE_FLAGS, readFlags)(buffer, t.flags);
				cont |= optional!(NodeType.ITEM, parseItem)(buffer,&t);
			}
		}
		
		
		
		void required(NodeType nt, alias func, A...)(ref Stream otbm, A args)
		{
			ubyte cb;
			otbm.read(cb);
			enforce!MapFormatBroken(cb == NODE_START);
			
			otbm.read(cb);
			enforce!MapFormatBroken(cb == nt);
			
			debug
			{
				writeln("parsing NodeType.",nt," by requirement at ",otbm.pos);
			}
			func(otbm, args);
			
			otbm.read(cb);
			enforce!MapFormatBroken(cb == NODE_END);
		}
		void required(DataType dt, alias func, A...)(ref Stream otbm, A args)
		{
			ubyte cb;
			otbm.read(cb);
			enforce!MapFormatBroken(cb == dt);
			
			debug
			{
				writeln("parsing DataType.",dt," by requirement at ",otbm.pos);
			}
			func(otbm, args);
		}
		bool optional(NodeType nt, alias func, A...)(ref Stream otbm, A args)
		{
			ubyte cb;
			
			auto len1 = otbm.peek(cb);
			if( cb != NODE_START )
			{
				return false; // not a node
			}
			otbm.pos += len1;
			
			auto len2 = otbm.peek(cb);
			if( cb != nt )
			{
				otbm.pos -= len1;
				return false; // different node
			}
			otbm.pos += len2;
			
			debug
			{
				writeln("optionally parsing NodeType.",nt," at ",otbm.pos);
			}
			
			func(otbm, args);
			
			otbm.read(cb);
			enforce!MapFormatBroken(cb == NODE_END);
			return true;
		}
		bool optional(DataType dt, alias func, A...)(ref Stream otbm, A args)
		{
			ubyte cb;
			
			auto len1 = otbm.peek(cb);
			if( dt != cb )
			{
				return false;
			}
			otbm.pos += len1;
			
			debug
			{
				writeln("optionally parsing DataType.",dt," at ",otbm.pos);
			}
			
			func(otbm, args);
			return true;
		}
		size_t multiple(alias type, alias func, A...)(ref Stream otbm, A args) if( is(typeof(type) == NodeType) || is(typeof(type) == DataType) )
		{
			size_t cnt;
			while( optional!(type,func)(otbm, args) ) { cnt++; }
			return cnt;
		}
		/**
		 * even: DataType.Foo
		 * odd: handler(FilterOTBM)
		 */
		size_t any(A...)(ref Stream otbm)
		{
			static assert(A.length % 2 == 0 && A.length != 0, "each DataType have to pair with corresponding handler");
			size_t total;
			size_t step;
			do {
				step = 0;
				foreach(i, t; A)
				{
					static if (i % 2 == 1)
					{
						step += multiple!(A[i-1],A[i])(otbm);
					}
				}
				total += step;
			} while( step != 0 );
			return total;
		}
	}
}
