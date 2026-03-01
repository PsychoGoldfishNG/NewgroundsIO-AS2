
/**
 * Session
 *
 * Contains information about the current user session.
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.Session extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * A unique session identifier
	 */
	public var id:String = null;

	/**
	 * If the user has not signed in, or granted access to your app, this will be null
	 */
	public var user:io.newgrounds.models.objects.User = null;

	/**
	 * If true, the session_id is expired. Use App.startSession to get a new one.
	 */
	public var expired:Boolean = false;

	/**
	 * If true, the user would like you to remember their session id.
	 */
	public var remember:Boolean = false;

	/**
	 * If the session has no associated user but is not expired, this property will provide a URL that can be used to sign the user in.
	 */
	public var passport_url:String = null;


	/** @private Tracks a session ID that may have been pre-authenticated */
	public var preauthenticatedId:String = "";

	/** @private Tracks whether the session has been validated with the server */
	public var verified:Boolean = false;

	//==================== CONSTRUCTOR ====================

	public function Session() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Session";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "object";
	}

	/**
	 * All property names for this object
	 */
	public function get propertyNames():Array {
		return ["id","user","expired","remember","passport_url"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return [];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
			"user": "User"
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Clears session-specific data to return the session to an unauthenticated state.
	 * Called by AppState when a session expires or is cancelled.
	 */
	public function clearSessionData():Void {
		this.id = null;
		this.user = null;
		this.passport_url = null;
		this.expired = false;
		this.remember = false;
		this.verified = false;
		this.preauthenticatedId = "";
	}

	/**
	 * Compares session id against a pre-authenticated id.
	 * Used in SessionState to determine if we can skip user verification.
	 */
	public function isPreauthenticated():Boolean {
		return this.preauthenticatedId.length > 0 && this.id === this.preauthenticatedId;
	}
}
