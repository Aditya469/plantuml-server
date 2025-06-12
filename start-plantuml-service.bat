@echo off
cd /d "C:\Users\Rama\plantuml-server"
mvn jetty:run -Djetty.http.port=91
