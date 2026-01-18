const { BedrockRuntimeClient, InvokeModelCommand } = require("@aws-sdk/client-bedrock-runtime");

exports.handler = async (event, context) => {
    console.log('Compliance Monitoring Lambda triggered', JSON.stringify(event, null, 2));
    
    try {
        const client = new BedrockRuntimeClient({
            region: process.env.AWS_REGION || 'eu-central-1'
        });
        
        // Extract parameters from event
        const complianceData = event.compliance_data || event.body?.compliance_data;
        const regulationType = event.regulation_type || event.body?.regulation_type || 'general';
        
        if (!complianceData) {
            return {
                statusCode: 400,
                body: JSON.stringify({
                    error: 'compliance_data parameter is required'
                })
            };
        }
        
        // Prepare prompt for Bedrock
        const prompt = `You are a compliance monitoring AI assistant. Analyze the following data for ${regulationType} regulatory compliance:

Data to analyze: ${complianceData}

Please provide:
1. A detailed compliance assessment
2. Overall compliance status (Compliant, Non-Compliant, or Partially Compliant)
3. List any non-compliance issues found

Respond in JSON format with the fields: compliance_assessment, compliance_status, non_compliance_issues`;

        const modelId = process.env.BEDROCK_MODEL_ID || 'eu.anthropic.claude-3-7-sonnet-20250219-v1:0';
        
        const command = new InvokeModelCommand({
            modelId: modelId,
            body: JSON.stringify({
                messages: [
                    {
                        role: "user",
                        content: prompt
                    }
                ],
                max_tokens: 4000,
                temperature: 0.1
            }),
            contentType: "application/json",
            accept: "application/json"
        });

        const response = await client.send(command);
        const responseBody = JSON.parse(new TextDecoder().decode(response.body));
        
        // Parse the AI response
        let aiResponse;
        try {
            aiResponse = JSON.parse(responseBody.content[0].text);
        } catch (parseError) {
            // If AI didn't return valid JSON, create structured response
            aiResponse = {
                compliance_assessment: responseBody.content[0].text,
                compliance_status: "Partially Compliant",
                non_compliance_issues: ["Analysis completed but requires manual review"]
            };
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify(aiResponse),
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        };
        
    } catch (error) {
        console.error('Error in compliance monitoring:', error);
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            }),
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        };
    }
};
