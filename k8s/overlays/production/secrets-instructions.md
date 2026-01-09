# Production Secrets Configuration
# 
# IMPORTANT: These secrets should be managed through AWS Secrets Manager
# or Kubernetes External Secrets Operator in production.
# 
# Create these secrets manually in your cluster:
# 
# kubectl create secret generic rds-endpoint \
#   --from-literal=endpoint=<your-rds-endpoint> \
#   -n tms-app
#
# kubectl create secret generic db-username \
#   --from-literal=username=<your-db-username> \
#   -n tms-app
#
# kubectl create secret generic db-password \
#   --from-literal=password=<your-db-password> \
#   -n tms-app
#
# kubectl create secret generic db-name \
#   --from-literal=name=task_management \
#   -n tms-app
#
# kubectl create secret docker-registry ecr-registry-secret \
#   --docker-server=301678011652.dkr.ecr.us-east-1.amazonaws.com \
#   --docker-username=AWS \
#   --docker-password=$(aws ecr get-login-password --region us-east-1) \
#   -n tms-app
