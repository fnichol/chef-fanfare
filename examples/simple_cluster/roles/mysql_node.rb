name "mysql_node"
description "A MySQL node in a cluster."

run_list(
  "recipe[mysql::server]",
  "recipe[fanfare::databases]"
)
