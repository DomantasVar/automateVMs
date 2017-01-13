#!/bin/bash

#NOTICE - master machine allways has to be created first when initializing new infrastructure!

echo "#!/bin/bash" > $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/registerVMs.sh
echo "#!/bin/bash" > $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/startVMs.sh
echo "#!/bin/bash" > $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/stopVMs.sh

source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/global_variables.cfg

	chmod +x $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/startVMs.sh && chown $USERNAME:$USERNAME $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/startVMs.sh 
	chmod +x $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/stopVMs.sh && chown $USERNAME:$USERNAME $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/stopVMs.sh 
	chmod +x $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/registerVMs.sh && chown $USERNAME:$USERNAME $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/registerVMs.sh



$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/MASTER.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/DB3.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/DB2.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/LOADBALANCER.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/WEB1.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/WEB2.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/DB1.cfg
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/automateVM.sh $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/configuration_files/CLIENT.cfg

