/**
 * logEvent
 *
 * Component: Event.logEvent
 * Logs a custom event to your API stats.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.Event.logEvent extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The domain hosting your app. Example: "newgrounds.com", "localHost"
	 */
	public var host:String = null;

	/**
	 * The name of your custom event as defined in your Referrals & Events settings.
	 */
	public var event_name:String = null;


	//==================== CONSTRUCTOR ====================

	public function logEvent() {
		super();

		// Set component-specific flags
		this.isSecure = false;
		this.requiresSession = false;
		this.redirect = false;
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Event.logEvent";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "component";
	}

	/**
	 * All property names for this component
	 */
	public function get propertyNames():Array {
		return ["host","event_name"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["host","event_name"];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
		};
	}

	//==================== CUSTOM METHODS ====================
}
