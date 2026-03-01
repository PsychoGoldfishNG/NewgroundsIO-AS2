
/**
 * Execute
 *
 * Contains all the information needed to execute an API component.
 */
import io.newgrounds.BaseObject;
import io.newgrounds.BaseComponent;

class io.newgrounds.models.objects.Execute extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The name of the component you want to call, ie 'App.connect'.
	 */
	public var component:String = null;

	/**
	 * An object of parameters you want to pass to the component.
	 */
	public var parameters:* = null;

	/**
	 * A an encrypted #Execute object or array of #Execute objects.
	 */
	public var secure:String = null;

	/**
	 * An optional value that will be returned, verbatim, in the #Result object.
	 */
	public var echo:* = null;


	/**
	 * Reference to the component model being executed
	 * Used during serialization to determine if encryption is needed
	 */
	public var componentModel:io.newgrounds.BaseComponent;

	//==================== CONSTRUCTOR ====================

	public function Execute() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Execute";
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
		return ["component","parameters","secure","echo"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["component","secure"];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
			"parameters": "Array"
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Sets the component to be executed
	 *
	 * @param componentModel A component model instance with all required properties set
	 */
	public function setComponent(componentModel:io.newgrounds.BaseComponent):Void {
		// Store reference to the component
		this.componentModel = componentModel;
		this.component = componentModel.objectName;
		if (componentModel.hasOwnProperty("prepareForJson")) {
			this.parameters = componentModel.prepareForJson();
		} else if (componentModel.hasOwnProperty("toObject")) {
			this.parameters = componentModel.toObject();
		} else {
			this.parameters = null;
		}
		// Note: Encryption for secure components is handled by HttpRequestHelper
		// This Execute object just stores the component name and parameters
	}

	/**
	 * Sets a single Execute object and clears the list
	 *
	 * @param executeObject A single Execute instance
	 */
	public function setExecute(executeObject):Void {
		this.execute = executeObject;
		this.executeList = null;
	}

	/**
	 * Sets an array of Execute objects and clears the single value
	 *
	 * @param executeArray An array of Execute instances
	 */
	public function setExecuteList(executeArray:Array):Void {
		this.executeList = executeArray;
		this.execute = null;
	}

	/**
	 * Checks if execute is in array format
	 *
	 * @return true if using list format, false if using single value
	 */
	public function executeIsArray():Boolean {
		return this.executeList != null && this.executeList.length > 0;
	}

	/**
	 * Gets the single Execute object
	 *
	 * @return Single Execute instance or null
	 */
	public function getExecute() {
		return this.execute;
	}

	/**
	 * Gets the Execute objects array
	 *
	 * @return Array of Execute instances or null
	 */
	public function getExecuteList():Array {
		return this.executeList;
	}
}
