package ecsy;

import ecsy.Component.ComponentConstructor;
import ecsy.Query.Matcher;
import haxe.ds.StringMap;
import Lambda;
class QueryManager {
    public var _world:World;
    public var _matcher_queries:StringMap<Query>;

    public function new(world:World) {
        this._world = world;

        // Queries indexed by a unique identifier for the components it has
        this._matcher_queries = new StringMap<Query>();
    }

    public function onEntityRemoved(entity:Entity) {
        for (query in this._matcher_queries.iterator()) {
            if (Lambda.has(entity.queries, query)) {
                query.removeEntity(entity);
            }
        }
    }

    /**
     * Callback when a component is added to an entity
     * @param {Entity} entity Entity that just got the new component
     * @param {Component} Component Component added to the entity
     */
    public function onEntityComponentAdded(entity:Entity, component:ComponentConstructor) {
        // @todo Use bitmask for checking components?

        // Check each indexed query to see if we need to add this entity to the list
        for (query in this._matcher_queries.iterator()) {

            if (Lambda.has(query.notComponents, component)
            && Lambda.has(query.entities, entity)) {
                query.removeEntity(entity);
                continue;
            }

            // Add the entity only if:
            // Component is in the query
            // and Entity has ALL the components of the query
            // and Entity is not already in the query
            if (
            !Lambda.has(query.components, component) ||
            !query.match(entity) ||
            Lambda.has(query.entities, entity)
            )
                continue;

            query.addEntity(entity);
        }
    }

    /**
     * Callback when a component is removed from an entity
     * @param {Entity} entity Entity to remove the component from
     * @param {Component} Component Component to remove from the entity
     */
    public function onEntityComponentRemoved(entity:Entity, component:ComponentConstructor) {
        for (query in this._matcher_queries.iterator()) {


            if (
            Lambda.has(query.notComponents, component) &&
            !Lambda.has(query.entities, entity) &&
            query.match(entity)
            ) {
                query.addEntity(entity);
                continue;
            }

            if (
            Lambda.has(query.components, component) &&
            Lambda.has(query.entities, entity) &&
            !query.match(entity)
            ) {
                query.removeEntity(entity);
                continue;
            }
        }
    }

    /**
     * Get a query for the specified components
     * @param {Component} Components Components that the query should have
     */
    public function getQuery(queryConfig:Matcher) {
        var key:String = Util.queryKey(queryConfig.allOfComponents, queryConfig.noneOfComponents);
        var query:Query = cast this._matcher_queries.get(key);
        if (!this._matcher_queries.exists(key)) {
            query = new Query( queryConfig, this._world.entityManager);
            this._matcher_queries.set(key, query);
        }
        return query;
    }

}
  