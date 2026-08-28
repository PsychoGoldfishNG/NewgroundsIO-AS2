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

	/**
	 * The App ID this object's data was loaded from, when it came from a
	 * DIFFERENT app than the one this client is running as. Null for ordinary
	 * local data, which is the overwhelmingly common case.
	 *
	 * Set by NGIO's loadExternal* methods, on the returned model and everything
	 * nested inside it.
	 *
	 * It exists because a model returned by a cross-app read is otherwise
	 * indistinguishable from a local one, while behaving very differently.
	 * Cross-app access is READ-ONLY: no component that writes accepts an app_id,
	 * so calling one on a foreign object sends that object's id against YOUR app.
	 * Every write method checks this via assertNotForeign() - see the note there
	 * for why that check is not merely cosmetic.
	 */
	public var foreignAppId:String = null;

	/** Static counter for tracking object IDs (for debugging) */
	private static var objectIDTracking:Number = 0;

	/** Unique object ID assigned during construction (for debugging) */
	public var objectId:Number = -1;

	//==================== PUBLIC METHODS ====================

	/**
	 * True if this object's data was loaded from another app.
	 *
	 * Prefer this to testing foreignAppId directly - it treats an empty string
	 * the same as null, so a stamp that never took cannot read as a foreign
	 * object.
	 */
	public function isForeign():Boolean {
		return this.foreignAppId != null && this.foreignAppId.length > 0;
	}

	/**
	 * Refuses a write on an object that was loaded from another app.
	 *
	 * Called at the top of every method that writes - before any work is done
	 * and before anything is sent - so a mistake surfaces at the call site
	 * rather than as a puzzling gateway error later.
	 *
	 * WHY THIS THROWS RATHER THAN REPORTING VIA CALLBACK: calling a write on a
	 * foreign object is a programming error, not a runtime condition the caller
	 * can recover from. Every write method takes an OPTIONAL callback, so an
	 * error delivered that way would be silently discarded by the callers most
	 * likely to make the mistake.
	 *
	 * WHY IT MATTERS MOST FOR CloudSave: medal and scoreboard ids are globally
	 * unique, so a misdirected write is rejected by the gateway - confusing, but
	 * harmless. SaveSlot.id is a per-app SLOT NUMBER, and every app has a slot 1.
	 * Writing through a foreign slot therefore succeeds, silently overwriting the
	 * caller's OWN save data. This check is the only thing standing between a
	 * cross-app read and real data loss.
	 *
	 * PUBLIC, unlike the AS3 version, only because ActionScript 2 has no
	 * protected attribute. Treat it as internal to the library.
	 *
	 * @param action Name of the refused method, e.g. "unlock()"
	 * @param consequence One sentence on what would have happened
	 */
	public function assertNotForeign(action:String, consequence:String):Void {
		if (!this.isForeign()) {
			return;
		}

		throw new Error(
			this.toString() + " was loaded from app " + this.foreignAppId + ", not this one, " +
			"and " + action + " writes through this app's session. " + consequence + " " +
			"Cross-app access is read-only - see the NGIO.loadExternal* methods."
		);
	}

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
		var defaultObject = buildDefaultInstance();

		for (var i:Number = 0; i < propNames.length; i++) {
			var propertyName:String = propNames[i];

			// Check if property exists in the import object
			// Use === to distinguish explicit null from missing/undefined
			if (importObject[propertyName] === undefined) {
				if (objectType == "component") {
					// A component is built from a developer-supplied PARTIAL parameter
					// set (see ObjectFactory.CreateComponent), not a complete snapshot.
					// Absent means "not sent" - null it explicitly, regardless of the
					// field's own declared default (a Boolean's false, a Number's 0),
					// so it drops out of toObject()'s excludeNulls pass instead of
					// reappearing on the wire as its type's zero value.
					this[propertyName] = null;
				} else if (defaultObject != null) {
					this[propertyName] = defaultObject[propertyName];
				}
				// else: keep whatever the class-level initializer set. Do NOT index
				// into the failed lookup - null[propertyName] is undefined in AVM1,
				// and casting that would overwrite the field default with null.
				continue;
			}

			var propertyValue = importObject[propertyName];

			// Cast and assign
			var castValue = castToExpectedType(propertyName, propertyValue);

			this[propertyName] = castValue;

			// Record where the nested model landed, so getObjectPath() can name
			// it. Done here rather than inside castToExpectedType so a subclass
			// overriding the cast still gets the links, and so arrays are
			// handled in one place.
			stampChildPosition(castValue, propertyName);
		}

		// Check for error property
		if (importObject["error"] != undefined && importObject.error != null) {
			this.error = io.newgrounds.models.objects.ObjectFactory.CreateObject("Error", importObject.error, this.core);

			// `error` is not in propertyNames, so the loop above never saw it -
			// stamp it here or a failed nested model reports no path.
			stampChildPosition(this.error, "error");
		}
	}

	/**
	 * A throwaway instance used to read this model's declared defaults.
	 *
	 * A result's objectName is a dotted component path ("Medal.unlock") that
	 * ObjectFactory.CreateObject() cannot resolve by objectName alone - see
	 * BaseObject.md, "The default instance and dotted names". Dispatching to
	 * CreateResult for objectType == "result" lets it split the scope and method
	 * apart, so declared defaults apply there too.
	 *
	 * Deliberately NOT extended to objectType == "component": a component is
	 * built from a developer-supplied PARTIAL parameter set (see
	 * ObjectFactory.CreateComponent), not a complete server snapshot, so the
	 * "absent means reset to the declared default" reasoning does not apply - an
	 * omitted optional parameter needs to stay absent so it drops off the wire in
	 * toObject(), not reappear as its type's default value. Return null for
	 * components and let the caller's "keep the constructor value" fallback
	 * handle it, same as it always effectively has.
	 *
	 * @return A fresh instance of this same type, or null if it couldn't be built
	 */
	private function buildDefaultInstance() {
		if (objectType == "object") {
			return io.newgrounds.models.objects.ObjectFactory.CreateObject(objectName, null, core);
		}

		if (objectType != "result") {
			return null;
		}

		var dotIndex:Number = objectName.indexOf(".");
		if (dotIndex == -1) {
			return null;
		}
		var scope:String = objectName.substring(0, dotIndex);
		var method:String = objectName.substring(dotIndex + 1);

		return io.newgrounds.models.objects.ObjectFactory.CreateResult(scope, method, null, core);
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
		// TYPE identity, not location: the same class reports the same name
		// wherever it sits. That is what makes it usable as the type check in
		// importFromObject() - a Session is a Session whether it arrived
		// standalone or nested inside a checkSession result.
		//
		// For where an object sits in a tree, use getObjectPath().
		//
		// NOTE: this used to fold parent/parentPropertyName in, which would have
		// made it positional. Nothing ever assigned those, so the branch never
		// ran - and the moment they WERE assigned it broke importFromObject,
		// because AppStateResultUpdateHelper imports a nested result.session into
		// the standalone appState.session.
		return objectType + "." + objectName;
	}

	/**
	 * Returns where this object sits in the model tree, for debugging.
	 *
	 * A standalone model reports its type name. A nested one reports its
	 * parent's path plus the property it occupies, so a Medal reached through an
	 * unlock result reads:
	 *
	 *     result.Medal.unlock.medal
	 *
	 * and a Score inside a getScores result reads:
	 *
	 *     result.ScoreBoard.getScores.scores[3]
	 *
	 * That is the difference between "a Score failed to import" and knowing
	 * WHICH score, which is the whole reason the parent links exist.
	 *
	 * Never use this for type comparison - use getFullObjectName().
	 *
	 * @return The path from the root model down to this one
	 */
	public function getObjectPath():String {
		// Walk upward rather than recursing, so a cycle cannot blow the stack.
		// AVM1 disables the WHOLE MOVIE on "256 levels of recursion exceeded",
		// so a debugging aid that recursed would take the app with it.
		var segments:Array = [];
		var node:io.newgrounds.BaseObject = this;
		var guard:Number = 0;

		while (node != null && guard < 64) {
			if (node.parent != null && node.parentPropertyName != null) {
				segments.unshift(node.parentPropertyName);
				node = node.parent;
			} else {
				// Reached the root - its own type name starts the path.
				segments.unshift(node.getFullObjectName());
				node = null;
			}
			guard++;
		}

		return segments.join(".");
	}

	/**
	 * Records this object's position in the tree, so getObjectPath() can report
	 * it later.
	 *
	 * Called from importFromObject() for every nested model it builds. Arrays
	 * get an index, because "a Score failed" is not an answer when a scoreboard
	 * returned a hundred of them.
	 *
	 * @param value The freshly cast property value - model, array, or scalar
	 * @param propertyName The property it was assigned to
	 */
	public function stampChildPosition(value, propertyName:String):Void {
		if (value instanceof io.newgrounds.BaseObject) {
			value.parent = this;
			value.parentPropertyName = propertyName;
			return;
		}

		if (value instanceof Array) {
			// NOT Array(value) - that is the conversion function, and it would
			// return [value], so the loop below would stamp the array itself.
			var items:Array = value;
			for (var i:Number = 0; i < items.length; i++) {
				if (items[i] instanceof io.newgrounds.BaseObject) {
					items[i].parent = this;
					items[i].parentPropertyName = propertyName + "[" + i + "]";
				}
			}
		}

		// Scalars have no position to record.
	}

	/**
	 * Check if this object has all required properties
	 *
	 * @return true if all required properties are present, false if any are missing
	 */
	public function hasValidProperties():Boolean {
		return getPreflightError() == null;
	}

	/**
	 * The reason this object would be rejected, or null if it is valid.
	 *
	 * hasValidProperties() answers "is it valid?"; this answers "why not?",
	 * which is what a caller needs when the answer arrives instead of a server
	 * response. The two share one implementation so they can never disagree.
	 *
	 * NOT the same as getValidationErrors() below, despite the names: that one
	 * lists every missing required property as a plain string, for a developer
	 * reading a report. This one returns the FIRST problem as a real NgioError,
	 * carrying the code the gateway would have used, for a caller reading it as
	 * a refusal.
	 *
	 * @return An NgioError describing the first problem found, or null
	 */
	public function getPreflightError() {
		var reqProps:Array = requiredProperties;

		for (var i:Number = 0; i < reqProps.length; i++) {
			var requiredProperty:String = reqProps[i];

			if (this[requiredProperty] == null || this[requiredProperty] == undefined) {
				return missingPropertyError(requiredProperty, "is missing");
			}

			if (typeof this[requiredProperty] == 'string') {
				if (this[requiredProperty].length == 0) {
					return missingPropertyError(requiredProperty, "is an empty string");
				}
			}

			if (this[requiredProperty] instanceof Array) {
				if (this[requiredProperty].length == 0) {
					return missingPropertyError(requiredProperty, "is an empty array");
				}
			}
		}

		return null;
	}

	/**
	 * Builds the error for a required property that is absent or empty.
	 *
	 * MISSING_PARAMETER (102) is what the gateway returns for the same
	 * condition. The message names the object and the property, because
	 * "missing a required parameter" on its own sends a developer reading their
	 * own code rather than the one line that is wrong.
	 */
	public function missingPropertyError(propertyName:String, problem:String) {
		return io.newgrounds.Errors.getError(
			io.newgrounds.Errors.MISSING_PARAMETER,
			getFullObjectName() + " requires '" + propertyName + "', which " + problem + ".",
			false
		);
	}

	/**
	 * Get a list of all validation errors
	 *
	 * Returns plain strings, not NgioError models, on purpose: every entry is the
	 * same MISSING_PARAMETER condition, so a typed model per entry adds nothing to
	 * branch on. This is a developer-facing report; callers needing one branchable
	 * typed error use getPreflightError().
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
