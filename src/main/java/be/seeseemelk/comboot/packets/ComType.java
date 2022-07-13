package be.seeseemelk.comboot.packets;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public enum ComType
{
	HELLO(1),
	READ(2),
	;

	@Getter
	private final int value;
}
