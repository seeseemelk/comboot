package be.seeseemelk.comboot;

import lombok.Data;
import lombok.experimental.SuperBuilder;

import java.util.Set;

@Data
@SuperBuilder
public class DiskParameters
{
	public static final DiskParameters DISK_PARAMETERS_1440 = DiskParameters.builder()
		.headsPerTrack(2)
		.numberOfTracks(80)
		.sectorsPerTrack(18)
		.build();

	public static final DiskParameters DISK_PARAMETERS_720 = DiskParameters.builder()
		.headsPerTrack(2)
		.numberOfTracks(40)
		.sectorsPerTrack(18)
		.build();

	public static final DiskParameters DISK_PARAMETERS_360 = DiskParameters.builder()
		.headsPerTrack(2)
		.numberOfTracks(40)
		.sectorsPerTrack(9)
		.build();

	public static final Set<DiskParameters> COMMON_PARAMETERS = Set.of(
		DISK_PARAMETERS_360,
		DISK_PARAMETERS_720,
		DISK_PARAMETERS_1440
	);

	public static DiskParameters getDiskParametersForLength(long length)
	{
		for (DiskParameters dp : COMMON_PARAMETERS)
		{
			if (dp.getSizeInBytes() == length)
				return dp;
		}
		throw new RuntimeException("Could not find disk parameters");
	}

	private int headsPerTrack;
	private int sectorsPerTrack;
	private int numberOfTracks;

	public int getNumberOfSectors()
	{
		return numberOfTracks * headsPerTrack * sectorsPerTrack;
	}

	public int getSizeInBytes()
	{
		return getNumberOfSectors() * 512;
	}
}
