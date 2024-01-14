#!/bin/bash

postgresqlconf=$(psql -qAt -c 'show config_file;')

declare -A settings=(
    ["max_connections"]=40
    ["shared_buffers"]=1GB
    ["effective_cache_size"]=3GB
    ["maintenance_work_mem"]=512MB
    ["checkpoint_completion_target"]=0.9
    ["wal_buffers"]=16MB
    ["default_statistics_target"]=500
    ["random_page_cost"]=4
    ["effective_io_concurrency"]=2
    ["work_mem"]=6553kB
    ["min_wal_size"]=4GB
    ["max_wal_size"]=16GB
)

for key in "${!settings[@]}"; do
    sed -i -r "s/^#?${key}.*/${key} = ${settings[${key}]}/" $postgresqlconf
done
