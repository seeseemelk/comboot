package be.seeseemelk.comboot.packets;

import be.seeseemelk.comboot.Buffer;

public interface ComPacket
{
	ComType getType();
	int getLength();
	void writeTo(Buffer buffer);
	void readFrom(Buffer buffer);
}
