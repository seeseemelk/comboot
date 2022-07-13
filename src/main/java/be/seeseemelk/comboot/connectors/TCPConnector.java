package be.seeseemelk.comboot.connectors;

import be.seeseemelk.comboot.packets.Buffer;
import lombok.RequiredArgsConstructor;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;

public class TCPConnector implements Connector, AutoCloseable
{
	private final Socket socket;
	private final OutputStream outputStream;
	private final InputStream inputStream;

	public TCPConnector(String host, int port) throws IOException
	{
		socket = new Socket(host, port);
		outputStream = socket.getOutputStream();
		inputStream = socket.getInputStream();
	}

	@Override
	public void send(Buffer buffer) throws IOException
	{
		outputStream.write(buffer.array());
	}

	@Override
	public Buffer receive() throws IOException
	{
		Buffer buffer = new Buffer(256 + 4);
		int type = inputStream.read();
		int length = inputStream.read();
		buffer.setByte(0, (byte) type);
		buffer.setByte(1, (byte) length);
		for (int i = 0; i < length; i++)
			buffer.setByte(i + 2, (byte) inputStream.read());
		buffer = buffer.takeFirst(length + 4);
		buffer.setByte(buffer.getLength() - 2, (byte) inputStream.read());
		buffer.setByte(buffer.getLength() - 1, (byte) inputStream.read());
		return buffer.takeFirst(length + 4);
	}

	@Override
	public void close() throws IOException
	{
		socket.close();
	}
}
