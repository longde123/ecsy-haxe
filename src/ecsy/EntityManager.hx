package ecsy;
import Array;
import haxe.ds.Either;
import Lambda;
import ecsy.Component.ComponentConstructor;
import ecsy.Component.SystemStateComponent;
import haxe.macro.Expr.Error;
import haxe.ds.StringMap;
@:generic
class EntityPool<E> extends ObjectPool<E> {
    var entityManager:EntityManager;

    public function new(entityManager, entityClass:Class<E>, initialSize = 0) {
        super(entityClass, 0);
        this.entityManager = entityManager;

        if (initialSize != 0) {
            this.expand(initialSize);
        }
    }

    override public function expand(count) {
        for (n in 0...count) {
            var clone:E = cast Type.createInstance(T, [ this.entityManager]) ;
            this.freeList.push(clone);
        }
        this.count += count;
    }
}

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
    public var _entitiesByNames:StringMap<Entity>;
    public var entitiesWithComponentsToRemove:Array<Dynamic>;
    public var entitiesToRemove:Array<Dynamic>;
    public var deferredRemovalEnabled:Bool;
    public var _entityPool:EntityPool<Entity> ;
    public var eventDispatcher:EventDispatcher;
    public var _queryManager:QueryManager;

    public function new(world) {
        this.world = world;
        this.componentsManager = world.componentsManager;

        // All the entities in this instance
        this._entities = [];
        this._nextEntityId = 0;

        this._entitiesByNames = new StringMap<Entity>();

        this._queryManager = new QueryManager(this.world);
        this.eventDispatcher = new EventDispatcher();
        this._entityPool = new EntityPool<Entity> (
        this,
        this.world.options.entityClass,
        this.world.options.entityPoolSize
        );

        // Deferred deletion
        this.entitiesWithComponentsToRemove = [];
        this.entitiesToRemove = [];
        this.deferredRemovalEnabled = true;
    }

    public function getEntityByName(name) {
        return this._entitiesByNames.get(name);
    }

    /**
     * Create a new entity
     */
    public function createEntity(name) {
        var entity:Entity = cast this._entityPool.acquire();
        entity.alive = true;
        entity.name = name ;
        if (name != null) {
            if (this._entitiesByNames.exists(name)) {
                trace("Entity name '${name}' already exist");
            } else {
                this._entitiesByNames.set(name, entity);
            }
        }

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
    public function entityAddComponent(entity:Entity, component:ComponentConstructor, values) {
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

        var comp:Component = componentPool != null
        ? componentPool.acquire()
        : Type.createInstance(component, values);

        if (componentPool != null && values != null) {
            comp.copy(values);
        }

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
    public function entityRemoveComponent(entity:Entity, component:ComponentConstructor, immediately) {
        var index = Lambda.has(entity._componentTypes, component);
        if (!index) return;
        var comp:Component = Lambda.find(entity._components, function(c) return Std.is(c, component));
        this.eventDispatcher.dispatchEvent(COMPONENT_REMOVE, entity, comp);

        if (immediately) {
            this._entityRemoveComponentSync(entity, component, index);
        } else {
            if (entity._componentTypesToRemove.length == 0)
                this.entitiesWithComponentsToRemove.push(entity);
            entity._componentTypes.remove(component);
            entity._componentTypesToRemove.push(component);
            entity._components.remove(comp);
            entity._componentsToRemove.push(comp);
        }

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
        this.world.componentsManager.componentRemovedFromEntity(Component);
    }

    /**
     * Remove all the components from an entity
     * @param {Entity} entity Entity from which the components will be removed
     */
    public function entityRemoveAllComponents(entity:Entity, immediately) {
        var Components = entity._componentTypes;
        var j = Components.length - 1;
        while (j >= 0) {
            if (!Std.is(Components[j], SystemStateComponent))
                this.entityRemoveComponent(entity, Components[j], immediately);
            j--;
        }
    }

    /**
     * Remove the entity from this manager. It will clear also its components
     * @param {Entity} entity Entity to remove from the manager
     * @param {Bool} immediately If you want to remove the component immediately instead of deferred (Default is false)
     */
    public function removeEntity(entity:Entity, immediately = false) {

        if (!Lambda.has(this._entities, entity)) throw ("Tried to remove entity not in list");
        var index = this._entities.indexOf(entity);
        entity.alive = false;
        if (entity.numStateComponents == 0) {
            // Remove from entity list
            this.eventDispatcher.dispatchEvent(ENTITY_REMOVED, entity);
            this._queryManager.onEntityRemoved(entity);
            if (immediately == true) {
                this._releaseEntity(entity, index);
            } else {
                this.entitiesToRemove.push(entity);
            }
        }
        this.entityRemoveAllComponents(entity, immediately);
    }

    public function _releaseEntity(entity:Entity, index:Int) {
        this._entities.remove(entity);
        if (this._entitiesByNames.exists(entity.name)) {
            this._entitiesByNames.remove(entity.name);
        }
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

    public function processDeferredRemoval() {
        if (!this.deferredRemovalEnabled) {
            return;
        }
        for (i in 0... this.entitiesToRemove.length) {
            var entity = this.entitiesToRemove[i];
            var index = this._entities.indexOf(entity);
            this._releaseEntity(entity, index);
        }
        this.entitiesToRemove = [];

        for (i in 0... this.entitiesWithComponentsToRemove.length) {
            var entity:Entity = this.entitiesWithComponentsToRemove[i];
            while (entity._componentTypesToRemove.length > 0) {
                var component = entity._componentTypesToRemove.pop();

                var comp:Component = Lambda.find(entity._componentsToRemove, function(c) return Std.is(c, component));
                entity._componentsToRemove.remove(comp);

                var componentPool:ObjectPool<Component> = this.world.componentsManager.getComponentsPool(
                    component
                );
                comp.reset();
                componentPool.release(comp);
                this.world.componentsManager.componentRemovedFromEntity(Component);
            }
        }

        this.entitiesWithComponentsToRemove = [];
    }

    /**
     * Get a query based on a list of components
     * @param {Array(Component)} Components List of components that will form the query
     */
    public function queryComponents(allOfComponents:Array<ComponentConstructor>, noneOfComponents:Array<ComponentConstructor>) {
        return this._queryManager.getQuery(allOfComponents, noneOfComponents);
    }

    // EXTRAS

    /**
     * Return number of entities
     */
    public function count() {
        return this._entities.length;
    }

    /**
     * Return some stats
     */
    public function stats() {
//      var stats = {
//        numEntities: this._entities.length,
//        numQueries: Object.keys(this._queryManager._queries).length,
//        queries: this._queryManager.stats(),
//        numComponentPool: Object.keys(this.componentsManager._componentPool)
//          .length,
//        componentPool: {},
//        eventDispatcher: this.eventDispatcher.stats
//      };
//
//      for (var cname in this.componentsManager._componentPool) {
//        var pool = this.componentsManager._componentPool[cname];
//        stats.componentPool[cname] = {
//          used: pool.totalUsed(),
//          size: pool.count
//        };
//      }
//
//      return stats;
    }
}
  

  