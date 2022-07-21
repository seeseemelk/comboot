package be.seeseemelk.comboot;

import be.seeseemelk.comboot.connectors.Connector;
import be.seeseemelk.comboot.packets.*;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SeekableByteChannel;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

@RequiredArgsConstructor
public class ComBootServer implements AutoCloseable
{
	@Setter
	@Getter
	private boolean autoBoot = false;
	private Map<Integer, Disk> disks = new HashMap<>();
	private final Connector connector;
	private boolean booted = false;
	private Disk writingDisk = null;

	public void setDisk(int id, Disk disk)
	{
		disk.setId(id);
		disks.put(id, disk);
	}

	public Disk getDisk(int id)
	{
		return disks.get(id);
	}

	public void openFile(int disk, Path file) throws IOException
	{
		setDisk(disk, Disk.openFile(file));
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
				case WRITE -> handleWrite((ComWrite) packet);
				case DATA -> handleData((ComData) packet);
				case FINISH -> {}
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
			sendDiskParameters();
			System.out.println("Sending boot request");
			connector.write(welcome);
			booted = true;
		}
	}

	private void sendDiskParameters(Disk disk) throws IOException
	{
		DiskParameters parameters = disk.getParameters();
		ComParameters packet = ComParameters.builder()
			.disk(disk.getId())
			.parameters(parameters)
			.build();
		System.out.format("Sending drive parameters for disk %d: %s%n", disk.getId(), packet);
		connector.write(packet);
	}

	private void sendDiskParameters() throws IOException
	{
		for (Disk disk : disks.values())
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
		long position = packet.getLba() * 512;
		SeekableByteChannel channel = getDisk(packet.getDisk()).getChannel();
		channel.position(position);
		int bytes = packet.getSectorCount() * 512;
		System.out.format("Reading %d bytes at 0x%08X%n", bytes, position);
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

	private void handleWrite(ComWrite packet) throws IOException
	{
		long position = packet.getLba() * 512;
		int bytes = packet.getSectorCount() * 512;
		System.out.format("Writing %d bytes at 0x%08X%n", bytes, position);

		writingDisk = getDisk(packet.getDisk());
		writingDisk.getChannel().position(position);
	}

	private void handleData(ComData packet) throws IOException
	{
		if (writingDisk != null)
		{
			byte[] data = packet.getData();
			ByteBuffer buffer = ByteBuffer.wrap(data);
			writingDisk.getChannel().write(buffer);
		}
	}

	@Override
	public void close() throws IOException
	{
		for (Disk disk : disks.values())
			disk.close();
	}
}
