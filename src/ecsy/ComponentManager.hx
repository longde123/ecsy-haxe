package ecsy;

import haxe.ds.StringMap;
import ecsy.Component.ComponentConstructor;
import haxe.ds.ObjectMap;

class ComponentManager {
    var _componentPool:StringMap< ObjectPool<Component>>;
    var numComponents:StringMap< Int>;
    public var components:Array<ComponentConstructor>;

    public function new() {
        this.components = [];
        this._componentPool = new StringMap< ObjectPool<Component>>();
        this.numComponents = new StringMap< Int>();
    }

    public function registerComponent(component:ComponentConstructor) {
        var componentName = Util.componentPropertyName(component);
        if (Lambda.has(components, component)) {
            trace("Component type: ${component} already registered.");
            return;
        }

        this.components.push(component);

        this.numComponents.set(componentName, 0);
        var objectPool = new ObjectPool(component);

        this._componentPool.set(componentName, objectPool);
    }

    public function componentAddedToEntity(component:ComponentConstructor) {
        if (!Lambda.has(components, component)) {
            this.registerComponent(component);
        }
        var componentName = Util.componentPropertyName(component);
        this.numComponents.set(componentName, this.numComponents.get(componentName) + 1);
    }

    public function componentRemovedFromEntity(component:ComponentConstructor) {
        var componentName = Util.componentPropertyName(component);
        this.numComponents.set(componentName, this.numComponents.get(componentName) - 1);
    }

    public function getComponentsPool(component:ComponentConstructor):ObjectPool<Component> {
        var componentName = Util.componentPropertyName(component);
        return this._componentPool.get(componentName);
    }
}
