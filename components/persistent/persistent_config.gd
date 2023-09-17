class_name PersistentConfig
extends Resource


## Persistent Configuration Resource
##
## This resource holds basic information about an application using the
## persistence system.


## Game save-file encryption password
@export var save_file_password : String = ""

## Database of all persistent zones in the game
@export var zone_database : PersistentZoneDatabase

## Database of all persistent item types in the game
@export var item_database : PersistentItemDatabase

## The applications starting zone
@export var starting_zone : PersistentZoneInfo
