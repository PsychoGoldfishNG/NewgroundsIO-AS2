/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
 * Contains all the information needed to execute an API component.
 */
class io.newgrounds.models.objects.Execute extends io.newgrounds.models.BaseObject {
	private var ___component:String;
	private var ___parameters;
	private var ___secure:String;
	private var ___echo:Object;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function Execute(props:Object) {
		super();
		this.__object = 'Execute';
		this.__properties = this.__properties.concat(["component","parameters","secure","echo"]);
		this.__required = ["component","secure"];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.__arrayTypes.parameters = true;
		this.fillProperties(props);

			this.__componentObject = null;

	}
	/**
	 * The name of the component you want to call, ie 'App.connect'.
	 */
	public function get component():String {
		return this.___component;
	}

	/**
	 * @private
	 */
	public function set component(___component:String) {
		this.___component = ___component;
	}
	/**
	 * An object of parameters you want to pass to the component.
	 */
	public function get parameters() {
		return this.___parameters;
	}

	/**
	 * @private
	 */
	public function set parameters(___parameters) {
		if (___parameters instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___parameters.length; i++) {
                newArr.push(this.castValue('parameters', ___parameters[i]));
            }
            this.___parameters = newArr;
        } else {
            this.___parameters = ___parameters;
        }
	}
	/**
	 * A an encrypted io.newgrounds.models.objects.Execute object or array of io.newgrounds.models.objects.Execute objects.
	 */
	public function get secure():String {
		return this.___secure;
	}

	/**
	 * @private
	 */
	public function set secure(___secure:String) {
		this.___secure = ___secure;
	}
	/**
	 * An optional value that will be returned, verbatim, in the result object.
	 */
	public function get echo():Object {
		return this.___echo;
	}

	/**
	 * @private
	 */
	public function set echo(___echo:Object) {
		this.___echo = ___echo;
	}

    private var __componentObject:io.newgrounds.models.BaseComponent;

    /**
     * Set a component object to execute
     * @param io.newgrounds.models.BaseComponent component Any component model
     */
    public function setComponent(component:io.newgrounds.models.BaseComponent)
    {
        this.__componentObject = component;
    }

    /**
     * Validate this object (overrides default validator)
     * @return Boolean
     */
    public function hasValidProperties():Boolean
    {
        this.__validationErrors = [];

        if (!this.__componentObject) {
            this.__validationErrors.push('Error in '+this.getFullClassName()+': You must attach a component with setComponent() before executing.');
        }

        // Secure components need the core attached so they can be encrypted
        var core = this.getCore();
        if (core === undefined) core = this.__componentObject.getCore();

        if (this.__componentObject.isSecure && !core) {
            this.__validationErrors.push('Error in '+this.__componentObject.getFullClassName()+': You must attach a core with setCore() before executing.');
        }
        if (this.__componentObject.requireSession && (!core || !core.session || !core.session.id)) {
            this.__validationErrors.push('Error in '+this.__componentObject.getFullClassName()+': You must have a valid session to execute this component.');
        }

        this.__componentObject.hasValidProperties();
        this.__validationErrors = this.__validationErrors.concat(this.__componentObject.getValidationErrors());

        return this.__validationErrors.length === 0;
    }

    /**
     * Override the default toJsonObject handler and use encryption on components that require it
     * @return object A native object that can be converted to a JSON string
     */
    public function toJsonObject()
    {
        if (!this.hasValidProperties()) return null;

        var obj:Object = {
            component: this.__componentObject.getObjectName(),
            parameters: this.__componentObject.toJsonObject()
        };

        if (this.__componentObject.isSecure) {

            var core = this.getCore();
            if (core === undefined) core = this.__componentObject.getCore();

            return {
                secure: core.encrypt(obj)
            };
        }

        return obj;
    }

}