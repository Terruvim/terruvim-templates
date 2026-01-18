import json
import boto3
import os
from typing import Dict, Any

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function for AI-powered risk assessment and compliance checks.
    Uses AWS Bedrock Claude 3 Sonnet for intelligent risk analysis.
    """
    
    # Initialize AWS clients
    bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'eu-west-1'))
    s3_client = boto3.client('s3')
    
    try:
        # Extract risk assessment parameters from event
        bucket = event.get('bucket') or os.environ.get('S3_BUCKET')
        assessment_type = event.get('assessment_type', 'general')
        data_sources = event.get('data_sources', [])
        
        if not bucket:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required parameter: bucket'
                })
            }
        
        # Gather data from specified sources
        source_data = {}
        for source in data_sources:
            try:
                response = s3_client.get_object(Bucket=bucket, Key=source)
                source_data[source] = response['Body'].read().decode('utf-8', errors='ignore')[:2000]
            except Exception as e:
                source_data[source] = f"Error reading source: {str(e)}"
        
        # Prepare prompt for Bedrock Claude 3 Sonnet
        model_id = os.environ.get('BEDROCK_MODEL_ID', 'eu.anthropic.claude-3-7-sonnet-20250219-v1:0')
        
        prompt = f"""
        Please conduct a comprehensive risk assessment based on the following information:
        
        Assessment Type: {assessment_type}
        Data Sources: {list(source_data.keys())}
        
        Analyze the following data and provide:
        1. Risk identification and categorization
        2. Risk probability and impact assessment
        3. Risk appetite and tolerance evaluation
        4. Mitigation strategies and controls
        5. Compliance gap analysis
        6. Recommendations for risk management
        
        Data for analysis:
        {json.dumps(source_data, indent=2)[:3000]}
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
        risk_assessment = response_body['content'][0]['text']
        
        # Save assessment results to S3
        assessment_key = f"risk-assessments/{assessment_type}_{context.aws_request_id}_assessment.json"
        assessment_result = {
            'assessment_type': assessment_type,
            'data_sources': list(source_data.keys()),
            'risk_assessment': risk_assessment,
            'timestamp': context.aws_request_id,
            'model_used': model_id
        }
        
        s3_client.put_object(
            Bucket=bucket,
            Key=assessment_key,
            Body=json.dumps(assessment_result, indent=2),
            ContentType='application/json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Risk assessment completed successfully',
                'assessment_key': assessment_key,
                'risk_assessment': risk_assessment
            })
        }
        
    except Exception as e:
        print(f"Error conducting risk assessment: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'Risk assessment failed: {str(e)}'
            })
        }
