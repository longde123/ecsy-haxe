package ecsy;
import ecsy.Component.ComponentConstructor;
import Lambda;
typedef EntityConstructor = Class<Entity>;
class Entity {
    public static var DEBUG = false;
    public var name:String;
    public var _entityManager:EntityManager;
    public var id:Int;
    public var _componentTypes:Array< ComponentConstructor>;
    public var numStateComponents:Int;
    public var alive:Bool;
    public var _components:Array<Component>;
    public var _componentsToRemove:Array<Component>;
    public var queries:Array<Query>;
    public var _componentTypesToRemove:Array<ComponentConstructor>;

    public function new(entityManager:EntityManager) {
        this._entityManager = entityManager ;

        // Unique ID for this entity
        this.id = entityManager._nextEntityId++;

        // List of components types the entity has
        this._componentTypes = [];

        // Instance of the components
        this._components = [];

        this._componentsToRemove = [];

        // Queries where the entity is added
        this.queries = [];

        // Used for deferred removal
        this._componentTypesToRemove = [];

        this.alive = false;

        //if there are state components on a entity, it can't be removed completely
        this.numStateComponents = 0;
    }

    // COMPONENTS

    public function getComponent(componentClass:ComponentConstructor, includeRemoved = false) {
        var component = Lambda.find(this._components, function(c) return Std.is(c, componentClass));

        if (component == null && includeRemoved == true) {
            component = getRemovedComponent(componentClass) ;
        }

        return DEBUG ? Util.wrapImmutableComponent(componentClass, component) : component;
    }

    public function getRemovedComponent(componentClass:ComponentConstructor) {
        return Lambda.find(this._componentsToRemove, function(c) return Std.is(c, componentClass));
    }

    public function getComponents() {
        return this._components;
    }

    public function getComponentsToRemove() {
        return this._componentsToRemove;
    }

    public function getComponentTypes() {
        return this._componentTypes;
    }

    public function getMutableComponent(component:ComponentConstructor) {
        var comp = getComponent(component);
        for (i in 0...this.queries.length) {
            var query:Query = this.queries[i];
            // @todo accelerate this check. Maybe having query._Components as an object
            // @todo add Not components
            if (query.reactive && Lambda.exists(query.components, function(c) return Std.is(c, component))) {
                query.eventDispatcher.dispatchEvent(
                    Query.COMPONENT_CHANGED,
                    this,
                    comp
                );
            }
        }
        return comp;
    }

    public function addComponent(component:ComponentConstructor) {
        this._entityManager.entityAddComponent(this, component);
        return this;
    }

    public function removeComponent(component:ComponentConstructor, forceImmediate = false) {
        this._entityManager.entityRemoveComponent(this, component, forceImmediate);
        return this;
    }

    public function hasComponent(component:ComponentConstructor, includeRemoved = false) {
        var had = Lambda.has(this._componentTypes, component);
        var hasRemoved = (includeRemoved == true && this.hasRemovedComponent(component));

        return had || hasRemoved;
    }

    public function hasRemovedComponent(component:ComponentConstructor) {
        return Lambda.has(this._componentTypesToRemove, component) ;
    }

    public function hasAllComponents(components:Array<ComponentConstructor>) {
        for (component in components) {
            if (!this.hasComponent(component))
                return false;
        }
        return true;
    }

    public function hasAnyComponents(components:Array<ComponentConstructor>) {
        for (component in components) {
            if (this.hasComponent(component))
                return true;
        }
        return false;
    }

    public function removeAllComponents(forceImmediate) {
        return this._entityManager.entityRemoveAllComponents(this, forceImmediate);
    }


    public function reset() {
        this.id = this._entityManager._nextEntityId++;
        this._componentTypes = [];
        this.queries = [];
        for (component in this._components) {
            component.reset();
        }
    }

    public function remove(forceImmediate = false) {
        return this._entityManager.removeEntity(this, forceImmediate);
    }
}