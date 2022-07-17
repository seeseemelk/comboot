package be.seeseemelk.comboot.packets;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public enum ComType
{
	HELLO(1),
	WELCOME(2),
	READ(3),
	DATA(4),
	FINISH(5),
	;

	@Getter
	private final int value;
}
