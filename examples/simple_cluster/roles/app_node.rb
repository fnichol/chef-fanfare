name "app_node"
description "An application node in a cluster."

run_list(
  "recipe[nginx]",
  "recipe[fanfare::applications]"
)
