/** ActionScript 2.0 */

import io.newgrounds.core;
import io.newgrounds.encoders.JSON;
import io.newgrounds.models.BaseComponent;
import io.newgrounds.models.BaseResult;

/**
* BaseObject is the base class for all model objects in the Newgrounds.io API.
* This is essentially an abstract class, and should not be instantiated directly.
*/
class io.newgrounds.models.BaseObject {

    /** A reference to the object path and classname */
    public var __object:String;

    /** A list of propertied this onbject can have */
    public var __properties:Array;

    /** A list of properties that are required for this to be a valid object */
    public var __required:Array;

    /** A reference to the core object that contains our app id and encryption information */
    public var __core:core;

    private var __validationErrors:Array;

    private var __castTypes:Object;
    private var __arrayTypes:Object;

    /**
    * Constructor
    */
    public function BaseObject() 
    {
        this.__properties = [];
        this.__required = [];
        this.__object = "BaseObject";
        this.__validationErrors = [];
        this.__castTypes = {};
    }

    /**
    * Attaches a core object to this object
    * @param core A reference to the core object
    */
    public function attachCore(core:core):Void
    {
        this.__core = core;
    }

    /**
    * Returns the core object attached to this object
    * @return core A reference to the core object
    */
    public function getCore():core
    {
        return this.__core;
    }

    /**
    * Returns an array of property names for this object
    */
    public function get propertyNames():Array
    {
        return __properties;
    }

    /**
    * Returns an array of required property names for this object
    */
    public function get requiredProperties():Array
    {
        return __required;
    }

    /**
    * Copies properties from an object into this object
    * @param props An object containing properties to copy
    */
    public function fillProperties(props:Object):Void
    {
        for (var key in props) {

            // components will be expecting user ids, vs objects
            if (key === 'user' && (this instanceof BaseComponent) && (props[key] instanceof io.newgrounds.models.objects.User)) {
                props[key] = props[key].id;
            }

            // ignore anything that isn't a property of this child class
            if (this.__properties.indexOf(key) != -1) {
                // cast the value to the correct type
                this.castValue(key, props[key]);
            }   
        }

        // if this object has a host property, and it's not present in the initial properties array, pull it from the core
        if (this.__properties.indexOf('host') != -1 && props['host'] === undefined) {
             this.castValue('host', io.newgrounds.core.getHost());
        }
    }

    /**
    * Casts a value to the correct type and sets it as a property of this object
    * @param propName The name of the property to set
    * @param value The value to set
    * @return mixed The value that was set
    */
    public function castValue(propName, value)
    {
        // if we get a null, we can just set it as-as
        if (value !== null) {

            // some properties can be arrays of a specific model
            if (this.__arrayTypes[propName] === true && value instanceof Array) {

                var aValue;

                // make a new array and populate it with cast values
                var newArr = [];
                for (var i = 0; i < value.length; i++) {
                    aValue  = this.castValue(propName, value[i]);
                    newArr.push(aValue);
                }
                value = newArr;

            // other properties need to be cast to a specific model
            } else if (this.__castTypes[propName] !== undefined && !(value instanceof this.__castTypes[propName])) {
                value = new this.__castTypes[propName](value);
                value.attachCore(this.getCore());
            }
        }

        // set the property and return the final value
        this[propName] = value;

        return value;
    }

    /**
    * Checks the state of this object's properties against the list of required properties
    * @return Boolean Will be true if all required properties have been set
    */
    public function hasValidProperties():Boolean
    {
        // we'll store any error messages here
        this.__validationErrors = [];

        // loop through the required properties and check if they're set
        for (var i = 0; i < __required.length; i++) {
            if (this[__required[i]] === undefined || this[__required[i]] === null) {
                this.__validationErrors.push("Missing required property in instance of "+this.getFullClassName()+": " + __required[i]);
            }
        }

        // if we have no errors, we're good to go!
        return this.__validationErrors.length === 0;
    }

    /**
    * Returns an array of validation errors
    * @return Array An array of validation errors
    */
    public function getValidationErrors():Array
    {
        return this.__validationErrors;
    }

    /**
    * Returns the object name of this object
    * @return String The object name of this object
    */
    public function getObjectName():String
    {
        return this.__object;
    }

    /**
    * Returns the full class name of this object
    * @return String The full class name of this object
    */
    public function getFullClassName():String
    {
        // all models start in this namespace
        var namespace = "io.newgrounds.models.";

        // our base classes aren't in a sub-namespace
        switch(this.__object) {
            case "BaseObject":
            case "BaseComponent":
            case "BaseResult":
                return namespace + this.__object;
        }

        // figure out what sub-namespace we're in by the superclass type
        if (this instanceof BaseComponent) {
            namespace += "components.";
        } else if (this instanceof BaseResult) {
            namespace += "results.";
        } else {
            namespace += "objects.";
        }

        return namespace + this.__object;
    }

    /**
    * Returns a JSON-encodable object representing this object and it's children
    * @return Object A JSON-encodable object
    */
    public function toJsonObject():Object
    {
        var obj:Object = {};
        var prop:String, val;

        // check our required properties and throw an error if any are missing
        for (var i = 0; i < this.__required.length; i++) {
            prop = this.__required[i];
            if (this[prop] === undefined) {
                throw new Error("Missing required property in instance of "+this.getFullClassName()+": " + prop);
            }
        }
        
        // loop through our properties and make them JSON-encodable
        for (var i = 0; i < this.__properties.length; i++) {
            prop = this.__properties[i];
            val = this.makeJsonObject(this[prop]);
            obj[prop] = val;
        }

        return obj;
    }

    /**
    * Recursively converts a value to a JSON-encodable object
    * @param source The value to convert
    * @return mixed A JSON-encodable alue
    */
    public function makeJsonObject(source)
    {
        // default to null so we always get something encodable
        var obj = null;

        // if it's an array, loop through and convert each item
        if (source instanceof Array) {
            
            obj = [];
            for (var i = 0; i < source.length; i++) {
                obj.push(this.makeJsonObject(source[i]));
            }

        // if it's one of our model classes, use it's toJsonObject method to ensure it's properties are valid and converted
        } else if (source instanceof BaseObject) {
            
            obj = source.toJsonObject();
            

        // if it's a flat object, iterate through and convert each property
        } else if (source instanceof Object) {
            
            obj = {};
            for (var key in source) {
                
                obj[key] = this.makeJsonObject(source[key]);
            }
        
        // strings, numbers and bools can be passed through as-is
        } else {
            
            obj = source;
        }

        return obj;
    }

    /**
    * Returns a JSON string representing this object and it's children
    * @return String A JSON string
    */
    public function toJsonString():String
    {
        return JSON.encode(this.toJsonObject());
    }
}