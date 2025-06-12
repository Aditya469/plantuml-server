Set up Windows Task Scheduler:

Press Win + R, type taskschd.msc

Click "Create Basic Task"

Name: "PlantUML Server"

Trigger: "When the computer starts"

Action: "Start a program"

Program: C:\plantuml-server\start-plantuml-service.bat

Check "Run with highest privileges"

Verify Service Installation
Open Services (press Win + R, type services.msc)

Look for "PlantUML Server" in the list

Right-click and select "Start" to test

Check http://localhost:91/plantuml in your browser