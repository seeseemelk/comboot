package be.seeseemelk.comboot.connectors;

import be.seeseemelk.comboot.Buffer;
import be.seeseemelk.comboot.packets.ComPacket;
import be.seeseemelk.comboot.ComSerializer;

import java.io.IOException;

public interface Connector
{
	void send(Buffer buffer) throws IOException;
	Buffer receive() throws IOException;
	boolean isConnected() throws IOException;

	default void write(ComPacket packet) throws IOException
	{
		Buffer buffer = ComSerializer.serialize(packet);
		System.out.format("Sending data: %s%n", buffer);
		send(buffer);
	}

	default ComPacket read() throws IOException
	{
		Buffer data = receive();
		System.out.format("Got data: %s%n", data);
		return ComSerializer.deserialize(data);
	}
}
