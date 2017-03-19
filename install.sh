#!/bin/bash - 
#===============================================================================
#
#          FILE: install.sh
# 
#         USAGE: ./install.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/19/2017 08:20
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ -e ./installPkg.sh ]; then
  ./installPkg.sh -i
fi

