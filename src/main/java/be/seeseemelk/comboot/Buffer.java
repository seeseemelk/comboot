package be.seeseemelk.comboot;

import java.nio.ByteBuffer;
import java.util.HexFormat;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class Buffer
{
	private static final HexFormat FORMAT = HexFormat.of();

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

	public int getShort(int index)
	{
		int low = getByte(index) & 0xFF;
		int high = getByte(index + 1) & 0xFF;
		return low | (high << 8);
	}

	public void setByte(int index, byte value)
	{
		buffer.put(index, value);
	}

	public void setBytes(int index, byte[] value)
	{
		for (int i = 0; i < value.length; i++)
			setByte(index + i, value[i]);
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

	public Stream<Byte> stream()
	{
		return Stream
			.iterate(0, i -> i < buffer.limit(), i -> i + 1)
			.map(this::getByteRead);
	}

	@Override
	public String toString()
	{
		return stream()
			.map(FORMAT::toHexDigits)
			.collect(Collectors.joining(" "));
	}
}
