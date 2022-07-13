package be.seeseemelk.comboot.packets;

import java.nio.ByteBuffer;

public class Buffer
{
	private final ByteBuffer buffer;

	public Buffer(ByteBuffer buffer)
	{
		this.buffer = buffer;
	}

	public Buffer(byte[] buffer)
	{
		this(ByteBuffer.wrap(buffer));
	}

	public Buffer(int bytes)
	{
		this(ByteBuffer.allocate(bytes));
	}

	public int getLength()
	{
		return buffer.limit();
	}

	public Buffer sliceLen(int index, int length)
	{
		return new Buffer(buffer.slice(index, length));
	}

	public Buffer slicePos(int index, int endIndex)
	{
		return sliceLen(index, endIndex - index);
	}

	public Buffer skipLast(int bytes)
	{
		return slicePos(0, getLength() - bytes);
	}

	public Buffer skipFirst(int bytes)
	{
		return slicePos(bytes, getLength());
	}

	public Buffer takeLast(int bytes)
	{
		return slicePos(getLength() - bytes, getLength());
	}

	public Buffer takeFirst(int bytes)
	{
		return slicePos(0, bytes);
	}

	public byte getByteRead(int index)
	{
		return buffer.get(index);
	}

	public int getByte(int index)
	{
		return Byte.toUnsignedInt(getByteRead(index));
	}

	public short getShort(int index)
	{
		int low = getByte(index) & 0xFF;
		int high = getByte(index + 1) & 0xFF;
		return (short) (low | (high << 8));
	}

	/*public int getInt(int index)
	{
		int low = getShort(index) & 0xFFFF;
		int high = getShort(index + 2) & 0xFFFF;
		return low | (high << 16);
	}*/

	public void setByte(int index, byte value)
	{
		buffer.put(index, value);
	}

	public void setByte(int index, int value)
	{
		setByte(index, (byte) value);
	}

	public void setShort(int index, short value)
	{
		setByte(index, (byte) (value & 0xFF));
		setByte(index + 1, (byte) (value >> 8));
	}

	public byte[] array()
	{
		return buffer.array();
	}
}
