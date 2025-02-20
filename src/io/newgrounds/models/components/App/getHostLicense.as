/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the App.getHostLicense component.
 */
class io.newgrounds.models.components.App.getHostLicense extends io.newgrounds.models.BaseComponent 
{
    private var ___host:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function getHostLicense(props:Object) 
    {
		super();

		this.__object = "App.getHostLicense";
		this.___host = null;
		this.__properties = this.__properties.concat(["host"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = false;

		this.__castTypes = {};

        this.fillProperties(props);

	}


    /**
    * The host domain to check (ei, somesite.com).
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


}

