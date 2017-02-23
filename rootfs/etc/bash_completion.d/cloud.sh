# Tab complete `cloud` commands
function _cloud_complete() {
  local targets=("${COMP_WORDS[@]}")
  local i=0
  local command

  # Pop off command
  targets=("${targets[@]:1}")
  [[ $targets ]] || targets=(".*")

  # If a cluster module is defined, it takes presedence 
  if [ -n "${targets[0]}" ] && [ -d "${LOCAL_STATE}/clusters/${CLUSTER_NAME}/${targets[0]}" ]; then
    cd "${LOCAL_STATE}/clusters/${CLUSTER_NAME}"
  else
    cd "$GEODESIC_PATH"
  fi

  while [[ $targets ]]; do
    arg=${targets[0]}
    # If it's a directory, we assume it's a module
    if [ -d "$arg" ]; then
      targets=("${targets[@]:1}")
      command=("make" "--no-print-directory" "help")
      cd "$arg"
    elif [ -f "$arg" ]; then
      targets=("${targets[@]:1}")
      command=("make" "--no-print-directory" "-f" "${arg}" "help")
      break
    else
      command=("make" "--no-print-directory" "help")
      break
    fi
  done
  query="^${targets[@]:-.*}"
  for w in $("${command[@]}" | grep -Eo '^ +[^ ]+' | sed 's/^ *//g' | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep "${query}"); do
    COMPREPLY[i++]="$w"
  done
}

complete -F _cloud_complete cloud
