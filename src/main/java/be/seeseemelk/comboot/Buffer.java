package be.seeseemelk.comboot;

import java.nio.ByteBuffer;
import java.util.HexFormat;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class Buffer
{
	private static final HexFormat FORMAT = HexFormat.of();

	private final ByteBuffer buffer;

	private final int offset;
	private final int length;

	public Buffer(ByteBuffer buffer, int offset, int length)
	{
		if (offset < 0 || offset >= buffer.limit())
			throw new IllegalArgumentException("Invalid offset");
		if (length < 0 || offset + length > buffer.limit())
			throw new IllegalArgumentException("Invalid length");
		this.buffer = buffer;
		this.offset = offset;
		this.length = length;
	}

	public Buffer(ByteBuffer buffer)
	{
		this(buffer, 0, buffer.limit());
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
		return length;
	}

	public Buffer sliceLen(int index, int length)
	{
		return new Buffer(buffer, index + offset, length);
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

	public int getByte(int index)
	{
		return Byte.toUnsignedInt(buffer.get(index + offset));
	}

	public byte getByteAsByte(int index)
	{
		return (byte) getByte(index);
	}

	public int getShort(int index)
	{
		int low = getByte(index) & 0xFF;
		int high = getByte(index + 1) & 0xFF;
		return low | (high << 8);
	}

	public long getInt(int index)
	{
		long low = getShort(index);
		long high = getShort(index + 2);
		return low | (high << 16L);
	}

	public void setByte(int index, byte value)
	{
		buffer.put(index + offset, value);
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

	public void setShort(int index, int value)
	{
		setByte(index, (byte) (value & 0xFF));
		setByte(index + 1, (byte) (value >> 8));
	}

	public void setInt(int index, int value)
	{
		setShort(index, (int) (value & 0xFFFF));
		setShort(index + 2, (int) ((value >> 16) & 0xFFFF));
	}

	public byte[] array()
	{
		return buffer.array();
	}

	public Stream<Byte> stream()
	{
		return Stream
			.iterate(0, i -> i < length, i -> i + 1)
			.map(this::getByteAsByte);
	}

	@Override
	public String toString()
	{
		return stream()
			.map(FORMAT::toHexDigits)
			.collect(Collectors.joining(" "));
	}

	public byte[] getBytes(byte[] destination, int start, int length)
	{
		for (int write = 0; write < length; write++)
			destination[write] = getByteAsByte(write + start);
		return destination;
	}

	public byte[] getBytes(int start, int length)
	{
		return getBytes(new byte[length], start, length);
	}
}
