package be.seeseemelk.comboot;

import lombok.Data;
import lombok.RequiredArgsConstructor;

import java.io.IOException;
import java.nio.channels.SeekableByteChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

@Data
@RequiredArgsConstructor
public class Disk implements AutoCloseable
{
	private int id;
	private final DiskParameters parameters;
	private final SeekableByteChannel channel;

	public static Disk openFile(Path file) throws IOException
	{
		System.out.format("Opening file %s%n", file);
		DiskParameters parameters = DiskParameters.getDiskParametersForLength(Files.size(file));
		SeekableByteChannel channel = channel = Files.newByteChannel(file, StandardOpenOption.READ, StandardOpenOption.WRITE);
		return new Disk(parameters, channel);
	}

	@Override
	public void close() throws IOException
	{
		channel.close();
	}
}
