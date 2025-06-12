@echo off
cd /d "C:\plantuml-server"

prunsrv.exe //IS//PlantUMLServer ^
--DisplayName="PlantUML Server" ^
--Description="PlantUML Diagram Generation Server" ^
--Install="C:\plantuml-server\prunsrv.exe" ^
--Jvm="C:\Program Files\Java\jdk-24\bin\server\jvm.dll" ^
--StartMode=exe ^
--StartImage="C:\Program Files\Apache\maven\bin\mvn.cmd" ^
--StartPath="C:\plantuml-server" ^
--StartParams="jetty:run;-Djetty.http.port=91" ^
--StopMode=exe ^
--StopImage="taskkill.exe" ^
--StopParams="/F;/IM;java.exe" ^
--LogPath="C:\plantuml-server\logs" ^
--StdOutput=auto ^
--StdError=auto ^
--Startup=auto

echo Service installed successfully!
pause
