import json
import boto3
import os
from typing import Dict, Any

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function for AI-powered document analysis in audit workflows.
    Uses AWS Bedrock Claude 3 Sonnet for intelligent document processing.
    """
    
    # Initialize AWS clients
    bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'eu-west-1'))
    s3_client = boto3.client('s3')
    
    try:
        # Extract document information from event
        bucket = event.get('bucket') or os.environ.get('S3_BUCKET')
        document_key = event.get('document_key')
        
        if not bucket or not document_key:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required parameters: bucket and document_key'
                })
            }
        
        # Get document from S3
        response = s3_client.get_object(Bucket=bucket, Key=document_key)
        document_content = response['Body'].read()
        
        # Prepare prompt for Bedrock Claude 3 Sonnet
        model_id = os.environ.get('BEDROCK_MODEL_ID', 'eu.anthropic.claude-3-7-sonnet-20250219-v1:0')
        
        prompt = f"""
        Please analyze the following document for audit purposes:
        
        Document: {document_key}
        
        Provide analysis covering:
        1. Document type and structure
        2. Key financial data and metrics
        3. Compliance indicators
        4. Risk factors identified
        5. Recommendations for audit procedures
        
        Document content: {document_content.decode('utf-8', errors='ignore')[:4000]}
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
        analysis = response_body['content'][0]['text']
        
        # Save analysis results to S3
        analysis_key = f"analysis/{document_key.replace('.', '_')}_analysis.json"
        analysis_result = {
            'document_key': document_key,
            'analysis': analysis,
            'timestamp': context.aws_request_id,
            'model_used': model_id
        }
        
        s3_client.put_object(
            Bucket=bucket,
            Key=analysis_key,
            Body=json.dumps(analysis_result, indent=2),
            ContentType='application/json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Document analysis completed successfully',
                'analysis_key': analysis_key,
                'analysis': analysis
            })
        }
        
    except Exception as e:
        print(f"Error processing document: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'Document analysis failed: {str(e)}'
            })
        }
