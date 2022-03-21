#include <stddef.h>
#include <stdint.h>

typedef struct tmp {
    size_t length;
    char *ptr;
} Tmp;

enum
{
	ITEM_GROUP_NONE = 0u,
	ITEM_GROUP_GROUND = 1u,
	ITEM_GROUP_CONTAINER = 2u,
	ITEM_GROUP_WEAPON = 3u,
	ITEM_GROUP_AMMUNITION = 4u,
	ITEM_GROUP_ARMOR = 5u,
	ITEM_GROUP_CHARGES = 6u,
	ITEM_GROUP_TELEPORT = 7u,
	ITEM_GROUP_MAGICFIELD = 8u,
	ITEM_GROUP_WRITEABLE = 9u,
	ITEM_GROUP_KEY = 10u,
	ITEM_GROUP_SPLASH = 11u,
	ITEM_GROUP_FLUID = 12u,
	ITEM_GROUP_DOOR = 13u,
	ITEM_GROUP_DEPRECATED = 14u,
	ITEM_GROUP_LAST = 15u,
};
typedef uint8_t ItemGroup;

enum {
	ITEM_FLAG_BLOCK_SOLID = 1 << 0,
	ITEM_FLAG_BLOCK_PROJECTILE = 1 << 1,
	ITEM_FLAG_BLOCK_PATHFIND = 1 << 2,
	ITEM_FLAG_HAS_HEIGHT = 1 << 3,
	ITEM_FLAG_USABLE = 1 << 4,
	ITEM_FLAG_PICKUPABLE = 1 << 5,
	ITEM_FLAG_MOVABLE = 1 << 6,
	ITEM_FLAG_STACKABLE = 1 << 7,
	ITEM_FLAG_FLOORCHANGEDOWN = 1 << 8,
	ITEM_FLAG_FLOORCHANGENORTH = 1 << 9,
	ITEM_FLAG_FLOORCHANGEEAST = 1 << 10,
	ITEM_FLAG_FLOORCHANGESOUTH = 1 << 11,
	ITEM_FLAG_FLOORCHANGEWEST = 1 << 12,
	ITEM_FLAG_ALWAYSONTOP = 1 << 13,
	ITEM_FLAG_READABLE = 1 << 14,
	ITEM_FLAG_ROTABLE = 1 << 15,
	ITEM_FLAG_HANGABLE = 1 << 16,
	ITEM_FLAG_VERTICAL = 1 << 17,
	ITEM_FLAG_HORIZONTAL = 1 << 18,
	ITEM_FLAG_CANNOTDECAY = 1 << 19,
	ITEM_FLAG_ALLOWDISTREAD = 1 << 20,
	ITEM_FLAG_UNUSED = 1 << 21,
	ITEM_FLAG_CLIENTCHARGES = 1 << 22, //deprecated
	ITEM_FLAG_LOOKTHROUGH = 1 << 23,
	ITEM_FLAG_ANIMATION = 1 << 24,
	ITEM_FLAG_WALKSTACK = 1 << 25
};
typedef uint32_t ItemFlags;

typedef struct
{
	uint16_t level;
	uint16_t color;
} Light;

typedef struct itemType {
	Tmp name;
	ItemGroup group;
	ItemFlags flags;
	uint16_t serverId;
	uint16_t clientId;
	uint16_t speed;
	Light light2;
	uint8_t topOrder;
	uint16_t wareId;
	uint8_t hash[16LLU];
	uint16_t miniMapColor;
} ItemType;

typedef struct versionInfo
{
    // Ignoring var otb_version alignment 1
    uint32_t otb_version;
    uint32_t client_version;
    uint32_t build;
    char csd[128LLU];
} VersionInfo;

typedef struct parserOTB {
	void (*onItemType) (ItemType);
	void (*onOTBVersion) (VersionInfo);
} ParserOTB;

void parseOTB(ParserOTB parser, size_t len, void* data);
