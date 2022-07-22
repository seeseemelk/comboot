package be.seeseemelk.comboot.packets;

import be.seeseemelk.comboot.Buffer;
import lombok.Data;

@Data
public class ComData implements ComPacket
{
	private byte[] data;

	@Override
	public ComType getType()
	{
		return ComType.DATA;
	}

	@Override
	public int getLength()
	{
		return data.length;
	}

	@Override
	public void writeTo(Buffer buffer)
	{
		buffer.setBytes(0, data);
	}

	@Override
	public void readFrom(Buffer buffer)
	{
		data = buffer.getBytes(0, buffer.getLength());
	}
}
