#!/bin/sh

$issues=`curl -D- -u stevew:M1sterD00 -X GET -H "Content-Type: application/json" "https://jira.giffgaff.co.uk/rest/api/2/search?jql=project%20in%20(\"Gameplan%20App\")%20AND%20type%20in%20(Story,%20Epic,%20Spike,%20Defect)%20AND%20(resolution%20in%20(Complete,%20Fixed,%20\"Fixed%20(Externally)\",%20Done)%20OR%20resolution%20is%20EMPTY)%20ORDER%20BY%20created%20ASC&fields=customfield_15201,customfield_15305&startAt=50"`
