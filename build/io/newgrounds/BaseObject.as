/**
 * BaseObject
 *
 * Foundation class for all model objects with serialization/deserialization
 *
 * Every model in Newgrounds.io (User, Medal, Score, SaveSlot, etc.) extends BaseObject.
 */
import io.newgrounds.Core;
import io.newgrounds.encoders.JSON;
import io.newgrounds.models.objects.ObjectFactory;

class io.newgrounds.BaseObject {

	//==================== ABSTRACT PROPERTIES ====================
	// These must be overridden in each subclass

	/**
	 * The name of this object type for the JSON (e.g., "User", "Medal", "Score")
	 */
	public function get objectName():String {
		throw new Error("BaseObject.objectName must be overridden in subclass");
		return null;
	}

	/**
	 * A category/namespace for this object (e.g., "object", "component", "result")
	 */
	public function get objectType():String {
		throw new Error("BaseObject.objectType must be overridden in subclass");
		return null;
	}

	/**
	 * List of all property names this object supports
	 */
	public function get propertyNames():Array {
		throw new Error("BaseObject.propertyNames must be overridden in subclass");
		return null;
	}

	/**
	 * List of properties that MUST be present
	 */
	public function get requiredProperties():Array {
		throw new Error("BaseObject.requiredProperties must be overridden in subclass");
		return null;
	}

	/**
	 * Specifies how to cast (convert) each property value to the correct type
	 */
	public function get castTypes():Object {
		throw new Error("BaseObject.castTypes must be overridden in subclass");
		return null;
	}

	//==================== PUBLIC PROPERTIES ====================

	/** Reference to the Core instance for accessing app state and executing components */
	public var core:io.newgrounds.Core;

	/** Parent object if this is nested (used for hierarchical naming) */
	public var parent:io.newgrounds.BaseObject;

	/** Property name in parent object (used for hierarchical naming) */
	public var parentPropertyName:String;

	/** Error details if something went wrong (can be set on any object) */
	public var error = null;

	/** Static counter for tracking object IDs (for debugging) */
	private static var objectIDTracking:Number = 0;

	/** Unique object ID assigned during construction (for debugging) */
	public var objectId:Number = -1;

	//==================== PUBLIC METHODS ====================

	/**
	 * Constructor for BaseObject
	 * Initializes the object and assigns a unique objectId for debugging
	 */
	public function BaseObject() {
		this.objectId = io.newgrounds.BaseObject.objectIDTracking++;
	}

	/**
	 * Import data from a plain object (usually JSON parsed from server)
	 *
	 * @param importObject Plain object with raw data (e.g., from JSON.parse)
	 */
	public function importFromObject(importObject):Void {
		// Validate input
		if (importObject == null || importObject == undefined) {
			return;
		}

		// If importing from another BaseObject instance
		if (importObject instanceof io.newgrounds.BaseObject) {
			// Verify same type
			if (importObject.getFullObjectName() != this.getFullObjectName()) {
				throw new Error("Cannot import " + importObject.getFullObjectName() +
				               " into " + this.getFullObjectName());
			}
			// Convert to plain object first
			importObject = importObject.toObject(false, false);
		}

		// Verify it's a simple object (not array, not primitive)
		if (importObject instanceof Array) {
			throw new Error("importObject must be a plain object or BaseObject instance");
		}

		// Import each property
		var propNames:Array = propertyNames;
		var castTypesObj:Object = castTypes;

		// create a new object of this type to get default values from
		// if the property isn't povided in the import object
		var defaultObject = io.newgrounds.models.objects.ObjectFactory.CreateObject(objectName, null, core);

		for (var i:Number = 0; i < propNames.length; i++) {
			var propertyName:String = propNames[i];

			// Check if property exists in the import object
			// Use === to distinguish explicit null from missing/undefined
			if (importObject[propertyName] === undefined) {
				importObject[propertyName] = defaultObject[propertyName];
			}

			var propertyValue = importObject[propertyName];

			// Cast and assign
			var castValue = castToExpectedType(propertyName, propertyValue);

			this[propertyName] = castValue;
		}

		// Check for error property
		if (importObject["error"] != undefined && importObject.error != null) {
			this.error = io.newgrounds.models.objects.ObjectFactory.CreateObject("Error", importObject.error, this.core);
		}
	}

	/**
	 * Convert a property value to its correct type
	 *
	 * @param propertyName Name of the property being cast
	 * @param value The raw value from JSON
	 * @return The value converted to the correct type
	 */
	public function castToExpectedType(propertyName:String, value) {
		if (value == null || value == undefined) {
			return null;
		}

		var castTypesObj:Object = castTypes;
		if (castTypesObj[propertyName] == undefined) {
			return value;
		}

		var castType = castTypesObj[propertyName];

		// Handle primitives
		if (castType == 'string') {
			return String(value);
		} else if (castType == 'number') {
			return Number(value);
		} else if (castType == 'boolean') {
			if (typeof value == 'string') {
				return value.toLowerCase() == 'true';
			} else {
				return Boolean(value);
			}
		}

		// Handle arrays - check for array-of-X pattern
		if (typeof castType == 'string' && castType.indexOf('array-of-') == 0) {
			var itemType:String = castType.substring(9); // Remove "array-of-" prefix

			var resultArray:Array = [];

			if (value instanceof Array) {
				for (var j:Number = 0; j < value.length; j++) {
					var element = value[j];
					if (typeof element == 'object' && !(element instanceof Array)) {
						element = io.newgrounds.models.objects.ObjectFactory.CreateObject(itemType, element, this.core);
					}
					resultArray.push(element);
				}
			} else if (typeof value == 'object') {
				return [io.newgrounds.models.objects.ObjectFactory.CreateObject(itemType, value, this.core)];
			} else {
				return [];
			}

			return resultArray;
		}

		// Handle single objects
		if (typeof value == 'object' && !(value instanceof Array) && castType !== "Array") {
			return io.newgrounds.models.objects.ObjectFactory.CreateObject(castType, value, this.core);
		}

		return value;
	}

	/**
	 * Returns the fully-qualified name of this object for logging/debugging
	 *
	 * @return Qualified name like "object.User" or "component.Medal.unlock"
	 */
	public function getFullObjectName():String {
		var fullName:String = objectType + "." + objectName;

		if (parent != null && parentPropertyName != null) {
			fullName = parent.getFullObjectName() + "." + parentPropertyName;
		}

		return fullName;
	}

	/**
	 * Check if this object has all required properties
	 *
	 * @return true if all required properties are present, false if any are missing
	 */
	public function hasValidProperties():Boolean {
		var reqProps:Array = requiredProperties;

		for (var i:Number = 0; i < reqProps.length; i++) {
			var requiredProperty:String = reqProps[i];

			if (this[requiredProperty] == null || this[requiredProperty] == undefined) {
				return false;
			}

			if (typeof this[requiredProperty] == 'string') {
				if (this[requiredProperty].length == 0) {
					return false;
				}
			}

			if (this[requiredProperty] instanceof Array) {
				if (this[requiredProperty].length == 0) {
					return false;
				}
			}
		}

		return true;
	}

	/**
	 * Get a list of all validation errors
	 *
	 * @return Array of error message strings (empty array if no errors)
	 */
	public function getValidationErrors():Array {
		var errors:Array = [];
		var reqProps:Array = requiredProperties;

		for (var i:Number = 0; i < reqProps.length; i++) {
			var requiredProperty:String = reqProps[i];

			if (this[requiredProperty] == null || this[requiredProperty] == undefined) {
				errors.push("Required property '" + requiredProperty + "' is missing or null");
				continue;
			}

			if (typeof this[requiredProperty] == 'string') {
				if (this[requiredProperty].length == 0) {
					errors.push("Required property '" + requiredProperty + "' is an empty string");
					continue;
				}
			}

			if (this[requiredProperty] instanceof Array) {
				if (this[requiredProperty].length == 0) {
					errors.push("Required property '" + requiredProperty + "' is an empty array");
					continue;
				}
			}
		}

		return errors;
	}

	/**
	 * Convert this model object to a plain object for serialization
	 *
	 * @param recursive If true, convert nested objects too.
	 * @param excludeNulls If true, don't include properties with null values.
	 * @return Plain object ready for JSON serialization
	 */
	public function toObject(recursive:Boolean, excludeNulls:Boolean):Object {
		if (recursive == undefined) recursive = true;
		if (excludeNulls == undefined) excludeNulls = true;

		var result:Object = {};
		var propNames:Array = propertyNames;

		for (var i:Number = 0; i < propNames.length; i++) {
			var propertyName:String = propNames[i];
			var value = this[propertyName];

			if (excludeNulls && value == null) {
				continue;
			}

			if (recursive && value instanceof io.newgrounds.BaseObject) {
				value = value.toObject(recursive, excludeNulls);
			} else if (recursive && value instanceof Array) {
				var newArray:Array = [];
				for (var j:Number = 0; j < value.length; j++) {
					var element = value[j];
					if (element instanceof io.newgrounds.BaseObject) {
						newArray.push(element.toObject(recursive, excludeNulls));
					} else {
						newArray.push(element);
					}
				}
				value = newArray;
			}

			result[propertyName] = value;
		}

		return result;
	}

	/**
	 * Convert this object to a JSON-serializable Object
	 */
	public function toJSON():Object {
		return prepareForJson();
	}

	/**
	 * Convert this object to a JSON string
	 */
	public function toJsonString():String {
		var plainObject:Object = prepareForJson();
		return io.newgrounds.encoders.JSON.encode(plainObject);
	}

	/**
	 * Prepares this object for JSON serialization
	 */
	public function prepareForJson():Object {
		return toObject(true, true);
	}

	/**
	 * Convert this object to a human-readable string representation
	 */
	public function toString():String {
		return this.objectName;
	}
}
