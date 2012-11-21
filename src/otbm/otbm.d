module otbm.otbm;

public {
	import otbm.parser;
}
private {
	import otbm.common;
}

extern(C)
{
	/**
	 OTBM file format parser instance
	 */
	struct ParserOTBM
	{
		/**
		 Called after reading file header
		 */
		void function(in Version map, in ushort width, in ushort height, in Version items) onHeader;
		
		/**
		 Called with human-provided map description
		 */
		void function(ref in char[] description) onMapDescription;
		/**
		 Provides user with path to file containing spawn description.
		 */
		void function(ref in char[] spawn) onMapSpawnFile;
		/**
		 Provides user with path to file that describes houses.
		 */
		void function(ref in char[] houses) onMapHousesFile;
		
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
		//void function(in uint id, in ushort x, in ushort y, in ubyte z, uint flags, in ushort itemId) onHouseTile;
		
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
		 Start to parse OTBM map file from stream (make sure you configured your callbacks before invocation)
		 */
		void parse(void[] stream)
		{	
	//		ubyte type, curByte;
	//		uint item_count;
	//		OTBMFilter otbm = new OTBMFilter(stream);
	//		
	//		void parseTileArea(OTBMFilter buffer)
	//		{
	//			ubyte parseTile(OTBMFilter buffer, ushort x, ushort y, ubyte z)
	//			{
	//				void readFlags(OTBMFilter buffer, out uint flags)
	//				{
	//					uint validFlags;
	//					
	//					buffer.read(flags);
	//					if (flags & TileState.PROTECTIONZONE)
	//					{
	//						validFlags |= TileState.PROTECTIONZONE;
	//					}
	//					if (flags & TileState.NOPVPZONE)
	//					{
	//						validFlags |= TileState.NOPVPZONE;
	//					}
	//					if (flags & TileState.PVPZONE)
	//					{
	//						validFlags |= TileState.PVPZONE;
	//					}
	//					if (flags & TileState.NOLOGOUT)
	//					{
	//						validFlags |= TileState.NOLOGOUT;
	//					}
	//					if (flags & TileState.REFRESH)
	//					{
	//						validFlags |= TileState.REFRESH;
	//					}
	//					enforceEx!MapFormatBroken(validFlags == flags);
	//				}
	//				ubyte parseItem(OTBMFilter buf, in Tile tile, in Item* parent = null)
	//				{
	//					ubyte ub;
	//					Item i = Item();
	//					i.id = ++item_count;
	//					
	//					buf.read(i.type);
	//					buf.read(ub);
	//					while(ub != NODE_END)
	//					{
	//						switch(ub)
	//						{
	//							case NODE_START:
	//								buffer.read(ub);
	//								switch(ub)
	//								{
	//									case NodeType.ITEM:
	//										parseItem(buf, tile, &i);
	//										buf.read(ub);
	//									break;
	//									default:
	//										enforceEx!MapFormatBroken(false);
	//								}
	//							break;
	//							case DataType.COUNT:
	//								buffer.read(i.count);
	//								buffer.read(ub);
	//							break;
	//							case DataType.TELE_DEST:
	//								i.isPortal = true;
	//								buffer.read(i.portal_exit.x);
	//								buffer.read(i.portal_exit.y);
	//								buffer.read(i.portal_exit.z);
	//								buffer.read(ub);
	//							break;
	//							case DataType.DEPOT_ID:
	//								i.isDepot = true;
	//								buffer.read(i.depot_id);
	//								buffer.read(ub);
	//							break;
	//							case DataType.TEXT:
	//								i.text = to!string(readStr(buffer));
	//								buffer.read(ub);
	//							break;
	//							case DataType.CHARGES:
	//								buffer.read(i.charges);
	//								buffer.read(ub);
	//							break;
	//							case DataType.ACTION_ID:
	//								buffer.read(i.aid);
	//								buffer.read(ub);
	//							break;
	//							case DataType.UNIQUE_ID:
	//								buffer.read(i.uid);
	//								buffer.read(ub);
	//							break;
	//							default:
	//								enforceEx!MapFormatBroken(false);
	//						}
	//					}
	//					if (onItem !is null)
	//					{
	//						onItem(tile, i, parent);
	//					}
	//					
	//					return ub;
	//				}
	//				ubyte curByte, type, dx, dy;
	//				Tile t;
	//				
	//				buffer.read(dx); t.pos.x = to!ushort(x+dx);
	//				buffer.read(dy); t.pos.y = to!ushort(y+dy);
	//				t.pos.z = z;
	//			
	//				buffer.read(curByte);
	//				while(curByte != NODE_END)
	//				{
	//					switch(curByte)
	//					{
	//						case DataType.ITEM:
	//							curByte = parseItem(buffer,t);
	//						break;
	//						case DataType.TILE_FLAGS:
	//							readFlags(buffer, t.flags);
	//							buffer.read(curByte);
	//						break;
	//						case NODE_START:
	//							otbm.read(curByte);
	//							while(curByte != NODE_END)
	//							{
	//								switch(curByte)
	//								{
	//									case NodeType.ITEM:
	//										curByte = parseItem(buffer,t);
	//									break;
	//									default:
	//										enforceEx!MapFormatBroken(false);
	//								}
	//							}
	//							otbm.read(curByte);
	//						break;
	//						default:
	//							enforceEx!MapFormatBroken(curByte == NODE_END);
	//					}
	//				}
	//				if (onTile !is null)
	//				{
	//					onTile(t);
	//				}
	//				buffer.read(curByte);
	//				return curByte;
	//			}
	//			ushort x, y;
	//			ubyte curByte, z;
	//			buffer.read(x);
	//			buffer.read(y);
	//			buffer.read(z);
	//			enforceEx!MapFormatBroken(z < 16);
	//			
	//			buffer.read(curByte);
	//			enforceEx!MapFormatBroken(curByte == NODE_START);
	//			while(curByte != NODE_END)
	//			{
	//				buffer.read(curByte);
	//				switch(curByte)
	//				{
	//					case NodeType.TILE:
	//						curByte = parseTile(buffer, x,y,z);
	//					break;
	//	//				case NodeType.HOUSETILE:
	//	//					buffer.doDebug();
	//	//	//				TileHouse(buffer);
	//	//				break;
	//					default:
	//						enforceEx!MapFormatBroken(false);
	//				}
	//			}
	//		}
	//		void parseTowns(OTBMFilter buf)
	//		{
	//			ubyte ub;
	//			buf.read(ub);
	//			enforceEx!MapFormatBroken(ub == NODE_START);
	//			while(ub != NODE_END)
	//			{
	//				buf.read(ub);
	//				switch(ub)
	//				{
	//					case NodeType.TOWN:
	//						Town t;
	//						buf.read(t.id);
	//						t.name = to!string(readStr(buf));
	//						buf.read(t.pos.x);
	//						buf.read(t.pos.y);
	//						buf.read(t.pos.z);
	//						if (onTown !is null)
	//							onTown(t);
	//						buf.read(ub);
	//					break;
	//					default:
	//						enforceEx!MapFormatBroken(false);
	//				}
	//			}
	//		}
	//		
	//		Version vOtbm;
	//		otbm.read(vOtbm.major);
	//		enforceEx!OTBMVersionNotSupported(isSupported(vOtbm), text("version=",vOtbm));
	//		
	//		otbm.onNodeChildNext!(NodeType.ROOT, parseHeader);
	//		otbm.onNodeChildNext!(NodeType.MAP_DATA, parseMapData);
	//		curByte = otbm._peekedByte;
	//		while(curByte != NODE_END)
	//		{
	//			enforceEx!MapFormatBroken(curByte == NODE_START);
	//			otbm.read(curByte);
	//			switch(curByte)
	//			{
	//				case NodeType.TILE_AREA:
	//					parseTileArea(otbm);
	//				break;
	//				case NodeType.TOWNS:
	//					parseTowns(otbm);
	//					otbm.read(curByte);
	//				break;
	//				case NodeType.WAYPOINTS:
	//					otbm.read(curByte);
	//					while(curByte != NODE_END)
	//					{
	//						switch(curByte)
	//						{
	//							case NodeType.WAYPOINT:
	//								Waypoint wp;
	//								wp.name = to!string(readStr(otbm));
	//								
	//								otbm.read(wp.pos.x);
	//								otbm.read(wp.pos.y);
	//								otbm.read(wp.pos.z);
	//								if (onWaypoint !is null)
	//									onWaypoint(wp);
	//							break;
	//							default:
	//								enforceEx!MapFormatBroken(false);
	//						}
	//					}
	//				break;
	//				default:
	//					enforceEx!MapFormatBroken(false);
	//			}
	//			otbm.read(curByte);
	//		}
		}
		
		private:
	//	class OTBMFilter : FilterStream
	//	{
	//		ubyte _curNode;
	//		bool _hasPeekedByte;
	//		ubyte _peekedByte;
	//		
	//		this(Stream otbm)
	//		{
	//			super(otbm);
	//		}
	//		
	//		// read from source
	//		override size_t readBlock(void* buffer, size_t size)
	//		{
	//			auto ret = super.readBlock(buffer,size);
	//			auto b = cast(ubyte[])buffer[0 .. ret];
	//			auto j = 0, i = 0;
	//			auto escape = false;
	//	
	//			while(true)
	//			{
	//				for(; j < ret; j++)
	//				{
	//					if (b[j] == NODE_ESCAPE)
	//					{
	//						if (ret <= j+1)
	//						{
	//							escape = true;
	//							break;
	//						}
	//						b[i++] = b[++j];
	//					}
	//		//			else if (b[j] == NODE_START || b[j] == NODE_END)
	//		//			{
	//		//				enforceEx!MapFormatBroken(false);
	//		//			}
	//					else
	//						b[i++] = b[j];
	//				}
	//				if (i < ret)
	//				{
	//					if (0 == super.readBlock(buffer+i, ret-i))
	//						break;
	//					if (escape)
	//					{
	//						i++;
	//						escape = false;
	//					}
	//					j = i;
	//				}
	//				else
	//				{
	//					break;
	//				}
	//			}
	//	
	//			return i;
	//		}
	//		
	//		void _readByte()
	//		{
	//			if (!_hasPeekedByte)
	//				source.read(_peekedByte);
	//			else
	//				_hasPeekedByte = false;
	//		}
	//		public:
	//		auto onNodeChildNext(NodeType nt, alias h, A...)(A args)
	//		{
	//			_readByte();
	//			enforceEx!MapFormatBroken(_peekedByte == NODE_START);
	//			source.read(_curNode);
	//			enforceEx!MapFormatBroken(_curNode == nt);
	//			return h(this, args);
	//		}
	//		/**
	//			even: NodeType.Foo
	//			odd: handler(FilterOTBM)
	//		**/
	//		void onAnyNodeChildNext(A...)()
	//		{
	//			static assert(A.length % 2 == 0 && A.length != 0,
	//				"each NodeType have to pair with corresponding handler");
	//			_readByte();
	//			foreach(i, t; A)
	//			{
	//				static if (i % 2 == 1)
	//				{
	//					if (A[i-1] == _peekedByte)
	//					{
	//						A[i](this);
	//					}
	//				}
	//			}
	//		}
	//		/**
	//			even: DataType.Foo
	//			odd: handler(FilterOTBM)
	//		**/
	//		auto onNodeAttribute(A...)()
	//		{
	//			static assert(A.length % 2 == 0 && A.length != 0,
	//				"each DataType have to pair with corresponding handler");
	//			_readByte();
	//			while(_peekedByte != NODE_END && _peekedByte != NODE_START)
	//			{
	//				foreach(i, t; A)
	//				{
	//					static if (i % 2 == 1)
	//					{
	//						if (A[i-1] == _peekedByte)
	//						{
	//							A[i](this);
	//						}
	//					}
	//				}
	//				source.read(_peekedByte);
	//			}
	//			_hasPeekedByte = true;
	//		}
	//		
	//		auto doDebug(uint lines = 6)
	//		{
	//			auto cmd = text(
	//					"hexdump -C /home/shd/Downloads/trunk.r5673/trunk.r5673/data/items/items.otb -s "
	//					,source.position > 16 ? source.position-16 : source.position
	//					," | head -n",lines);
	//			system(cmd.ptr);
	//		}
	//	}
		
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
		
	//	void parseDescription(OTBMFilter buffer)
	//	{
	//		char[] desc = readStr(buffer);
	//		if (onMapDescription !is null)
	//			onMapDescription(desc);
	//	}
	//	void parseSpawns(OTBMFilter buffer)
	//	{
	//		char[] spawn = readStr(buffer);
	//		if (onMapSpawnFile !is null)
	//			onMapSpawnFile(spawn);
	//	}
	//	void parseHouses(OTBMFilter buffer)
	//	{
	//		char[] houses = readStr(buffer);
	//		if (onMapHousesFile !is null)
	//			onMapHousesFile(houses);
	//	}
	//	void parseMapData(OTBMFilter buffer)
	//	{
	//		buffer.onNodeAttribute!(
	//			DataType.DESCRIPTION, parseDescription,
	//			DataType.EXT_SPAWN_FILE, parseSpawns,
	//			DataType.EXT_HOUSE_FILE, parseHouses
	//		);
	//	}
	//	
	//	void parseHeader(OTBMFilter buffer)
	//	{
	//		uint ver;			buffer.read(ver);
	//		ushort width;		buffer.read(width);
	//		ushort height;		buffer.read(height);
	//		uint itemsVerMajor;	buffer.read(itemsVerMajor);
	//		uint itemsVerMinor;	buffer.read(itemsVerMinor);
	//		
	//		Nullable!Version map = Version(ver, 0);
	//		Nullable!Version items = Version(itemsVerMajor, itemsVerMinor);
	//		enforceEx!MapVersionNotSupported(isSupported(map, items));
	//		
	//		if (onHeader !is null)
	//			onHeader(map, width, height, items);
	//	}
	//	
	//	char[] readStr(Stream buffer)
	//	{
	//		ushort len;
	//		buffer.read(len);
	//		return buffer.readString(len);
	//	}
		
	}
}