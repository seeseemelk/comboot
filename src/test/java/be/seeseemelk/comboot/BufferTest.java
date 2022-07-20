package be.seeseemelk.comboot;

import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;

public class BufferTest
{
	@Test
	public void getIntForZeroValue()
	{
		Buffer buffer = bufferOf(0, 0, 0, 0);
		assertThat(buffer.getInt(0), equalTo(0L));
	}

	@Test
	public void getIntForNonZeroValue()
	{
		Buffer buffer = bufferOf(1, 0, 0, 0);
		assertThat(buffer.getInt(0), equalTo(1L));
	}

	private Buffer bufferOf(int... values)
	{
		return new Buffer(arrayOf(values));
	}

	private byte[] arrayOf(int... values)
	{
		byte[] array = new byte[values.length];
		for (int i = 0; i < values.length; i++)
			array[i] = (byte) values[i];
		return array;
	}
}
