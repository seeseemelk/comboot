package be.seeseemelk.comboot.packets;

import be.seeseemelk.comboot.Buffer;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@Data
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class ComRead implements ComPacket
{
	private int drive;
	private int sectorCount;
	private int cylinder;
	private int sector;
	private int head;

	@Override
	public ComType getType()
	{
		return ComType.READ;
	}

	@Override
	public int getLength()
	{
		return 6;
	}

	@Override
	public void writeTo(Buffer buffer)
	{
		throw new UnsupportedOperationException();
	}

	@Override
	public void readFrom(Buffer buffer)
	{
		drive = buffer.getByte(0);
		sectorCount = buffer.getByte(1);
		cylinder = buffer.getShort(2);
		sector = buffer.getByte(4);
		head = buffer.getByte(5);
	}

	public int getLBA()
	{
		int lba = 0;
		lba = (cylinder * 2 + head) * 18 + (sector - 1);
		return lba;
	}
}
