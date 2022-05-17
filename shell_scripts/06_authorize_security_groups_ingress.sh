#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

ipv4_web_security_group_rule_id=$( \
  aws ec2 authorize-security-group-ingress \
  --group-id ${WEB_SECURITY_GROUP_ID} \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --query SecurityGroupRules[0].SecurityGroupRuleId \
  --output text \
) && echo "IPv4 Web Security Group ID: ${ipv4_web_security_group_rule_id}" \
&& sed -i "/# Security Group Rule/a IPV4_WEB_SECURITY_GROUP_RULE_ID=${ipv4_web_security_group_rule_id}" .env


ipv6_web_security_group_rule_id=$( \
  aws ec2 authorize-security-group-ingress \
  --group-id ${WEB_SECURITY_GROUP_ID} \
  --ip-permissions FromPort=80,ToPort=80,IpProtocol=tcp,Ipv6Ranges='[{CidrIpv6=::/0}]' \
  --query SecurityGroupRules[0].SecurityGroupRuleId \
  --output text \
) && echo "IPv6 Web Security Group ID: ${ipv6_web_security_group_rule_id}" \
&& sed -i "/# Security Group Rule/a IPV6_WEB_SECURITY_GROUP_RULE_ID=${ipv6_web_security_group_rule_id}" .env
