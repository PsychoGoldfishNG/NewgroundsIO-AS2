/** ActionScript 2.0 */

import io.newgrounds.models.BaseObject;

/**
* BaseObject is the base class for all result objects in the Newgrounds.io API.
* This is essentially an abstract class, and should not be instantiated directly.
*/
class io.newgrounds.models.BaseResult extends io.newgrounds.models.BaseObject
{
    private var _success:Boolean;
    private var _error:io.newgrounds.models.objects.Error;

    public function BaseResult()
    {
        super();
        this.__object = "BaseResult";
        this._success = false;
        this._error = null;
        this.__properties = this.__properties.concat(["success", "error"]);
    }

    public function get success():Boolean
    {
        return this._success;
    }

    public function set success(_success:Boolean)
    {
        this._success = _success;
    }

    public function get error():io.newgrounds.models.objects.Error
    {
        return this._error;
    }

    public function set error(_error:io.newgrounds.models.objects.Error)
    {
        this._error = _error;
    }

    public function castValue(propName, value):Void
    {
        if (propName === 'error') {
            value = new io.newgrounds.models.objects.Error(value);
        }
        super.castValue(propName, value);
    }
}