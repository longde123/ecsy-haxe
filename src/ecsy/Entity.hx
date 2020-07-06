package ecsy;
import ecsy.Component.ComponentConstructor;
import Lambda;
typedef EntityConstructor = Class<Entity>;
class Entity {
    public static var DEBUG = false;
    public var _entityManager:EntityManager;
    public var id:Int;
    public var _componentTypes:Array< ComponentConstructor>;
    public var numStateComponents:Int;
    public var alive:Bool;
    public var _components:Array<Component>;
    public var queries:Array<Query>;

    public function new(entityManager:EntityManager) {
        this._entityManager = entityManager ;

        // Unique ID for this entity
        this.id = entityManager._nextEntityId++;

        // List of components types the entity has
        this._componentTypes = [];

        // Instance of the components
        this._components = [];


        // Queries where the entity is added
        this.queries = [];


        this.alive = false;

        //if there are state components on a entity, it can't be removed completely
        this.numStateComponents = 0;
    }

    // COMPONENTS

    public function getComponent<C:Component>(componentClass:Class<C> ):C {
        var component = Lambda.find(this._components, function(c) return Std.is(c, componentClass));



        return cast  DEBUG ? Util.wrapImmutableComponent(cast componentClass, component) : component;
    }


    public function getComponents() {
        return this._components;
    }



    public function getComponentTypes() {
        return this._componentTypes;
    }

    public function getMutableComponent<C:Component>(component:Class<C>):C {
        var comp = getComponent(component);
        for (i in 0...this.queries.length) {
            var query:Query = this.queries[i];
            // @todo accelerate this check. Maybe having query._Components as an object
            // @todo add Not components
            if (query.reactive && Lambda.has(query.components, cast  component )) {
                query.eventDispatcher.dispatchEvent(
                    Query.COMPONENT_CHANGED,
                    this,
                    comp
                );
            }
        }

        this._entityManager.entityMutableComponent(this, comp);
        return cast comp;
    }

    public function addComponent(component:ComponentConstructor) {
        this._entityManager.entityAddComponent(this, component);
        return this;
    }

    public function removeComponent(component:ComponentConstructor) {
        this._entityManager.entityRemoveComponent(this, component);
        return this;
    }

    public function hasComponent(component:ComponentConstructor, includeRemoved = false) {
        var had = Lambda.has(this._componentTypes, component);

        return had  ;
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

    public function removeAllComponents() {
        return this._entityManager.entityRemoveAllComponents(this);
    }


    public function reset() {
        this.id = this._entityManager._nextEntityId++;
        this._componentTypes = [];
        this.queries = [];
        for (component in this._components) {
            component.reset();
        }
    }

    public function remove() {
        return this._entityManager.removeEntity(this);
    }
}