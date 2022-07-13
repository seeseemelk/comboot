package be.seeseemelk.comboot.connectors;

import be.seeseemelk.comboot.packets.Buffer;
import be.seeseemelk.comboot.packets.ComPacket;
import be.seeseemelk.comboot.packets.ComSerializer;

import java.io.IOException;

public interface Connector
{
	void send(Buffer buffer) throws IOException;
	Buffer receive() throws IOException;

	default void write(ComPacket packet) throws IOException
	{
		send(ComSerializer.serialize(packet));
	}

	default ComPacket read() throws IOException
	{
		return ComSerializer.deserialize(receive());
	}
}
