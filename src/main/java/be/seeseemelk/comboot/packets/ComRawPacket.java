package be.seeseemelk.comboot.packets;

import lombok.Getter;

public class ComRawPacket
{
	@Getter
	private ComType type;
	private byte[] data;
	private int checksum;

	public int getLength()
	{
		return data.length;
	}
}
