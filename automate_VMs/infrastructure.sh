#!/bin/bash

#NOTICE - master machine allways has to be created first when initializing new infrastructure!

$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/MASTER.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/DB3.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/DB2.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/LB.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/WEB1.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/WEB2.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/CLIENT.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/DB1.cfg
