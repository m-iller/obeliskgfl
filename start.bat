@echo off
cls  
title srcds.com Watchdog 
:srcds 
echo (%time%) srcds started. 
start /wait srcds.exe -console -game garrysmod +map gm_construct +maxplayers 2 +port 27015 +gamemode obelisk +host_workshop_collection 3581244434 
goto srcds
quit