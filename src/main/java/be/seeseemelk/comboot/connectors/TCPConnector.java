package be.seeseemelk.comboot.connectors;

import be.seeseemelk.comboot.Buffer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;

public class TCPConnector implements Connector, AutoCloseable
{
	private final Socket socket;
	private final OutputStream outputStream;
	private final InputStream inputStream;
	private boolean closed = false;

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
		outputStream.flush();
	}

	@Override
	public Buffer receive() throws IOException
	{
		Buffer buffer = new Buffer(256 + 4);
		byte type = readByte();
		byte length = readByte();
		buffer.setByte(0, type);
		buffer.setByte(1, length);
		for (int i = 0; i < length; i++)
			buffer.setByte(i + 2, readByte());
		buffer = buffer.takeFirst(length + 4);
		buffer.setByte(buffer.getLength() - 2, readByte());
		buffer.setByte(buffer.getLength() - 1, readByte());
		return buffer.takeFirst(length + 4);
	}

	public byte readByte() throws IOException
	{
		int value = inputStream.read();
		if (value == -1)
		{
			closed = true;
			throw new IOException("Closed");
		}
		return (byte) value;
	}

	@Override
	public void close() throws IOException
	{
		socket.close();
	}

	@Override
	public boolean isConnected()
	{
		return socket.isConnected() && !socket.isClosed() && !closed;
	}
}
