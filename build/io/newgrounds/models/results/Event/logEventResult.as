/**
 * logEventResult
 *
 * Result for: Event.logEvent
 * Contains the data returned by the Event.logEvent API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Event.logEventResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * 
	 */
	public var event_name:String = null;


	//==================== CONSTRUCTOR ====================

	public function logEventResult() {
		super();
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
		return "result";
	}

	/**
	 * All property names for this result
	 */
	public function get propertyNames():Array {
		return ["event_name"];
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
		};
	}

	//==================== CUSTOM METHODS ====================
}
