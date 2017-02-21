# Tab complete `cloud` commands
function _cloud_complete() {
  local targets=("${COMP_WORDS[@]}")
  local i=0
  local command

  # Pop off command
  targets=("${targets[@]:1}")
  [[ $targets ]] || targets=(".*")

  cd /geodesic/modules
  while [[ $targets ]]; do
    arg=${targets[0]}
    # If it's a directory, we assume it's a module
    if [ -d "$arg" ]; then
      targets=("${targets[@]:1}")
      cd "$arg"
    elif [ -f "$arg" ]; then
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
