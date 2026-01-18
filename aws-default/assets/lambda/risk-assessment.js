const { BedrockRuntimeClient, InvokeModelCommand } = require("@aws-sdk/client-bedrock-runtime");

exports.handler = async (event, context) => {
    console.log('Risk Assessment Lambda triggered', JSON.stringify(event, null, 2));
    
    try {
        const client = new BedrockRuntimeClient({
            region: process.env.AWS_REGION || 'eu-central-1'
        });
        
        // Extract parameters from event
        const riskData = event.risk_data || event.body?.risk_data;
        const riskCategory = event.risk_category || event.body?.risk_category || 'operational';
        
        if (!riskData) {
            return {
                statusCode: 400,
                body: JSON.stringify({
                    error: 'risk_data parameter is required'
                })
            };
        }
        
        // Prepare prompt for Bedrock
        const prompt = `You are a risk assessment AI assistant. Analyze the following ${riskCategory} risk data:

Risk data: ${riskData}

Please provide:
1. A comprehensive risk assessment
2. Risk level (Low, Medium, High, Critical)
3. Specific risk factors identified
4. Mitigation recommendations
5. Impact analysis

Respond in JSON format with the fields: risk_assessment, risk_level, risk_factors, mitigation_recommendations, impact_analysis`;

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
                risk_assessment: responseBody.content[0].text,
                risk_level: "Medium",
                risk_factors: ["Analysis completed"],
                mitigation_recommendations: ["Review risk assessment results"],
                impact_analysis: "Impact analysis requires manual review"
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
        console.error('Error in risk assessment:', error);
        
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
