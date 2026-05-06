#!/bin/bash

PAT='^mongodb://(.*):(.*)@(.*)/(.*)$'

mkdir -p /tmp/dbinit-scripts

for file_full_path in /cognigy-ai-dbinit/mongodb-connection-strings/*
do
  STRING=$(cat $file_full_path)
  [[ $STRING =~ $PAT ]] # check if the string matches the pattern

  USER=${BASH_REMATCH[1]}
  PASSWORD=${BASH_REMATCH[2]}
  HOSTS=${BASH_REMATCH[3]}
  DB=${BASH_REMATCH[4]}

  file_name=${file_full_path##*/}

  if [ "$file_name" == "cognigy-service-testing-billing" ]; then
    cat > /tmp/dbinit-scripts/$file_name.js <<-EOF
if (db.getSiblingDB("$DB").getRole("billingAppendOnly") == null) {
  db.getSiblingDB("$DB").createRole({
    role: "billingAppendOnly",
    privileges: [
      {
        resource: { db: "$DB", collection: "billingsimulationruns" },
        actions: ["insert", "find", "listIndexes", "collStats", "indexStats", "createCollection"]
      },
      {
        resource: { db: "$DB", collection: "preAggregateBillingSimulationRuns" },
        actions: ["find", "insert", "update", "createIndex", "dropIndex", "listIndexes", "collStats", "indexStats"]
      },
      {
        resource: { db: "$DB", collection: "" },
        actions: ["createCollection", "listCollections", "find"]
      }
    ],
    roles: []
  });
}

if (db.getSiblingDB("$DB").getUser("$USER") == null) {
  db.getSiblingDB("$DB").createUser({
    user: "$USER",
    pwd: "$PASSWORD",
    roles: [
      { role: "billingAppendOnly", db: "$DB" }
    ]
  });
}
EOF
  else
    cat > /tmp/dbinit-scripts/$file_name.js <<-EOF
if (db.getSiblingDB("$DB").getUser("$USER") == null) {
  db.getSiblingDB("$DB").createUser({
    user: "$USER",
    pwd: "$PASSWORD",
    roles: [
      { role: "readWrite", db: "$DB" }
    ]
  });
}
EOF
  fi
done
MONGODB_PRIMARY_HOST=`mongosh -u $MONGODB_USERNAME -p $MONGODB_PASSWORD --authenticationDatabase admin mongodb://$MONGODB_HOSTS --eval "rs.status().members.find(r=>r.state===1).name" --quiet`
echo "MongoDB primary host: $MONGODB_PRIMARY_HOST"
mongosh -u $MONGODB_USERNAME -p $MONGODB_PASSWORD --authenticationDatabase admin mongodb://$MONGODB_PRIMARY_HOST /tmp/dbinit-scripts/*