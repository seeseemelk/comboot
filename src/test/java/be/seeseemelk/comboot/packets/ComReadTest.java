package be.seeseemelk.comboot.packets;

import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;

public class ComReadTest
{
	@Test
	public void testGetLBA()
	{
		assertThat(getLBA(1, 0, 0), equalTo(0));
		assertThat(getLBA(2, 0, 0), equalTo(1));
		assertThat(getLBA(3, 0, 0), equalTo(2));
		assertThat(getLBA(18, 0, 0), equalTo(17));

		assertThat(getLBA(1, 0, 1), equalTo(18));
		assertThat(getLBA(2, 0, 1), equalTo(19));
		assertThat(getLBA(3, 0, 1), equalTo(20));
		assertThat(getLBA(18, 0, 1), equalTo(35));

		assertThat(getLBA(1, 1, 0), equalTo(36));
	}

	private int getLBA(int sector, int cylinder, int head)
	{
		return ComRead.builder()
			.sector(sector)
			.cylinder(cylinder)
			.head(head)
			.build()
			.getLBA();
	}
}
