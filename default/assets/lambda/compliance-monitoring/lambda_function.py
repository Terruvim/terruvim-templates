import json
import boto3
import os
from typing import Dict, Any, List

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function for AI-powered compliance monitoring and regulatory checks.
    Uses AWS Bedrock Claude 3 Sonnet for intelligent compliance analysis.
    """
    
    # Initialize AWS clients
    bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'eu-west-1'))
    s3_client = boto3.client('s3')
    
    try:
        # Extract compliance monitoring parameters from event
        bucket = event.get('bucket') or os.environ.get('S3_BUCKET')
        compliance_framework = event.get('compliance_framework', 'GDPR')
        monitoring_scope = event.get('monitoring_scope', 'full')
        data_sources = event.get('data_sources', [])
        
        if not bucket:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required parameter: bucket'
                })
            }
        
        # Define compliance frameworks and their requirements
        frameworks = {
            'GDPR': [
                'Data protection by design and by default',
                'Consent management',
                'Data subject rights',
                'Data breach notification',
                'Privacy impact assessments'
            ],
            'SOX': [
                'Internal controls over financial reporting',
                'Management assessment of controls',
                'Auditor attestation',
                'Disclosure controls and procedures'
            ],
            'ISO27001': [
                'Information security management system',
                'Risk assessment and treatment',
                'Security controls implementation',
                'Continuous monitoring and improvement'
            ]
        }
        
        # Gather compliance data from specified sources
        compliance_data = {}
        for source in data_sources:
            try:
                response = s3_client.get_object(Bucket=bucket, Key=source)
                compliance_data[source] = response['Body'].read().decode('utf-8', errors='ignore')[:2000]
            except Exception as e:
                compliance_data[source] = f"Error reading source: {str(e)}"
        
        # Prepare prompt for Bedrock Claude 3 Sonnet
        model_id = os.environ.get('BEDROCK_MODEL_ID', 'eu.anthropic.claude-3-7-sonnet-20250219-v1:0')
        
        framework_requirements = frameworks.get(compliance_framework, ['General compliance requirements'])
        
        prompt = f"""
        Please conduct a comprehensive compliance monitoring analysis based on the following:
        
        Compliance Framework: {compliance_framework}
        Monitoring Scope: {monitoring_scope}
        Framework Requirements: {framework_requirements}
        
        Analyze the compliance data and provide:
        1. Compliance status assessment for each requirement
        2. Gap analysis and non-compliance areas
        3. Risk assessment for compliance violations
        4. Recommendations for remediation actions
        5. Continuous monitoring suggestions
        6. Evidence documentation requirements
        
        Compliance data for analysis:
        {json.dumps(compliance_data, indent=2)[:3000]}
        """
        
        # Call Bedrock
        bedrock_response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
        )
        
        # Parse response
        response_body = json.loads(bedrock_response['body'].read())
        compliance_analysis = response_body['content'][0]['text']
        
        # Save compliance monitoring results to S3
        monitoring_key = f"compliance-monitoring/{compliance_framework}_{monitoring_scope}_{context.aws_request_id}_report.json"
        monitoring_result = {
            'compliance_framework': compliance_framework,
            'monitoring_scope': monitoring_scope,
            'framework_requirements': framework_requirements,
            'data_sources': list(compliance_data.keys()),
            'compliance_analysis': compliance_analysis,
            'timestamp': context.aws_request_id,
            'model_used': model_id
        }
        
        s3_client.put_object(
            Bucket=bucket,
            Key=monitoring_key,
            Body=json.dumps(monitoring_result, indent=2),
            ContentType='application/json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Compliance monitoring completed successfully',
                'monitoring_key': monitoring_key,
                'compliance_analysis': compliance_analysis
            })
        }
        
    except Exception as e:
        print(f"Error conducting compliance monitoring: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'Compliance monitoring failed: {str(e)}'
            })
        }
