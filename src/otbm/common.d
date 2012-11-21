module otbm.common;

public {
	import std.conv : to;
	import std.array;
	import std.algorithm;
	import std.exception : enforceEx;
	import std.stdio : writeln;
}

struct Stream
{
	void[] *data;
	size_t pos;
	
	this(ref void[] data)
	{
		this.data = &data;
	}
	
	void peek(T)(out T type)
	{
		type = *cast(T*) (*data).ptr[pos..pos+type.sizeof];
	}
	void read(T)(out T type)
	{
		assert(pos+type.sizeof <= data.length);
		peek(type);
		pos += type.sizeof;
	}
	string readString(size_t length)
	{
		assert(pos+length <= data.length);
		pos +=length;
		return to!string((*data).ptr[pos-length..pos]);
	}
	bool end()
	{
		return pos >= data.length;
	}
	void seekCur(size_t offset)
	{
		assert(pos+offset <= data.length);
	}
	private:
	T read_escaped(T)(size_t length)
	{
		//TODO
	}
}