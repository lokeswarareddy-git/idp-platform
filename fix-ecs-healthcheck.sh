#!/bin/bash
set -e

aws ecs describe-task-definition \
  --task-definition idp-platform \
  --region us-east-2 \
  --output json > /tmp/td_raw.json

python3 << 'EOF'
import json
td = json.load(open('/tmp/td_raw.json'))['taskDefinition']
for key in ['taskDefinitionArn','revision','status','requiresAttributes','compatibilities','registeredAt','registeredBy']:
    td.pop(key, None)
td['containerDefinitions'][0].pop('healthCheck', None)
json.dump(td, open('/tmp/td_clean.json', 'w'))
print('healthCheck removed')
EOF

aws ecs register-task-definition \
  --region us-east-2 \
  --cli-input-json file:///tmp/td_clean.json \
  --query 'taskDefinition.taskDefinitionArn' --output text

aws ecs update-service \
  --cluster idp-platform-dev \
  --service idp-platform \
  --task-definition idp-platform \
  --force-new-deployment \
  --region us-east-2 \
  --query 'service.deployments[0].status' --output text

echo "Done — deployment started"
