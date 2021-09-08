# cachet

[cachet](https://cachethq.io) is a beautiful and powerful open source status page system.

flip/flop

This project defines a docker container for the cachet which is an open source status page system.

https://cachethq.io
https://github.com/CachetHQ/Docker
https://github.com/CachetHQ/Cachet

## Issues

1. Move the sqlite db from running instance and setup with pv
2. Branch version is not right, probably need to break the two projects apart. The container tag version should just be the main one.
3. Confirm the setup stuff.


Setup

docker exec -it cachet php artisan key:generate
docker exec -it cachet php artisan config:clear
docker exec -it cachet php artisan config:cache

To-Do:

Move database.sqlite to /opt/docker/...
Document /opt/docker/...
Write clients...

Data Persistence
Location : /var/www/html/database/database.sqlite
 *Note:* the dtabase can be coppied via docker cp cachet:/var/www/html/database/database.sqlite ./
 
 https://cachet-client.readthedocs.io/en/latest/index.html
 
 pythonping requires root/sudo
 
 TO-DO:
 
 Need to created the requirements.txt file for the python components
 Create a docker file for the standalone container for testing, build off the existing docker container
 Create container for cachet.
move the devices like apple tv and lights out to guest network

