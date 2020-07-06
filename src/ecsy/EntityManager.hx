package ecsy;
import Array;
import ecsy.Component.ComponentConstructor;
import ecsy.Component.SystemStateComponent;
import ecsy.Query.Matcher;
import haxe.ds.StringMap;
import Lambda;


/**
   * @private
   * @class EntityManager
   */
class EntityManager {
    static var ENTITY_CREATED = "EntityManager#ENTITY_CREATE";
    static var ENTITY_REMOVED = "EntityManager#ENTITY_REMOVED";
    static var COMPONENT_ADDED = "EntityManager#COMPONENT_ADDED";
    static var COMPONENT_REMOVE = "EntityManager#COMPONENT_REMOVE";
    public var world:World;
    public var componentsManager:ComponentManager;
    public var _entities:Array<Entity>;
    public var _nextEntityId:Int;
    public var _entityPool:ObjectPool<Entity> ;
    public var eventDispatcher:EventDispatcher;
    public var _queryManager:QueryManager;

    public function new(world) {
        this.world = world;
        this.componentsManager = world.componentsManager;

        // All the entities in this instance
        this._entities = [];
        this._nextEntityId = 0;


        this._queryManager = new QueryManager(this.world);
        this.eventDispatcher = new EventDispatcher();
        this._entityPool = new ObjectPool<Entity> ( function() return  new Entity(this), this.world.options.entityPoolSize);


    }



    /**
     * Create a new entity
     */
    public function createEntity( ) {
        var entity:Entity = cast this._entityPool.acquire();
        entity.alive = true;
        this._entities.push(entity);
        this.eventDispatcher.dispatchEvent(ENTITY_CREATED, entity);
        return entity;
    }

    // COMPONENTS

    /**
     * Add a component to an entity
     * @param {Entity} entity Entity where the component will be added
     * @param {Component} Component Component to be added to the entity
     * @param {Object} values Optional values to replace the default attributes
     */
    public function entityAddComponent(entity:Entity, component:ComponentConstructor) {
        if (!Lambda.has(this.world.componentsManager.components, component)) {
            throw ("Attempted to add unregistered component  " );
        }

        if (Lambda.has(entity._componentTypes, component)) {
            // @todo Just on debug mode
            trace(
                "Component type already exists on entity.",
                entity,
                component
            );
            return;
        }

        entity._componentTypes.push(component);

        if (component == SystemStateComponent) {
            entity.numStateComponents++;
        }

        var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(
            component
        );

        var comp:Component = componentPool.acquire();
        comp.reset();

        entity._components.push(comp) ;

        this._queryManager.onEntityComponentAdded(entity, component);
        this.world.componentsManager.componentAddedToEntity(component);

        this.eventDispatcher.dispatchEvent(COMPONENT_ADDED, entity, comp);
    }

    /**
     * Remove a component from an entity
     * @param {Entity} entity Entity which will get removed the component
     * @param {*} Component Component to remove from the entity
     * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
     */
    public function entityRemoveComponent(entity:Entity, component:ComponentConstructor ) {
        var index = Lambda.has(entity._componentTypes, component);
        if (!index) return;
        var comp:Component = Lambda.find(entity._components, function(c) return Std.is(c, component));
        this.eventDispatcher.dispatchEvent(COMPONENT_REMOVE, entity, comp);

            this._entityRemoveComponentSync(entity, component, index);


        // Check each indexed query to see if we need to remove it
        this._queryManager.onEntityComponentRemoved(entity, component);

        if (Std.is(component, SystemStateComponent)) {
            entity.numStateComponents--;

            // Check if the entity was a ghost waiting for the last system state component to be removed
            if (entity.numStateComponents == 0 && !entity.alive) {
                entity.remove();
            }
        }
    }

    public function _entityRemoveComponentSync(entity:Entity, component:ComponentConstructor, index) {
        // Remove T listing on entity and property ref, then free the component.
        entity._componentTypes.remove(component);
        var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(
            component
        );
        var comp:Component = Lambda.find(entity._components, function(c) return Std.is(c, component));
        entity._components.remove(comp);
        comp.reset();
        componentPool.release(comp);
        this.world.componentsManager.componentRemovedFromEntity(component);
    }

    /**
     * Remove all the components from an entity
     * @param {Entity} entity Entity from which the components will be removed
     */
    public function entityRemoveAllComponents(entity:Entity) {
        var Components = entity._componentTypes;
        var j = Components.length - 1;
        while (j >= 0) {
            if (!Std.is(Components[j], SystemStateComponent))
                this.entityRemoveComponent(entity, Components[j]);
            j--;
        }
    }

    /**
     * Remove the entity from this manager. It will clear also its components
     * @param {Entity} entity Entity to remove from the manager
     * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
     */
    public function removeEntity(entity:Entity) {
        if (!Lambda.has(this._entities, entity)) throw ("Tried to remove entity not in list");
        var index = this._entities.indexOf(entity);
        entity.alive = false;
        if (entity.numStateComponents == 0) {
            // Remove from entity list
            this.eventDispatcher.dispatchEvent(ENTITY_REMOVED, entity);
            this._queryManager.onEntityRemoved(entity);

                this._releaseEntity(entity, index);

        }
        this.entityRemoveAllComponents(entity);
    }

    public function _releaseEntity(entity:Entity, index:Int) {
        this._entities.remove(entity);
        this._entityPool.release(entity);
    }

    /**
     * Remove all entities from this manager
     */
    public function removeAllEntities() {
        var i = this._entities.length - 1;
        while (i >= 0) {
            this.removeEntity(this._entities[i]);
            i--;
        }
    }


    /**
     * Get a query based on a list of components
     * @param {Array(Component)} Components List of components that will form the query
     */
    public function queryComponents(queryConfig:Matcher) {
        return this._queryManager.getQuery(queryConfig);
    }

    // EXTRAS

    /**
     * Return number of entities
     */
    public function count() {
        return this._entities.length;
    }

}
  

  