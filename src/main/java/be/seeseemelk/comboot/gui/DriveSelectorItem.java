package be.seeseemelk.comboot.gui;

import lombok.Data;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
@Data
class DriveSelectorItem
{
	public static final DriveSelectorItem NOT_PRESENT = new DriveSelectorItem("Not Present");
	public static final DriveSelectorItem VIRTUAL = new DriveSelectorItem("Image...");

	private final String description;

	public String toString()
	{
		return description;
	}
}
