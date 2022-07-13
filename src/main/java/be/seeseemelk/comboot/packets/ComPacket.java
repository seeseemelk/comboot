package be.seeseemelk.comboot.packets;

import java.nio.ByteBuffer;

public interface ComPacket
{
	ComType getType();
	int getLength();
	void writeTo(Buffer buffer);
	void readFrom(Buffer buffer);
}
