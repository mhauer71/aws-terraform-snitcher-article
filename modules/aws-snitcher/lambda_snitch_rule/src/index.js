const aws   = require('aws-sdk');
const utils = require('./utils.js');
const Rules = require('./rules.js');
const http  = require('http');

async function readAppConfig() {
    let urlPath = `http://localhost:${process.env.AWS_APPCONFIG_EXTENSION_HTTP_PORT}/applications/${process.env.AWS_APPCONFIG_APPLICATION_NAME}/environments/${process.env.AWS_APPCONFIG_ENVIRONMENT}/configurations/${process.env.AWS_APPCONFIG_CONFIGURATION_PROFILE}`;
    
    const res = await new Promise((resolve, reject) => {
        http.get(urlPath, resolve);
    });
    
    let configData = await new Promise((resolve, reject) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('error', err => reject(err));
        res.on('end', () => resolve(data));
    });
    
    const parsedConfigData = JSON.parse(configData);
    return parsedConfigData;
}

function log(context, message) {
  // We are using AWS AppConfig Lambda Extesion (installed with the this Lambda Function)
  // This extension includes best practices that simplify using AWS AppConfig while reducing costs
  // see more here: https://docs.aws.amazon.com/appconfig/latest/userguide/appconfig-integration-lambda-extensions.html
  //   | - The extension maintains a local cache of the configuration data. 
  //   | - If the data isn't in the cache, the extension calls AWS AppConfig to get the configuration data.
  //   | - Upon receiving the configuration from the service, the extension stores it in the local cache and passes it to the Lambda function.
  //   | - AWS AppConfig Lambda extension periodically checks for updates to your configuration data in the background. Each time your Lambda function is invoked, 
  //   |       the extension checks the elapsed time since it retrieved a configuration. If the elapsed time is greater than the configured poll interval,
  //   |       the extension calls AWS AppConfig to check for newly deployed data, updates the local cache if there has been a change, and resets the elapsed time.
  if ( context && context['config']['debug_log_messages'] ) {
    console.log(message);
  }
}

async function lookupEventCloudtrail(event, context) {
    const eventDetail  = event['detail'];
    
    // Lookup event on Cloudtrail of this specific resource in the last N minutes range
    let   minutesRange = 5;
    let   startDate    = new Date(eventDetail['notificationCreationTime']);
          startDate    = new Date(startDate.getTime() - (minutesRange*60000));
    let   endDate      = new Date(eventDetail['notificationCreationTime']);
          endDate      = new Date(endDate.getTime() + ((minutesRange)*60000));
    
    let resourceId   = "";
    let resourceName = "";
    if  ('resourceId' in eventDetail['configurationItem'] ) {
        resourceId = eventDetail['configurationItem']['resourceId'];
        log(context, "Looking for: [ResourceId=" + resourceId + "]  [ResourceType=" + eventDetail['configurationItem']['resourceType'] + "]");
    } else if ('resourceName' in eventDetail['configurationItem'] ) {
        resourceName = eventDetail['configurationItem']['resourceName'];
        log(context, "Looking for: [ResourceName=" + resourceName + "]  [ResourceType=" + eventDetail['configurationItem']['resourceType'] + "]");
    } else {
        log(context, "Looking for: [ResourceType=" + eventDetail['configurationItem']['resourceType'] + " (Without ResourceName)]");
    }
    log(context, "between: " + startDate +  " and " + endDate);
    
    try {
        let lookupAttributes;
        if ( resourceId != "" ) {
            lookupAttributes = [
                {AttributeKey:"ResourceName",AttributeValue:resourceId},
                {AttributeKey:"ResourceType",AttributeValue:eventDetail['configurationItem']['resourceType']}
            ];
        } else if ( resourceName != "" ) {
            lookupAttributes = [
                {AttributeKey:"ResourceName",AttributeValue:resourceName},
                {AttributeKey:"ResourceType",AttributeValue:eventDetail['configurationItem']['resourceType']}
            ];
        } else {
            lookupAttributes = [
                {AttributeKey:"ResourceType",AttributeValue:eventDetail['configurationItem']['resourceType']}
            ];
        }
        // Lookup the last 3 events regarding this resource
        let cloudtrail = new aws.CloudTrail();
        let params = {
          LookupAttributes: lookupAttributes,
          EndTime: endDate,
          StartTime: startDate,
          MaxResults: '3',
        };
        
        let data = await cloudtrail.lookupEvents(params).promise();
        log(context, "Cloudtrail response:");
        log(context, data);
        if ( 'Events' in data && data['Events'].length > 0 ) {
            let eventCloudTrail = data['Events'][0];
            return eventCloudTrail;
        } else {
            console.warn(`No event found in Cloudtrail for:${lookupAttributes}`);
        }
        return null;

    } catch (error) {
        console.log("ERROR on lookupEvent Cloudtrail");
        console.log(error.stack);
    }
    
}

exports.handler = async function(event) {
    let context   = {};
    let appConfig = await readAppConfig();
    context["config"] = appConfig;
    log(context, appConfig);
    
    log(context, '--- AWS Config Terraform Snitch <START> ---');
    log(context, event);
    
    var cloudtrailEvent      = await lookupEventCloudtrail(event, context);
    var urlAwsConfigTimeline = utils.urlAwsConfigTimeline(event);
    var fullCloudTrailEvent  = "CloudTrailEvent" in cloudtrailEvent ? JSON.parse(cloudtrailEvent["CloudTrailEvent"]) : null;
    log(context, cloudtrailEvent);
    log(context, fullCloudTrailEvent);
    log(context, urlAwsConfigTimeline);
    if ( fullCloudTrailEvent ) {
        context["cloudtrail"] = fullCloudTrailEvent;
    }
    
    var responsePromise = new Promise(function(resolve, reject) {resolve(200)});

    var rules = new Rules(event, context);
    let notify = rules.notify();
    if ( notify ) {
        log(context, "Notify is ON...");
        let region                   = "NOT DEFINED";
        let account                  = "NOT DEFINED";
        let eventDate                = "NOT DEFINED";
        let resource                 = "NOT DEFINED";
        let changeType               = "NOT DEFINED";
        let notificationCreationTime = "NOT DEFINED";
        let configurationItemStatus  = "NOT DEFINED";
        let listTags                 = "";
        
        if ( 'detail' in event ) {
            region    = event['detail']['configurationItem']['awsRegion'];
            account   = event['detail']['configurationItem']['awsAccountId'];
            eventDate = utils.prepareDate(event['detail']['configurationItem']['configurationItemCaptureTime']);
            resource  = event['detail']['configurationItem']['ARN'];

            if ('configurationItemDiff' in event['detail']) {
                if ('changeType' in event['detail']['configurationItemDiff']) {
                  changeType = event['detail']['configurationItemDiff']['changeType'];
                }
            }

            if ('notificationCreationTime' in event['detail']) {
                notificationCreationTime = utils.prepareDate(event['detail']['notificationCreationTime']);
            }
            
            if ('configurationItem' in event['detail']) {
                if ('configurationItemStatus' in event['detail']['configurationItem']) {
                    configurationItemStatus = event['detail']['configurationItem']['configurationItemStatus'];
                }
            }
            
            for( const val of utils.extractTags(event) ) {
                listTags += `         - ${val}\n`;
            }
        }

        let labelSep  = ":\n         - ";
        let labelSep2 = ": ";
        let message   = "";
        message      += "";
        message      += "==============================================================================\n";
        message      += "AWS Terraform Snitch Notification\n";
        message      += "==============================================================================\n";
        message      += `Region${labelSep2}${region}\n`;
        message      += `Account${labelSep2}${account}\n`;
        message      += "------------------------------------------------------------------------------\n";
        message      += `Date Event${labelSep}${eventDate}\n`;
        message      += `Resources${labelSep}${resource}\n`;
        message      += `Change Type${labelSep}${changeType}` + "\n";
        message      += `Notification Creation Time${labelSep}${notificationCreationTime}\n`;
        message      += `Configuration Item Status${labelSep}${configurationItemStatus}\n`;
        message      += `Tags: \n${listTags}`;
        message      += `AWS Config Timeline${labelSep}${urlAwsConfigTimeline}\n`;
        message      += "------------------------------------------------------------------------------\n";
        
        if ( cloudtrailEvent ) {
            
            
            message    += " >>>>> CloudTrail - Event\n";
            message    += `Event Id${labelSep}${cloudtrailEvent['EventId']}` + "\n";
            message    += `Event Name${labelSep}${cloudtrailEvent['EventName']}` + "\n";
            message    += `Source${labelSep}${cloudtrailEvent['EventSource']}` + "\n\n";
            
            message    += " >>>>> CloudTrail - User\n";
            message    += `Source IP Address${labelSep}${fullCloudTrailEvent['sourceIPAddress']}` + "\n";
            message    += `Type${labelSep}${fullCloudTrailEvent['userIdentity']['type']}` + "\n";
            message    += `User name${labelSep}${fullCloudTrailEvent['userIdentity']['userName']}` + "\n";
            message    += `ARN${labelSep}${fullCloudTrailEvent['userIdentity']['arn']}` + "\n";
            message    += `Principal ID${labelSep}${fullCloudTrailEvent['userIdentity']['principalId']}` + "\n";
            message    += `User Agent${labelSep}${fullCloudTrailEvent['userAgent']}` + "\n";
            // message    += `Session Issuer${labelSep}${fullCloudTrailEvent['userIdentity']['sessionContext']['sessionIssuer']}` + "\n";
            // message    += `Web Id Federation Data${labelSep}${fullCloudTrailEvent['userIdentity']['sessionContext']['webIdFederationData']}` + "\n";
            // message    += `Attributes${labelSep}${fullCloudTrailEvent['userIdentity']['sessionContext']['attributes']}` + "\n";
            // cloudtrailEvent['requestID'];
            // cloudtrailEvent['eventTime'];
            // cloudtrailEvent['eventCategory'];
            // cloudtrailEvent['userIdentity']['accountId'];
        }
        message    += "==============================================================================";
        message    += "\n";

        var params = {
            Message: message,
            TopicArn: process.env.SNS_TOPIC
        };
        responsePromise = new aws.SNS().publish(params).promise();
        responsePromise.then(
            function(data) {
                log(context, '--- AWS Config Rule Notification <START RESULT PUBLISH SNS> ---');
                log(context, `Message sent to the topic ${params.TopicArn}`);
                log(context, "MessageID is " + data.MessageId);
                log(context, '--- AWS Config Rule Notification <END RESULT PUBLISH SNS> ---');
            }).catch(
              function(err) {
                console.log('--- AWS Config Rule Notification <ERROR> ---');
                console.error(err, err.stack);
              }
            );
    } else {
        log(context, "Notify is OFF...");
    }
    
    log(context, '--- AWS Config Terraform Snitch <END> ---');
    return responsePromise;
};
