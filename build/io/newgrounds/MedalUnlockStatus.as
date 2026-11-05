/**
 * MedalUnlockStatus
 *
 * Where an unlock attempt left the medal. Every outcome MedalUnlockQueue
 * reports has one, as outcome.status. error is null exactly when the status is
 * UNLOCKED.
 *
 * AS2 has no const, so these are static vars. Don't assign to them.
 */
class io.newgrounds.MedalUnlockStatus {

	/** The gateway unlocked it. */
	public static var UNLOCKED:String = "unlocked";

	/** The gateway ruled on this medal and refused it (202 above all). It isn't retried. */
	public static var REJECTED:String = "rejected";

	/** Not ruled on yet, and still buffered: a retry pass will send it again. */
	public static var PENDING:String = "pending";

	/** Earned while nobody was signed in, and buffered until the game claims or
	 * discards it (NGIO.setHoldGuestMedalUnlocks()). */
	public static var HELD:String = "held";

	/** Not ruled on, and not buffered either: a guest unlock with
	 * NGIO.setKeepGuestMedalUnlocks(false). Nothing will send it again. */
	public static var DROPPED:String = "dropped";
}
