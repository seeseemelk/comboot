package be.seeseemelk.comboot.packets;

import lombok.Data;

@Data
public class ComHello implements ComPacket
{

	@Override
	public ComType getType()
	{
		return ComType.HELLO;
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
