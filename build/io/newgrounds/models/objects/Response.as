
/**
 * Response
 *
 * Contains all return output from an API request.
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.Response extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * Your application's unique ID
	 */
	public var app_id:String = null;

	/**
	 * If false, there was a problem with your 'request' object. Details will be in the error property.
	 */
	public var success:Boolean = false;

	/**
	 * Contains extra information you may need when debugging (debug mode only).
	 */
	public var debug:io.newgrounds.models.objects.Debug = null;

	/**
	 * This will be a #Result object, or an array containing one-or-more #Result objects (this will match the structure of the execute property in your #Request object).
	 */
	public var result = null;

	/**
	 * If there was an error, this will contain the current version number of the API gateway.
	 */
	public var api_version:String = null;

	/**
	 * If you passed an 'echo' value in your request object, it will be echoed here.
	 */
	public var echo = null;


	/**
	 * Array of Result objects (for mixed type handling with single result)
	 */
	public var resultList:Array = null;

	//==================== CONSTRUCTOR ====================

	public function Response() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Response";
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
		return ["app_id","success","debug","result","api_version","echo"];
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
			debug: "Debug",
			result: "array-of-Result"
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Sets a single result and clears the list
	 * @param resultObject A single result model instance
	 */
	public function setResult(resultObject):Void {
		this.result = resultObject;
		this.resultList = null;
	}

	/**
	 * Sets an array of results and clears the single value
	 * @param resultArray An array of result model instances (empty clears the list)
	 */
	public function setResultList(resultArray:Array):Void {
		if (resultArray != null && resultArray.length > 0) {
			this.resultList = resultArray;
		} else {
			this.resultList = null;
		}
		this.result = null;
	}

	/**
	 * Checks if using list format
	 * @return True if this response contains multiple results
	 */
	public function resultIsList():Boolean {
		return (this.resultList instanceof Array);
	}

	/**
	 * Gets the single result
	 * @return The single BaseResult instance or null
	 */
	public function getResult() {
		return this.result;
	}

	/**
	 * Gets the result array
	 * @return The array of BaseResult instances or null
	 */
	public function getResultList():Array {
		return this.resultList;
	}

	/**
	 * Overrides BaseObject.toObject() to ensure result uses the active format
	 */
	public function toObject(recursive:Boolean, excludeNulls:Boolean):Object {
		if (recursive == undefined) recursive = true;
		if (excludeNulls == undefined) excludeNulls = true;
		var obj:Object = super.toObject(recursive, excludeNulls);

		if (this.resultList instanceof Array) {
			obj.result = this.resultList;
		} else if (this.result != null) {
			obj.result = this.result;
		} else if (!excludeNulls) {
			obj.result = null;
		} else {
			delete obj.result;
		}

		return obj;
	}
}
