#!/bin/bash
#
# changelog:
#  (0.1)    2021-04-01 :: Created
#           2021-04-02 :: Working low-level example, namespaces don't work
#           2021-04-03 :: Added concept of namespaces, seems to work
#  (0.2)    2021-04-05 :: NS's didn't work, keys would overwrite. The key/next
#                         arrays were not global, and behaved as indexed arrays
#  (0.3)    2021-04-15 :: Renaming public methods to avoid collisions. Changing
#                         from 'Class' -> '.node' for accuracy
#           2021-04-16 :: Improved sourcing functionality
#           2021-04-19 :: Removed all calls to `sed`, replacing with substring
#                         removal. Much faster to not call so many subprocesses.

#──────────────────────────────────( prereqs )──────────────────────────────────
# Version requirement: >4
[[ ${BASH_VERSION%%.*} -lt 4 ]] && {
   echo -e "\n[${BASH_SOURCE[0]}] ERROR: Requires Bash version >= 4\n"
   exit 1
}

# Verification if we've sourced this in other scripts. Name is standardized.
# e.g., filename 'mk-conf.sh' --> '__source_mk_conf=true'
__fname__="$( basename "${BASH_SOURCE[0]%.*}" )"
declare "__source_${__fname__//[^[:alnum:]]/_}__"=true


#═════════════════════════════════╡ FUNCTIONS ╞═════════════════════════════════
#──────────────────────────────────( public )───────────────────────────────────
# There are no real 'public' or 'private' methods, however the user-facing funcs
# are given a '.XXXX' name, rather than '__XXXX__', to avoid name collisions.

function .node {
   #─────────────────────────────( define name )────────────────────────────────
   # Defaults:
   __verbose__=false

   while [[ $# -gt 0 ]] ; do
      case "$1" in
         -p|--parents|--parent)                    # Sets as child to existing
            shift                                  # parent node.
            local parents="$1" ; shift
            ;;
         -v|--verbose)                             # Echo's more information on
            __verbose__=true ; shift               # function creation for debug
            ;;
         *)
            # TODO: rework. Feels silly to repeatedly assign each additional arg
            #       onto the short_name. Maybe just assign $1 then break?
            local short_name="$1" ; shift
            ;;
      esac
   done

   local fqfn parent_fqfn
   if [[ -z "$parents" ]] ; then
      fqfn=$short_name                             # If no parent, gets a top-
   else                                            # level name, for easy call
      parents="${parents//[.,]/ }"

      parent_fqfn=$( $parents __fqname__ )         # Else 'private' name, nested
      fqfn="${parent_fqfn}__${short_name}"         # under the parent's name

      $parent_fqfn __next__ $short_name $fqfn
   fi

   $__verbose__ && {
      echo "Creating '${short_name}', qualified as '${fqfn}', parents: ${parents// /,}"
   }

   #────────────────────────────( create state )────────────────────────────────
   declare -gA ${fqfn}__keys
   declare -gA ${fqfn}__next
   
   #───────────────────────────( build function )───────────────────────────────
   eval "
   function $fqfn {
         case \"\$1\" in
            #────────────────────────( set )────────────────────────────────────
            __set__)
                  shift
                  ${fqfn}__keys[\$1]=\"\${@:2}\"
                  return 0
                  ;;
            __aset__)
                  shift
                  ${fqfn}__keys[\$1]+=\"\${${fqfn}__keys[\$1]:+\\n}\${@:2}\"
                  return 0
                  ;;
            __next__)
                  shift
                  ${fqfn}__next[\$1]=\"\$2\"
                  return 0
                  ;;
            #───────────────────────( query )───────────────────────────────────
            __name__)
                  echo \"$short_name\"
                  return 0
                  ;;
            __fqname__)
                  echo \"$fqfn\"
                  return 0
                  ;;
            __children__)
                  echo \"\${!${fqfn}__next[@]}\"
                  return 0
                  ;;
            __find__)
                  shift
                  if [[ -z \$@ ]] ; then
                     echo \"${short_name}\" 
                     return 0
                  fi
                   
                  local next=\"\${${fqfn}__next[\$1]}\"
                  shift

                  if [[ -n \"\$next\" ]] ; then
                     \$next __find__ \$@
                  else
                     echo \"${short_name}\" 
                     return 0
                  fi
                  ;;
            #────────────────────────( do )─────────────────────────────────────
            __activate__)
                  for _key in \"\${!${fqfn}__keys[@]}\" ; do
                     local _val=\"\${${fqfn}__keys[\"\$_key\"]}\"
                     declare -g \$_key=\"\$_val\"
                  done
                  return 0
                  ;;
            __deactivate__)
                  for _key in \"\${!${fqfn}__keys[@]}\" ; do
                     unset _key
                  done
                  return 0
                  ;;
         esac

         if [[ \$# -eq 1 ]] ; then
            local val=\"\${${fqfn}__keys[\$1]}\"
            [[ -n \"\$val\" ]] && {
               echo -e \"\$val\" ; return 0
            } || return 1
         elif [[ \$# -gt 1 ]] ; then
            local next=\"\${${fqfn}__next[\$1]}\"
            [[ -n \"\$next\" ]] && {
               shift
               \$next \$@
            } || return 2
         fi
      }
   "
}
