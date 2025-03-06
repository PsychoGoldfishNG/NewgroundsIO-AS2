/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
 * Contains all return output from an API request.
 */
class io.newgrounds.models.objects.Response extends io.newgrounds.models.BaseObject {
	private var ___app_id:String;
	private var ___success:Boolean;
	private var ___debug:io.newgrounds.models.objects.Debug;
	private var ___result;
	private var ___error:io.newgrounds.models.objects.Error;
	private var ___api_version:String;
	private var ___help_url:String;
	private var ___echo:Object;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function Response(props:Object) {
		super();
		this.__object = 'Response';
		this.__properties = this.__properties.concat(["app_id","success","debug","result","error","api_version","help_url","echo"]);
		this.__required = [];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.__castTypes.debug = io.newgrounds.models.objects.Debug;
		this.__arrayTypes.result = true;
		this.__castTypes.result = io.newgrounds.models.BaseResult;
		this.__castTypes.error = io.newgrounds.models.objects.Error;
		this.fillProperties(props);
	}
	/**
	 * Your application's unique ID
	 */
	public function get app_id():String {
		return this.___app_id;
	}

	/**
	 * @private
	 */
	public function set app_id(___app_id:String) {
		this.___app_id = ___app_id;
	}
	/**
	 * If false, there was a problem with your 'request' object. Details will be in the error property.
	 */
	public function get success():Boolean {
		return this.___success;
	}

	/**
	 * @private
	 */
	public function set success(___success:Boolean) {
		this.___success = ___success;
	}
	/**
	 * Contains extra information you may need when debugging (debug mode only).
	 */
	public function get debug():io.newgrounds.models.objects.Debug {
		return this.___debug;
	}

	/**
	 * @private
	 */
	public function set debug(___debug:io.newgrounds.models.objects.Debug) {
		this.___debug = ___debug;
	}
	/**
	 * This will be a result object, or an array containing one-or-more result objects (this will match the structure of the execute property in your io.newgrounds.models.objects.Request object).
	 */
	public function get result() {
		return this.___result;
	}

	/**
	 * @private
	 */
	public function set result(___result) {
		if (___result instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___result.length; i++) {
                newArr.push(this.castValue('result', ___result[i]));
            }
            this.___result = newArr;
        } else {
            this.___result = ___result;
        }
	}
	/**
	 * This will contain any error info if the success property is false.
	 */
	public function get error():io.newgrounds.models.objects.Error {
		return this.___error;
	}

	/**
	 * @private
	 */
	public function set error(___error:io.newgrounds.models.objects.Error) {
		this.___error = ___error;
	}
	/**
	 * If there was an error, this will contain the current version number of the API gateway.
	 */
	public function get api_version():String {
		return this.___api_version;
	}

	/**
	 * @private
	 */
	public function set api_version(___api_version:String) {
		this.___api_version = ___api_version;
	}
	/**
	 * If there was an error, this will contain the URL for our help docs.
	 */
	public function get help_url():String {
		return this.___help_url;
	}

	/**
	 * @private
	 */
	public function set help_url(___help_url:String) {
		this.___help_url = ___help_url;
	}
	/**
	 * If you passed an 'echo' value in your request object, it will be echoed here.
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

    // override - this will populate deeper result objects
    public function castValue(propName, value)
    {
        if (propName === 'result') {
            if (value instanceof Array) {
                var aValue;
                var newArr = [];
                for (var i = 0; i < value.length; i++) {
                    aValue = io.newgrounds.models.objects.ObjectIndex.CreateResult(value[i].component, value[i].data);
                    aValue.attachCore(this.getCore());
                    newArr.push(aValue);
                }
                value = newArr;
            } else {
                value = io.newgrounds.models.objects.ObjectIndex.CreateResult(value.component, value.data);
                value.attachCore(this.getCore());
            }

            return this.___result = value;
        }
        super.castValue(propName, value);

        return value;
    }

}