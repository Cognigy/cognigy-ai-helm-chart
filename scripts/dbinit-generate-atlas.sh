#!/bin/bash

# example connection string: mongodb+srv://user:foo@cluster-atlas.ygo1m.mongodb.net/dbname
ATLAS_CONNECTION_STRING_PATTERN='^(.*)://(.*):(.*)@(.*)/(.*)$'

# the script requires the following variables to be set
# MONGODB_ATLAS_PUBLIC_API_KEY
# MONGODB_ATLAS_PRIVATE_API_KEY
# MONGODB_ATLAS_PROJECT_ID
# MONGODB_ATLAS_CLUSTER_NAME

# prepare environment for privacy
export MONGODB_ATLAS_SKIP_UPDATE_CHECK=true
export DO_NOT_TRACK=rue
export MONGODB_ATLAS_OUTPUT=json

echo "check connection to Atlas Cluster"
atlas clusters list

for file_full_path in /cognigy-ai-dbinit/mongodb-connection-strings/*
do
  DBCONURI=$(cat $file_full_path)
  DBCONURI=$(echo $DBCONURI | cut -d "?" -f1)
   # check if the string matches the pattern
  [[ $DBCONURI =~ $ATLAS_CONNECTION_STRING_PATTERN ]]

  # extract connection string data
  SCHEME=${BASH_REMATCH[1]}
  USER=${BASH_REMATCH[2]}
  PASSWORD=${BASH_REMATCH[3]}
  HOSTS=${BASH_REMATCH[4]}
  DB=${BASH_REMATCH[5]}

  # create a user that is readWrite restricted to the targetDatabase
  echo "Creating User for Database ${DB}"
  if [[ -n $(atlas dbusers describe ${USER}) ]]
  then
    echo "User ${USER} for Database ${DB} already exists, skipping..."
  else
    atlas dbusers create --username ${USER} --projectId ${MONGODB_ATLAS_PROJECT_ID} --password "${PASSWORD}" --scope "${MONGODB_ATLAS_CLUSTER_NAME}" --role "readWrite@${DB}"
  fi
done

echo "Display all users we have around for debug purposes later"
atlas dbusers list