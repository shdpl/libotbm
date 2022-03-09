module otbm.common;

public {
	import std.conv : to;
	import std.array;
	import std.algorithm;
	import std.exception : enforce;
	import std.stdio : writeln;
}

private {
	import std.conv : text;
	import std.process : executeShell;
}

immutable ubyte NODE_START	= 0xfe;
immutable ubyte NODE_END	= 0xff;
immutable ubyte NODE_ESCAPE	= 0xfd;

struct Stream
{
	void[] *data;
	size_t pos;
	
	this(ref void[] data)
	{
		this.data = &data;
	}
	
	auto peek(T)(out T type)
	{
		return peek_escaped(type);
	}
	void read(T)(out T type)
	{
		assert(pos+type.sizeof <= data.length);
		pos += peek_escaped(type);
	}
	string readString(size_t length)
	{
		assert(pos+length <= data.length);
		auto tmp = new char[length]; //FIXME: get rid of allocation
		auto delta = peek_escaped_byte(cast(ubyte*)tmp, length);
		pos += delta;
		return to!string(tmp);
	}
	bool end()
	{
		return pos >= data.length;
	}
	void seekCur(size_t offset)
	{
		assert(pos+offset <= data.length && pos+offset >= 0);
		pos += offset;
	}
			
	auto doDebug(uint lines = 6)
	{
		auto cmd = text(
				"hexdump -C /home/shd/nawia/windows/nawia-content/src/data/items/items.otb -s "
				,pos > 16 ? pos-16 : pos
				," | head -n",lines);
		auto stdout = executeShell(cmd);
		writeln(stdout);
	}
	private:
	size_t peek_escaped(T)(out T type)
	{
		return peek_escaped_byte(cast(ubyte*) &type, type.sizeof);
	}
	size_t peek_escaped_byte(ubyte* t, size_t len)
	{
		size_t skipped = 0;
		for(size_t i = 0; i < len+skipped; i++)
		{
			if( *(cast(ubyte*) (*data).ptr+pos+i) == NODE_ESCAPE )
			{
					skipped++;
					i++;
			}
			t[i-skipped] = *(cast(ubyte*) (*data).ptr+pos+i);
		}
		return len+skipped;
	}
}
