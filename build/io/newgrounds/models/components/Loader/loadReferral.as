/**
 * loadReferral
 *
 * Component: Loader.loadReferral
 * Loads a custom referral URL (as defined in your "Referrals & Events" settings), and logs the referral to your API stats.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.Loader.loadReferral extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The domain hosting your app. Example: "www.somesite.com", "localHost"
	 */
	public var host:String = null;

	/**
	 * The name of the referral (as defined in your "Referrals & Events" settings).
	 */
	public var referral_name:String = null;

	/**
	 * Set this to false to skip logging this as a referral event.
	 */
	public var log_stat:Boolean = true;


	//==================== CONSTRUCTOR ====================

	public function loadReferral() {
		super();

		// Set component-specific flags
		this.isSecure = false;
		this.requiresSession = false;
		this.redirect = true;
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Loader.loadReferral";
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
		return ["host","referral_name","redirect","log_stat"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["host","referral_name"];
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
