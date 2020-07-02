package ecsy;

class ObjectPool<TClass> {
    // @todo Add initial size
    var T:Class<TClass>;
    var isObjectPool:Bool;
    var count:Int;
    var freeList:Array<TClass>;

    public function new(T:Class<TClass>, initialSize = 0) {
        this.freeList = [];
        this.count = 0;
        this.T = T;
        this.isObjectPool = true;

        if (initialSize != 0) {
            this.expand(initialSize);
        }
    }

    public function acquire():TClass {
        // Grow the list by 20%ish if we're out
        if (this.freeList.length <= 0) {
            this.expand(Math.round(this.count * 0.2) + 1);
        }

        var item = this.freeList.pop();

        return item;
    }

    public function release(item:TClass) {
        this.freeList.push(item);
    }

    public function expand(count) {
        for (n in 0...count) {
            var clone:TClass = cast Type.createEmptyInstance(T) ;
            this.freeList.push(clone);
        }
        this.count += count;
    }

    public function totalSize() {
        return this.count;
    }

    public function totalFree() {
        return this.freeList.length;
    }

    public function totalUsed() {
        return this.count - this.freeList.length;
    }
}

class DummyObjectPool<TClass> {
    var T:Class<TClass>;
    var isDummyObjectPool:Bool;
    var count:Int;
    var used:Int;

    public function new(T:Class<TClass>) {
        this.isDummyObjectPool = true;
        this.count = 0;
        this.used = 0;
        this.T = T;
    }

    public function acquire() {
        this.used++;
        this.count++;
        return Type.createEmptyInstance(T) ;
    }

    public function release() {
        this.used--;
    }

    public function totalSize() {
        return this.count;
    }

    public function totalFree() {
        return Math.POSITIVE_INFINITY;
    }

    public function totalUsed() {
        return this.used;
    }
}
