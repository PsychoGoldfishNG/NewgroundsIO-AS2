/**
 * BaseComponent
 *
 * Base class for all component models sent to servers
 *
 * Components are the building blocks of API calls. Every action you send to
 * the server (unlock a medal, post a score, check session, etc.) is done via a component.
 */

class io.newgrounds.BaseComponent extends io.newgrounds.BaseObject {

	//==================== PUBLIC PROPERTIES ====================

	/**
	 * Whether this component must be encrypted before sending
	 */
	public var isSecure:Boolean = false;

	/**
	 * Whether the user must be logged in to execute this component
	 */
	public var requiresSession:Boolean = false;

	/**
	 * Whether this component opens a browser window (Passport login)
	 */
	public var redirect:Boolean = false;

	/**
	 * The window/frame to open redirect in (if redirect=true)
	 */
	public var browserTarget:String = null;

	//==================== CONSTRUCTOR ====================

	public function BaseComponent() {
		super();

		this.isSecure = false;
		this.requiresSession = false;
		this.redirect = false;
		this.browserTarget = null;
	}

	//==================== OVERRIDDEN METHODS ====================

	/**
	 * Enhanced validation that includes session requirements
	 */
	public function hasValidProperties():Boolean {
		var parentIsValid:Boolean = super.hasValidProperties();
		if (!parentIsValid) {
			return false;
		}

		if (this.requiresSession) {
			if (this.core == null) {
				return false;
			}

			if (this.core.appState == null) {
				return false;
			}

			var session = this.core.appState.session;

			if (session == null) {
				return false;
			}

			if (session.id == null || (typeof session.id == "string" && session.id.length == 0)) {
				return false;
			}

			if (session.user == null) {
				return false;
			}

			if (session.user.id == null ||
			    (typeof session.user.id == "string" && session.user.id.length == 0)) {
				return false;
			}
		}

		return true;
	}
}
