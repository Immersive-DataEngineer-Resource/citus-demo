#!/bin/bash

DB_NAME="store"  # Database name
USER_NAME="postgres"  # Username

echo "======================================================================="
echo "MASTER"
echo "======================================================================="

MASTER_CONTAINER="citus-demo_master"

echo "Active worker count:"
docker exec -it "$MASTER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" -c "
    SELECT count(*) FROM master_get_active_worker_nodes();
" -tA
echo ""

echo "Get nodes"
docker exec -it "$MASTER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" -c "
    SELECT * FROM pg_dist_node;
"
echo ""


echo "Order shard placement:"
docker exec -i "$MASTER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" < "inspect_get_order_shard_placement.sql"
echo ""


SHARD_TABLE_NAMES=$(docker exec -i "$MASTER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" -tA < "inspect_get_order_shard_table_names.sql")
echo "Order shard table names:"
echo "$SHARD_TABLE_NAMES"
echo ""


SQL="SELECT count(1) FROM orders"
echo "$SQL"
docker exec -it "$MASTER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" -c "$SQL";
echo ""


for WORKER_CONTAINER in "citus-demo_worker_1" "citus-demo_worker_2" "citus-demo_worker_3"
do
    echo "======================================================================="
    echo "WORKER $WORKER_CONTAINER"
    echo "======================================================================="

    SQL="SELECT count(1) FROM orders"
    echo "$SQL"
    docker exec -it "$WORKER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" -c "$SQL";

    
    for SHARD_TABLE_NAME in $SHARD_TABLE_NAMES
    do
        SQL="select * from $SHARD_TABLE_NAME order by order_id limit 5"
        echo "$SQL"
        docker exec -it "$WORKER_CONTAINER" psql -U "$USER_NAME" -d "$DB_NAME" -c "$SQL"
    done

done