const { BedrockRuntimeClient, InvokeModelCommand } = require("@aws-sdk/client-bedrock-runtime");

exports.handler = async (event, context) => {
    console.log('Document Analysis Lambda triggered', JSON.stringify(event, null, 2));
    
    try {
        const client = new BedrockRuntimeClient({
            region: process.env.AWS_REGION || 'eu-central-1'
        });
        
        // Extract parameters from event
        const document = event.document || event.body?.document;
        const analysisType = event.analysis_type || event.body?.analysis_type || 'general';
        
        if (!document) {
            return {
                statusCode: 400,
                body: JSON.stringify({
                    error: 'document parameter is required'
                })
            };
        }
        
        // Prepare prompt for Bedrock
        const prompt = `You are a document analysis AI assistant. Perform ${analysisType} analysis on the following document:

Document content: ${document}

Please provide:
1. A detailed analysis summary
2. Key findings and insights
3. Recommended actions if any
4. Document classification and importance level

Respond in JSON format with the fields: analysis_summary, key_findings, recommended_actions, document_classification`;

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
                analysis_summary: responseBody.content[0].text,
                key_findings: ["Document analysis completed"],
                recommended_actions: ["Review analysis results"],
                document_classification: "Standard"
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
        console.error('Error in document analysis:', error);
        
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
