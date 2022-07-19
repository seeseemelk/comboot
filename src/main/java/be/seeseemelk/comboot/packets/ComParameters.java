package be.seeseemelk.comboot.packets;

import be.seeseemelk.comboot.Buffer;
import be.seeseemelk.comboot.DiskParameters;
import lombok.Data;
import lombok.experimental.SuperBuilder;

@Data
@SuperBuilder
public class ComParameters implements ComPacket
{
	private int disk;
	private DiskParameters parameters;

	@Override
	public ComType getType()
	{
		return ComType.PARAMETERS;
	}

	@Override
	public int getLength()
	{
		return 4;
	}

	@Override
	public void writeTo(Buffer buffer)
	{
		buffer.setByte(0, disk);
		buffer.setByte(1, parameters.getHeadsPerTrack());
		buffer.setByte(2, parameters.getSectorsPerTrack());
		buffer.setByte(3, parameters.getNumberOfTracks());
	}

	@Override
	public void readFrom(Buffer buffer)
	{
		disk = buffer.getByte(0);
		parameters.setHeadsPerTrack(buffer.getByte(1));
		parameters.setSectorsPerTrack(buffer.getByte(2));
		parameters.setNumberOfTracks(buffer.getByte(3));
	}
}
