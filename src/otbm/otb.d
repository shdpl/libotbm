module otbm.otb;

public {
	import otbm.parser;
}

private {
	import std.bitmanip;
	
	import otbm.common;
}

extern (C)
{
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
	 OTB file format parser instance
	 */
	struct ParserOTB {
		
		/**
		 Informs user about item type definition
		 */
		void function(ItemType) onItemType;
		/**
		 Informs user about OTB Version
		 */
		void function(VersionInfo) onOTBVersion;
		
		/**
		 Start to parse OTB file from stream (make sure you configured your callbacks before invocation)
		 */
		void parse(void[] data)
		{
			enum RootAttrib : ubyte
			{
				VERSION = 0x1
			}
			alias ushort DataSize;
			
			auto stream = Stream(data);
			ubyte cb;
			ushort len;
			RootAttrib ra;
			VersionGeneral vOtb;
			stream.read(vOtb.major);
			enforceEx!OTBMVersionNotSupported(isSupported(vOtb), text("version=",vOtb));
			stream.read(cb);
			enforceEx!MapFormatBroken(cb == NODE_START);
			stream.read(cb);
			switch(cb)
			{
				case 0:
					uint flags;
					stream.read(flags);
					stream.read(cast(ubyte) ra);
					switch(ra)
					{
						case RootAttrib.VERSION:
							immutable GENERIC_OTB = 0xffffffff;
							DataSize ds;
							stream.read(ds);
							enforceEx!MapFormatBroken(ds == VersionInfo.sizeof);
							VersionInfo vi;
							stream.read(vi.otb_version);
							stream.read(vi.client_version);
							stream.read(vi.build);
							stream.readString(128);
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
			for(stream.read(cb); cb != NODE_END; stream.read(cb) )
			{
				ItemType it;
				stream.read(cast(ubyte) it.group);
				stream.read(it.flags.f);
				
				ushort size;
				stream.read(cb);
				while (cb != NODE_END)
				{
					stream.read(size);
					switch(cb)
					{
						case ItemAttribute.ServerId:
							enforceEx!MapFormatBroken(size == it.serverId.sizeof);
							stream.read(it.serverId);
						break;
						case ItemAttribute.ClientId:
							enforceEx!MapFormatBroken(size == it.clientId.sizeof);
							stream.read(it.clientId);
						break;
						case ItemAttribute.Speed:
							enforceEx!MapFormatBroken(size == it.speed.sizeof);
							stream.read(it.speed);
						break;
						case ItemAttribute.Light2:
							enforceEx!MapFormatBroken(size == it.light2.sizeof);
							stream.read(it.light2.level);
							stream.read(it.light2.color);
						break;
						case ItemAttribute.TopOrder:
							enforceEx!MapFormatBroken(size == it.topOrder.sizeof);
							stream.read(it.topOrder);
						break;
						case ItemAttribute.WareId:
							enforceEx!MapFormatBroken(size == it.wareId.sizeof);
							stream.read(it.wareId);
						break;
						case ItemAttribute.Name:
							it.name = stream.readString(size);
						break;
						case ItemAttribute.SpriteHash:
							enforceEx!MapFormatBroken(size == it.hash.sizeof);
							stream.read(it.hash);
						break;
						case ItemAttribute.MiniMapColor:
							enforceEx!MapFormatBroken(size == it.miniMapColor.sizeof);
							stream.read(it.miniMapColor);
						break;
						case ItemAttribute.Attribute07:
							stream.seekCur(size);
						break;
						case ItemAttribute.Attribute08:
							stream.seekCur(size);
						break;
						default:
							enforceEx!MapFormatBroken(false);
					}
					stream.read(cb);
				}
				if (onItemType !is null)
				{
					onItemType(it);
				}
			}
			enforceEx!MapFormatBroken(stream.end);
		}
	}
}