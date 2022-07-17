package be.seeseemelk.comboot;

import be.seeseemelk.comboot.packets.ComPacket;
import lombok.experimental.StandardException;

@StandardException
public class ComBootException extends RuntimeException
{
	private Buffer buffer;
	private ComPacket packet;

	public ComBootException(String message, Buffer buffer, ComPacket packet)
	{
		this(message);
		this.buffer = buffer;
		this.packet = packet;
	}

	@Override
	public String toString()
	{
		return "ComBootException(buffer='" + buffer + "', packet=" + packet + ")";
	}
}
