/**
 * SessionStatus
 *
 * Represents the current status of a client session (result of checkSession call)
 *
 * NOTE: This is a simple data model that does NOT extend BaseObject
 */

class io.newgrounds.SessionStatus {

	//==================== STATUS CONSTANTS ====================

	public static var UNINITIALIZED:String = "uninitialized";
	public static var UNVERIFIED:String = "unverified";
	public static var SESSION_ID_PROVIDED:String = "session-id-provided";
	public static var NOT_LOGGED_IN:String = "not-logged-in";
	public static var WAITING_FOR_PASSPORT:String = "waiting-for-passport";
	public static var LOGGED_IN:String = "logged-in";
	public static var LOGIN_CANCELLED:String = "login-cancelled";
	public static var EXPIRED:String = "expired";
	public static var ERROR:String = "error";

	//==================== PUBLIC PROPERTIES ====================

	/**
	 * The current session status
	 */
	public var status:String = "uninitialized";

	/**
	 * The logged-in user (if status = LOGGED_IN), otherwise null
	 */
	public var user = null;

	/**
	 * Error details (if status = ERROR), otherwise null
	 */
	public var error = null;

	//==================== CONSTRUCTOR ====================

	public function SessionStatus() {
		this.status = io.newgrounds.SessionStatus.UNINITIALIZED;
		this.user = null;
		this.error = null;
	}
}
