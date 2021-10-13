function prepareDate(strDate) {
   try {
     var dtWhen = new Date(strDate);
     var month = "00" + (dtWhen.getMonth()+1)
     var dt    = dtWhen.getDate() + "/" + month.substr(month.length-2) + "/" + dtWhen.getFullYear();
     var hour  = "00" + dtWhen.getHours()
     var min   = "00" + dtWhen.getMinutes()
     return String(dt + " " + hour.substr(hour.length-2) + ":" + min.substr(min.length-2))
   } catch (error) {
     // not big deal
     console.log(error)
     return strDate;
   }
}

function urlAwsConfigTimeline(event) {
  let current_region        = event['detail']['configurationItem']['awsRegion'];
  let resource_id           = encodeURIComponent(event['detail']['configurationItem']['resourceId']);
  let resource_name         = encodeURIComponent(event['detail']['configurationItem']['resourceName']);
  let resource_type         = encodeURIComponent(event['detail']['configurationItem']['resourceType']);
  return `https://${current_region}.console.aws.amazon.com/config/home?region=${current_region}#/resources/timeline?resourceId=${resource_id}&resourceName=${resource_name}&resourceType=${resource_type}`
}

function extractTags(event) {
   var tags = []
   if ('detail' in event) {
     if ('configurationItem' in event['detail']) {
       if ('tags' in event['detail']['configurationItem']) {
         if (event['detail']['configurationItem']['tags']) {
             for (var key in event['detail']['configurationItem']['tags']) {
                 var value = event['detail']['configurationItem']['tags'][key]
                 tags.push(key + "=" + value)
             }
         }
       }
     }
   }
   return tags
}

module.exports.prepareDate = prepareDate;
module.exports.extractTags = extractTags;
module.exports.urlAwsConfigTimeline = urlAwsConfigTimeline;
