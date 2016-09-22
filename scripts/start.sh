#!/bin/bash

#Run run.sh
#
#/run.sh

################
# Start Platform Service
#
echo "Starting Platform Services"
/apps/opt/weblogic/endeca/PlatformServices/11.1.0/tools/server/bin/startup.sh &
echo "Done PS"

################
# Start Tools and Framework
#
echo "Starting Tools and Framework"
/apps/opt/weblogic/endeca/ToolsAndFrameworks/11.1.0/server/bin/startup.sh &
echo "Done T&F"

###############
# Deploy Search Application
#
# Create Response file for the wizard
echo '' > /search.rsp
echo 'Y' >> /search.rsp
echo 'Search' >> /search.rsp
echo '/apps/opt/weblogic/endeca/apps' >> /search.rsp
echo '8888' >> /search.rsp
echo '8006' >> /search.rsp
echo '17000' >> /search.rsp
echo '17002' >> /search.rsp
echo '17010' >> /search.rsp
echo '' >> /search.rsp
echo '/apps/opt/weblogic/endeca/ToolsAndFrameworks/11.1.0/deployment_template/lib/../../server/workspace/credential_store/jps-config.xml' >> /search.rsp
echo '/apps/opt/weblogic/endeca/ToolsAndFrameworks/11.1.0/deployment_template/lib/../../server/workspace/state/repository' >> /search.rsp
echo '' >> /search.rsp

# Run the Wizard
/apps/opt/weblogic/endeca/ToolsAndFrameworks/11.1.0/deployment_template/bin/deploy.sh --app /apps/opt/weblogic/endeca/ToolsAndFrameworks/11.1.0/reference/discover-data/deploy.xml < /search.rsp
