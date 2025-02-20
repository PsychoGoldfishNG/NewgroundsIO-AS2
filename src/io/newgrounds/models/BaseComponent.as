/** ActionScript 2.0 */

import io.newgrounds.models.BaseObject;

/**
* BaseObject is the base class for all component objects in the Newgrounds.io API.
* This is essentially an abstract class, and should not be instantiated directly.
*/
class io.newgrounds.models.BaseComponent extends io.newgrounds.models.BaseObject
{
    public var __isSecure:Boolean;
    public var __requireSession:Boolean;
    public var __isRedirect:Boolean;

    public function BaseComponent()
    {
        super();
        this.__object = "BaseComponent";
    }

    public function get isSecure():Boolean
    {
        return this.__isSecure ? true : false;
    }

    public function get requireSession():Boolean
    {
        return this.__requireSession ? true : false;
    }

    public function get isRedirect():Boolean
    {
        return this.__isRedirect ? true : false;
    }
}