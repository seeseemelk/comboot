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
public class ComWrite implements ComPacket
{
	private int disk;
	private int sectorCount;
	private long lba;

	@Override
	public ComType getType()
	{
		return ComType.WRITE;
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
		disk = buffer.getByte(0);
		sectorCount = buffer.getByte(1);
		lba = buffer.getInt(2);
	}
}
