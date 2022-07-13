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
done

mongo -u $MONGODB_USERNAME -p $MONGODB_PASSWORD --authenticationDatabase admin $MONGODB_HOSTS /tmp/dbinit-scripts/*