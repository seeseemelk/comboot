package be.seeseemelk.comboot.packets;

import lombok.experimental.UtilityClass;

@UtilityClass
public class ComSerializer
{
	public Buffer serialize(ComPacket packet)
	{
		Buffer buffer = new Buffer(packet.getLength() + 4);
		buffer.setByte(0, packet.getType().getValue());
		buffer.setByte(1, packet.getLength());
		packet.writeTo(buffer.sliceLen(2, packet.getLength()));

		int checksum = calculateChecksum(buffer.skipLast(2));
		buffer.setByte(buffer.getLength() - 2, (byte) checksum);
		buffer.setByte(buffer.getLength() - 1, (byte) (checksum >> 8));

		return buffer;
	}

	public ComPacket deserialize(Buffer buffer)
	{
		ComPacket packet;
		int type = buffer.getByte(0);
		switch (type)
		{
		case 1:
			packet = new ComHello();
			break;
		case 2:
			packet = new ComRead();
			break;
		default:
			throw new RuntimeException(String.format("Invalid ComPacket type: %d", type));
		}
		int length = buffer.getByte(1);
		if (length == buffer.skipLast(2).getLength())
			throw new RuntimeException("Buffer badly sized");
		packet.readFrom(buffer.slicePos(2, buffer.getLength() - 2));

		int expectedChecksum = calculateChecksum(buffer.skipLast(2));
		int actualChecksum = buffer.getShort(buffer.getLength() - 2);
		if (expectedChecksum != actualChecksum)
			throw new RuntimeException("Incorrect checksum");

		return packet;
	}

	public int calculateChecksum(Buffer buffer)
	{
		int c0 = 0;
		int c1 = 0;
		for (int i = 0; i < buffer.getLength(); i++)
		{
			c0 = (c0 + buffer.getByte(i)) % 255;
			c1 = (c1 + c0) % 255;
		}
		return (c0) | (c1 << 8);
	}
}
