import otbm.parser;
import std.stream : BufferedFile;
import std.stdio : writeln;
import std.array;

enum FileType : ubyte
{
	Unknown,
	OTBM,
	OTB
}

int main(string[] args)
{
	if (args.length != 3)
	{
		return usage(args[0]);
	}
	auto f = new BufferedFile();
	f.open(args[2]);
	
	auto ft = detect_type(args[2]);
	if (ft == FileType.Unknown)
	{
		writeln("Could recognize input file extension");
		return 2;
	}
	
	switch(args[1])
	{
		case "chk":
			check(f, ft);
		break;
		case "ls":
			list(f, ft);
		break;
		default:
			return usage(args[0]);
	}
	return 0;
}

bool usage(string executable)
{
	writeln(
		"Usage: ",executable," command path/to/file.otb\n",
		" supported commands",
		"  chk ",
//		"  ed ",
//		"  rm ",
		"  ls "
	);
	return 1;
}

FileType detect_type(string file_path)
{
	if (file_path[$-4 .. $] == ".otb")
	{
		return FileType.OTB;
	}
	else if(file_path[$-5 .. $] == ".otbm")
	{
		return FileType.OTBM;
	}
	else
	{
		return FileType.Unknown;
	}
}

void check(Stream f, FileType ft)
{
	switch(ft)
	{
		case FileType.OTBM:
			parse(f);
		break;
		case FileType.OTB:
			parseOTB(f);
		break;
		default:
			throw new Error(text("Validation of file type ",ft," not implemented!"));
	}
}

void list(Stream f, FileType ft)
{
	switch(ft)
	{
		case FileType.OTB:
			listOTB(f, ft);
		break;
		default:
			throw new Error(text("List of file type ",ft," not implemented!"));
	}
	check(f,ft);
}

void listOTB(Stream f,  FileType ft)
{
	onItemType = delegate(ItemType it)
	{
		writeln(
			"Name:         ",it.name,"\n",
			"Group:        ",it.group,"\n",
			"Flags:        ",it.flags,"\n",
			"ServerId:     ",it.serverId,"\n",
			"ClientId:     ",it.clientId,"\n",
			"Speed:        ",it.speed,"\n",
			"Light2:       ",it.light2,"\n",
			"TopOrder:     ",it.topOrder,"\n",
			"WareId:       ",it.wareId,"\n",
			"Hash:         ",it.hash,"\n",
			"MiniMapColor: ",it.miniMapColor,"\n"
		);
	};
}
