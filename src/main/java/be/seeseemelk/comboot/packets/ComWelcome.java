package be.seeseemelk.comboot.packets;

import be.seeseemelk.comboot.Buffer;
import lombok.Data;
import lombok.experimental.SuperBuilder;

@Data
@SuperBuilder
public class ComWelcome implements ComPacket
{
	private int numDisks;
	private int numFloppies;

	@Override
	public ComType getType()
	{
		return ComType.WELCOME;
	}

	@Override
	public int getLength()
	{
		return 2;
	}

	@Override
	public void writeTo(Buffer buffer)
	{
		buffer.setByte(0, numFloppies);
		buffer.setByte(1, numDisks);
	}

	@Override
	public void readFrom(Buffer buffer)
	{
		numFloppies = buffer.getByte(0);
		numDisks = buffer.getByte(1);
	}
}
