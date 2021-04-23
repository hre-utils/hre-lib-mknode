#!/bin/bash
source mk-node.sh

function test_standalone {
   for fn in $(seq 1 $1) ; do
      .node fn_$fn
   done
}


function test_with_parent {
   .node f0

   # Number of parents, cap out at 4.
   case $1 in
      1)    shift
            .node f1 -p f0
            parents='f0'
            ;;

      2)    shift
            .node f1 -p f0
            .node f2 -p f0,f1
            parents='f0 f1'
            ;;

      3)    shift
            .node f1 -p f0
            .node f2 -p f0,f1
            .node f3 -p f0,f1,f2
            parents='f0 f1 f2'
            ;;

      4)    shift
            .node f1 -p f0
            .node f2 -p f0,f1
            .node f3 -p f0,f1,f2
            .node f4 -p f0,f1,f2,f3
            parents='f0 f1 f2 f3'
            ;;

      *)    shift
            ;;
   esac

   .node f0
   for fn in $(seq 1 $1) ; do
      .node fn_$fn -p "${parents// /,}"
   done
}


function test_standalone_and_data {
   nodes=$1
   keys=$2

   for fn in $(seq 1 $nodes) ; do
      .node fn_$fn
      for i in $(seq 0 $keys) ; do
         "fn_$fn" __set__ "key$i" "value$i"
      done
   done
}


function test_with_parent_and_data {
   .node f0

   # Number of parents, cap out at 4.
   case $1 in
      1)    shift
            .node f1 -p f0
            parents='f0'
            ;;

      2)    shift
            .node f1 -p f0
            .node f2 -p f0,f1
            parents='f0 f1'
            ;;

      3)    shift
            .node f1 -p f0
            .node f2 -p f0,f1
            .node f3 -p f0,f1,f2
            parents='f0 f1 f2'
            ;;

      4)    shift
            .node f1 -p f0
            .node f2 -p f0,f1
            .node f3 -p f0,f1,f2
            .node f4 -p f0,f1,f2,f3
            parents='f0 f1 f2 f3'
            ;;

      *)    shift
            ;;
   esac

   nodes=$1
   keys=$2

   .node f0
   for fn in $(seq 1 $nodes) ; do
      .node fn_$fn -p "${parents// /,}"
      for i in $(seq 0 $keys) ; do
         $parents __set__ "key$i" "value$i"
      done
   done
}


echo    "═══════════════════════════════════╡ NO DATA ╞══════════════════════════════════"
echo -n "───────────────────────────────────( orphans )──────────────────────────────────"
time test_standalone 1000

echo -n "───────────────────────────────────( parents )──────────────────────────────────"
time test_with_parent 1 1000

echo -n "─────────────────────────────────( parents +2 )─────────────────────────────────"
time test_with_parent 2 1000

echo -n "─────────────────────────────────( parents +3 )─────────────────────────────────"
time test_with_parent 3 1000

#echo
#
#echo -e "════════════════════════════════════╡ DATA ╞════════════════════════════════════"
#echo -n "───────────────────────────────────( orphans )──────────────────────────────────"
#time test_standalone_and_data 100 500
#
#echo -n "───────────────────────────────────( parents )──────────────────────────────────"
#time test_with_parent_and_data 1 100 500
#
#echo -n "─────────────────────────────────( parents +2 )─────────────────────────────────"
#time test_with_parent_and_data 2 100 500
#
#echo -n "─────────────────────────────────( parents +3 )─────────────────────────────────"
#time test_with_parent_and_data 3 100 500
#
#echo -n "─────────────────────────────────( parents +4 )─────────────────────────────────"
#time test_with_parent_and_data 4 100 500
