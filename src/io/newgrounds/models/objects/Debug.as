/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
* Contains extra debugging information.
*/
class io.newgrounds.models.objects.Debug extends io.newgrounds.models.BaseObject {

	private var ___exec_time:String;
	private var ___request:io.newgrounds.models.objects.Request;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function Debug(props:Object)
    {
		super();

		this.__object = 'Debug';
		this.__properties = this.__properties.concat(["exec_time","request"]);
		this.__required = [];

		this.__castTypes = {};
		this.__arrayTypes = {};

		this.__castTypes.request = io.newgrounds.models.objects.Request;

		this.fillProperties(props);

	}

	/**
    * The time, in milliseconds, that it took to execute a request.
    */
	public function get exec_time():String {
		return this.___exec_time;
	}

    /**
    * @private
    */
	public function set exec_time(___exec_time:String)
    {
        this.___exec_time = ___exec_time;
    }

	/**
    * A copy of the request object that was posted to the server.
    */
	public function get request():io.newgrounds.models.objects.Request {
		return this.___request;
	}

    /**
    * @private
    */
	public function set request(___request:io.newgrounds.models.objects.Request)
    {
        this.___request = ___request;
    }


}
