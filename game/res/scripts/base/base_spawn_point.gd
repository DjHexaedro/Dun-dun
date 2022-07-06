# Base class for each individual position a powerup can spawn in. Even though I
# named it "base", it will probably be the only type of this object I'll make
extends Position2D

class_name BaseSpawnPoint


var enabled: bool = true
var being_used: bool = false
