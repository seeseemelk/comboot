package be.seeseemelk.comboot;

import be.seeseemelk.comboot.connectors.Connector;
import be.seeseemelk.comboot.packets.*;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SeekableByteChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.HashMap;
import java.util.Map;

@RequiredArgsConstructor
public class ComBootServer implements AutoCloseable
{
	@Setter
	@Getter
	private boolean autoBoot = false;
	private Map<Integer, DiskParameters> diskParameters = new HashMap<>();
	private final Connector connector;
	private SeekableByteChannel channel;
	private boolean booted = false;

	public void openFile(int disk, Path file) throws IOException
	{
		close();
		System.out.format("Opening file %s%n", file);
		DiskParameters parameters = DiskParameters.getDiskParametersForLength(Files.size(file));
		channel = Files.newByteChannel(file, StandardOpenOption.READ);
		diskParameters.put(disk, parameters);
		sendDiskParameters(disk);
	}

	public void openFile(int disk, String file) throws IOException
	{
		openFile(disk, Paths.get(file));
	}

	public void run() throws IOException
	{
		while (connector.isConnected())
		{
			try
			{
				ComPacket packet = connector.read();
				System.out.format("Received packet: %s%n", packet);
				switch (packet.getType())
				{
				case HELLO -> handleHello((ComHello) packet);
				case READ -> handleRead((ComRead) packet);
				}
			}
			catch (ComBootException e)
			{
				e.printStackTrace();
			}
		}
	}

	public void sendBoot() throws IOException
	{
		if (!booted)
		{
			ComWelcome welcome = ComWelcome.builder()
				.numFloppies(1)
				.numDisks(0)
				.build();
			connector.write(welcome);
			sendDiskParameters();
			booted = true;
		}
	}

	private void sendDiskParameters(int disk) throws IOException
	{
		DiskParameters parameters = diskParameters.get(disk);
		ComParameters packet = ComParameters.builder()
			.disk(disk)
			.parameters(parameters)
			.build();
		connector.write(packet);
	}

	private void sendDiskParameters() throws IOException
	{
		for (int disk : diskParameters.keySet())
			sendDiskParameters(disk);
	}

	private void handleHello(ComHello packet) throws IOException
	{
		booted = false;
		System.out.println("Sent welcome");
		if (isAutoBoot())
			sendBoot();
	}

	private void handleRead(ComRead packet) throws IOException
	{
		int position = packet.getLBA() * 512;
		channel.position(position);
		int bytes = packet.getSectorCount() * 512;
		System.out.format("Reading %d bytes at 0x%04X%n", bytes, position);
		while (bytes > 0)
		{
			int bytesInPacket = Math.min(bytes, 64);
			bytes -= bytesInPacket;

			ByteBuffer buffer = ByteBuffer.allocate(bytesInPacket);
			channel.read(buffer);

			ComData data = new ComData();
			data.setData(buffer.array());
			connector.write(data);
		}
		ComFinish finish = new ComFinish();
		connector.write(finish);
	}

	@Override
	public void close() throws IOException
	{
		if (channel != null)
		{
			channel.close();
			channel = null;
		}
	}
}
