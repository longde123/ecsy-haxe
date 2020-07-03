package ecsy;
import ecsy.Component.ComponentConstructor;
class Util {
    public static function wrapImmutableComponent(T, component) {
        return component;
    }
/**
    * Return the name of a component
    * @param {Component} Component
* @private
*/
    public static function getName(component:ComponentConstructor) {
        return Type.getClassName(component) ;
    }

/**
 * Return a valid property name for the Component
 * @param {Component} Component
 * @private
 */
    public static function componentPropertyName(component:ComponentConstructor) {
        return getName(component);
    }

/**
 * Get a key from a list of components
 * @param {Array(Component)} Components Array of components to generate the key
 * @private
 */
    public static function queryKey(allOfComponents:Array<ComponentConstructor>, noneOfComponents:Array<ComponentConstructor>):String {
        var names = [];
        for (component in allOfComponents) {
            names.push(getName(component));
        }
        for (component in noneOfComponents) {
            names.push("not" + getName(component));
        }

        return names.join("-");
    }

}
