/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
* A top-level wrapper containing any information needed to authenticate the application/user and any component calls being made.
*/
class io.newgrounds.models.objects.Request extends io.newgrounds.models.BaseObject {

	private var ___app_id:String;
	private var ___execute;
	private var ___session_id:String;
	private var ___debug:Boolean;
	private var ___echo:Object;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function Request(props:Object)
    {
		super();

		this.__object = 'Request';
		this.__properties = this.__properties.concat(["app_id","execute","session_id","debug","echo"]);
		this.__required = ["app_id","execute"];

		this.__castTypes = {};
		this.__arrayTypes = {};

		this.__arrayTypes.execute = true;
		this.__castTypes.execute = io.newgrounds.models.objects.Execute;

		this.fillProperties(props);

	}

	/**
    * Your application's unique ID.
    */
	public function get app_id():String {
		return this.___app_id;
	}

    /**
    * @private
    */
	public function set app_id(___app_id:String)
    {
        this.___app_id = ___app_id;
    }

	/**
    * A io.newgrounds.models.objects.Execute object, or array of one-or-more io.newgrounds.models.objects.Execute objects.
    */
	public function get execute() {
		return this.___execute;
	}

    /**
    * @private
    */
	public function set execute(___execute)
    {
        if (___execute instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___execute.length; i++) {
                newArr.push(this.castValue('execute', ___execute[i]));
            }
            this.___execute = newArr;
        } else {
            this.___execute = ___execute;
        }
    }

	/**
    * An optional login session id.
    */
	public function get session_id():String {
		return this.___session_id;
	}

    /**
    * @private
    */
	public function set session_id(___session_id:String)
    {
        this.___session_id = ___session_id;
    }

	/**
    * If set to true, calls will be executed in debug mode.
    */
	public function get debug():Boolean {
		return this.___debug;
	}

    /**
    * @private
    */
	public function set debug(___debug:Boolean)
    {
        this.___debug = ___debug;
    }

	/**
    * An optional value that will be returned, verbatim, in the io.newgrounds.models.objects.Response object.
    */
	public function get echo():Object {
		return this.___echo;
	}

    /**
    * @private
    */
	public function set echo(___echo:Object)
    {
        this.___echo = ___echo;
    }


}
