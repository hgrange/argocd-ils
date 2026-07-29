#!/bin/bash -xv

post_incident() {
set -xv
curdate=$(date +"%Y/%m/%d %H:%M:%S")
cat << EOF | jq -c
{"checked":"false",
"id":$tid,
"title":"$project $ownerEmail No assertion",
"description":"$comment",
"project":"$project",
"ownerEmail":"$ownerEmail",
"openingDate":"$curdate",
"closedDate":" ",
"status":"$incidentStatus"}
EOF
}



insert_data()
{
  curl -s -k -X 'PUT'  -H 'Content-Type: application/json' https://$apihost/workloads/$1/custom_columns/$2?token=$token -d "{\"value\":\"$3\"}"
}

delete_data()
{
  curl -s -k -X 'DELETE'  -H 'Content-Type: application/json' https://$apihost/workloads/$1/custom_columns/$2?token=$token 
}

NAMESPACE_REPORTER=reporter
token=AAAAAAAAAAAAAAAAAAAAAAAA
apihost=ibm-license-service-reporter-reporter.apps.ocp.82.66.156.8.nip.io 
cmdbhost=itsm-reporter.apps.ocp.82.66.156.8.nip.io
cmdbUrl="http://192.168.14.25:9080"
cmdbUrl="https://$cmdbhost"
firstLoop=true

#for iter in 1 2
#do

curl -s -k -X "GET"  -H 'Content-Type: application/json'  https://$apihost/workloads?token=$token  > /data/workloads.json
gzip -c   /data/workloads.json > /data/workloads/workloads.json.$(date +"%Y_%m_%d-%H:%M").gz   
curl -s -k -X "GET"  -H 'Content-Type: application/json'  https://$apihost/custom_columns?token=$token > /data/custom_columns.json
curl -s -k -X "GET"  -H 'Content-Type: application/json'  $cmdbUrl/v2/cmdbs > /data/cmdbs.json

#"id":122,"kind":"Deployment","name":"es1-ibm-es-metrics","namespace":"cp4i","clusterId":"ClusterTest1","clusterName":"Cluster1","chargebackGroupName":"","replicas":1,"containers":[{"name":"metrics","image":"cp.icr.io/cp/ibm-eventstreams-metrics-collector@sha256:fb8f5b6d49c629007b930ee280f2f6055d8cb3d3e52d95cebd1ec3eca73dd0e9","charged":false,"components":null}],"annotations":"IBM_Event_Streams_for_Non_Production/VIRTUAL_PROCESSOR_CORE/IBM_Cloud_Pak_for_Integration/VIRTUAL_PROCESSOR_CORE/2:1","customColumns":[]},{

#{"cluster":"cluster1","namespace":"namespace1","ownerEmail":"herve@ibm.com","project":"app1","sid":"cluster1_app1"}

#[{"id":1,"name":"SAM Status","type":"text"},{"id":2,"name":"Project","type":"text"},{"id":3,"name":"Project Owner","type":"text"},{"id":4,"name":"ServiceNow status","type":"text"},{"id":5,"name":"ServiceNow ticket","type":"text"},{"id":6,"name":"Comment","type":"text"},{"id":7,"name":"Remediation needed","type":"text"}]

list_id=$(cat /data/workloads.json | jq '.[].id' | sort -n)
echo $list_id

idcol_ownerEmail=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"Project\ Owner\" | tr ',' '\12' | grep {\"id\" | awk -F: '{ print $2 }' )
idcol_project=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"Project\" | tr ',' '\12' | grep {\"id\" | awk -F: '{ print $2 }' )
idcol_ticket=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"ServiceNow\ ticket\" | tr ',' '\12' | grep {\"id\" | awk -F: '{ print $2 }' )
idcol_comment=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"Comment\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_status=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"ServiceNow\ status\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_recId=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"RecId\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_samStatus=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"SAM\ Status\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_remediation=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"Remediation\ needed\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_test=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"TEST\ ANNOTATION\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_date=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"Date\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')
idcol_charged=$( cat /data/custom_columns.json | sed 's/{"id":/\n{"id":/g' | grep \"name\":\"Charged\"  | tr ',' '\12' | grep {\"id\" |  awk -F: '{ print $2 }')

#for recId in $list_id
for recId in 2            
do
    rec=$(cat /data/workloads.json | jq ".[] | select (.id==$recId)" | jq -c )
    namespace=$( echo $rec | tr ',' '\12' | grep namespace | awk -F\" '{ print $4 }' )
    cluster=$( echo $rec | tr ',' '\12' | grep clusterName | awk -F\" '{ print $4 }' )
    charged=$( echo $rec | tr ',' '\12' | grep charged | awk -F: '{ print $2 }' )
    annotations=$( echo $rec | jq .annotations ) 
    container=$( echo $rec | tr ',' '\12' | grep containers | awk -F\" '{ print $(NF-1) }' )
    image=$( echo $rec | tr ',' '\12' | grep image | awk -F\" '{ print $(NF-1) }')
    components=$( echo $rec |  jq '[.containers[].components[].name,.containers[].components[].version]' | jq -c | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' )

    recCmdb=$(cat /data/cmdbs.json | sed 's/{"c/\n{"c/g' | grep -i \"namespace\":\"$namespace\" | grep -i \"cluster\":\"$cluster\")
    ownerEmail=$(echo $recCmdb | tr ',' '\12' | grep ownerEmail | awk -F\" '{ print $4 }' )
    echo $ownerEmail
    project=$(echo $recCmdb | tr ',' '\12' | grep project | awk -F\" '{ print $4 }' )
    remediationNeeded=$(echo $rec | jq -r ".customColumns[] | select (.name==\"Remediation needed\")|.value")
    comment=$(echo $rec | jq -r ".customColumns[] | select (.name==\"Comment\")|.value")
    samStatus=$(echo $rec | jq -r ".customColumns[] | select (.name==\"SAM Status\")|.value")
    tid=$(echo $rec | jq -r ".customColumns[] | select (.name==\"ServiceNow ticket\")|.value")
    test=$(echo $rec | jq -r ".customColumns[] | select (.name==\"TEST ANNOTATION\")|.value")
    echo test=$test 
    if [ $( echo _$test | grep -i without | wc -c ) -ge 7 ]; then
      if [ $(firstLoop) == "true" ]; then
        bash -xv /data/deploy-NoAnnotation.sh
      else
        bash -xv /data/deploy-WithAnnotations.sh
      fi
      firstLoop=false;
    fi

    
    if [ $(echo "_"$remediationNeeded | grep -i yes | wc -l) -gt 0 ]; then
       if [ $( echo $tid | wc -c) -lt 10 ]; then 

          incidentStatus="Open"
          tid=$(date +%s)
          tid=$(curl -s -k -X 'POST' $cmdbUrl/v2/incident -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d "$(post_incident)"  )
          echo $tid
          if [ $( echo $comment | wc -c ) -lt 3 ]; then
             comment="Wrong assertion for Container $container, with components $components"
          fi
          insert_data $recId $idcol_project $project
          insert_data $recId $idcol_comment "$comment"
          insert_data $recId $idcol_ownerEmail $ownerEmail
          insert_data $recId $idcol_ticket $tid
          insert_data $recId $idcol_recId $recId
          insert_data $recId $idcol_charged $charged
          delete_data $recId $idcol_remediation
       else
          #echo  Reouvrir Incident
          incidentStatus="Open"
          curl -s -k -X 'PUT' $cmdbUrl/v2/incident -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d "$(post_incident)"  
          delete_data $recId $idcol_remediation
       fi
#   elif [ $( echo $charged | grep null | egrep -v 'true|false' | wc -l ) -gt 0 ]; then
    elif [[ $( echo $annotations | grep null | wc -c ) -ge 5  && $( echo $charged | grep true | wc -c) -ge 4 ]]; then
       if [ $( echo $tid | wc -c) -lt 10 ]; then 

          #comment="No assertion for Container $container, with components $components"
       
          #tid=$(curl -s -k  -X 'POST' $cmdbUrl/v2/incident -H 'accept: application/json' -H 'Content-Type: application/json' \
          #     -d "$(post_incident)"  )
          #echo $tid
          insert_data $recId $idcol_project $project
          #insert_data $recId $idcol_comment "$comment"
          insert_data $recId $idcol_ownerEmail $ownerEmail
          #insert_data $recId $idcol_ticket $tid
          insert_data $recId $idcol_recId $recId
          insert_data $recId $idcol_samStatus "Open"
          insert_data $recId $idcol_charged $charged
          insert_data $recId $idcol_date "$(date +"%y%m%d-%H:%M")"
       else
          insert_data $recId $idcol_samStatus "Open"
       fi
    else
       if [ $(echo $rec | jq -r ".customColumns[] | select (.name==\"Project\")|.value" | wc -c) -eq 0 ]; then
         insert_data $recId $idcol_project $project
       fi
       if [ $(echo $rec | jq -r ".customColumns[] | select (.name==\"Project Owner\")|.value" | wc -c) -eq 0 ]; then
         insert_data $recId $idcol_ownerEmail $ownerEmail
       fi
       insert_data $recId $idcol_charged $charged
       insert_data $recId $idcol_recId  $recId
    fi 

    if [ $( echo $tid | wc -c) -ge 10 ]; then 
       echo Retrieve Status !!!!!
       status=$(curl -k -s $cmdbUrl/v2/incident/$tid | jq -r '.status')
       if [ $(echo $status | wc -c ) -le 1 ]; then
         delete_data $recId $idcol_ticket  
         delete_data $recId $idcol_status  
#         delete_data $recId $idcol_recId  
         delete_data $recId $idcol_comment  
         delete_data $recId $idcol_samStatus
       else 
         echo status: $status
         insert_data $recId $idcol_status $status
       fi
    fi
done   
#done    
    






    


