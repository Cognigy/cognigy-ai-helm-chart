#!/bin/bash
set -e

# Check if required environment variables are set
if [[ -z $INSIGHTS_POSTGRES_PASSWORD || -z $INSIGHTS_POSTGRES_HOSTS ]]
then
  echo "Environment variables INSIGHTS_POSTGRES_PASSWORD and INSIGHTS_POSTGRES_HOSTS must be set."
  exit 1
fi

is_primary_replica() {
  local host=$1
  local max_retries=10 # Assuming in 10 seconds pod will be ready
  local retries=0

  while [[ $retries -lt $max_retries ]]; do
      local result=$(PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h "$host" -U postgres -c "SELECT pg_is_in_recovery();" | head -3 | tail -1)
      if [[ $result == *"f"* ]]; then
          return 0 # 0 means true in shell :D
      elif [[ $result == *"t"* ]]; then
          return 1
      else
          retries=$((retries+1))
          sleep 1  # Wait for 1 second before retrying
      fi
  done

  exit 1 # Exit here, so that Kuberentes can restart the pod
}

# Find primary host
IFS=' ' read -ra HOSTS <<< "$INSIGHTS_POSTGRES_HOSTS"
for HOST in "${HOSTS[@]}"; do
  if is_primary_replica $HOST; then
    INSIGHTS_POSTGRES_HOST=$HOST
    break
  fi
done

# Default database name
if [ -n "$INSIGHTS_POSTGRES_DB_NAME" ]; then
  DATABASE="$INSIGHTS_POSTGRES_DB_NAME"
else
  DATABASE="service_analytics_collector"
fi

create_user() {
  local psql_command=$(cat <<EOF
    DO
    \$$
    BEGIN
        IF EXISTS (
            SELECT FROM pg_catalog.pg_user
            WHERE usename= '$1') THEN
            RAISE NOTICE 'User $1 already exists. Skipping.';
        ELSE
            CREATE USER "$1" WITH PASSWORD '$2';
        END IF;
    END
    \$$;
EOF
)
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -tc "$psql_command"
}

grant_access() {
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -tc "GRANT ALL PRIVILEGES ON DATABASE $DATABASE TO \"$1\";"
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -tc "GRANT CREATE ON DATABASE $DATABASE TO \"$1\";"
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -d $DATABASE -tc "GRANT CREATE ON SCHEMA public TO \"$1\";"
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -d $DATABASE -tc "GRANT ALL ON ALL TABLES IN SCHEMA public TO \"$1\";"
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -d $DATABASE -tc "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO \"$1\";"
  PGPASSWORD=$INSIGHTS_POSTGRES_PASSWORD psql -h $INSIGHTS_POSTGRES_HOST -U postgres -d $DATABASE -tc "GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO \"$1\";"
}

for file_full_path in /cognigy-insights-dbinit/passwords/*
do
  USERNAME=${file_full_path##*/}
  PASSWORD=$(cat $file_full_path)

  echo "Creating user '$USERNAME'..."
  create_user $USERNAME "$PASSWORD"
  echo "Granting access to '$USERNAME'..."
  grant_access $USERNAME
done