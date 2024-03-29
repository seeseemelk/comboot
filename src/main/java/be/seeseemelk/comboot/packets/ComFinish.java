package be.seeseemelk.comboot.packets;

import be.seeseemelk.comboot.Buffer;
import lombok.Data;

@Data
public class ComFinish implements ComPacket
{

	@Override
	public ComType getType()
	{
		return ComType.FINISH;
	}

	@Override
	public int getLength()
	{
		return 0;
	}

	@Override
	public void writeTo(Buffer buffer)
	{
	}

	@Override
	public void readFrom(Buffer buffer)
	{
	}
}
