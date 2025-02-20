/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the Loader.loadAuthorUrl component.
 */
class io.newgrounds.models.components.Loader.loadAuthorUrl extends io.newgrounds.models.BaseComponent 
{
    private var ___host:String;
		private var ___redirect:Boolean;
		private var ___log_stat:Boolean;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function loadAuthorUrl(props:Object) 
    {
		super();

		this.__object = "Loader.loadAuthorUrl";
		this.___host = null;
		this.___redirect = true;
		this.___log_stat = true;
		this.__properties = this.__properties.concat(["host","redirect","log_stat"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = true;

		this.__castTypes = {};

        this.fillProperties(props);

	}


    /**
    * The domain hosting your app. Example: "www.somesite.com", "localHost"
    */
	public function get host():String {
		return this.___host;
	}

    /**
    * @private
    */
	public function set host(___host:String)
    {
        this.___host = ___host;
    }


    /**
    * Set this to false to get a JSON response containing the URL instead of doing an actual redirect.
    */
	public function get redirect():Boolean {
		return this.___redirect;
	}

    /**
    * @private
    */
	public function set redirect(___redirect:Boolean)
    {
        this.___redirect = ___redirect;
    }


    /**
    * Set this to false to skip logging this as a referral event.
    */
	public function get log_stat():Boolean {
		return this.___log_stat;
	}

    /**
    * @private
    */
	public function set log_stat(___log_stat:Boolean)
    {
        this.___log_stat = ___log_stat;
    }


}

