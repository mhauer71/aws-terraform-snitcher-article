class Rules {

    constructor(event, context) {
        this.event   = event;
        this.context = context;
    }

    notify() {
        console.log(this.context);
        // Check at AWS AppConfig if notification is enabled
        var isNotificationsOn = this.context['config']['notifications_on'];
        if ( isNotificationsOn ) {
            
            return this.ruleUserAgentIsNotTerraform();
            
        }
        return notify;
    }

    ruleUserAgentIsNotTerraform() {
        // According to the rule(s), if TRUE and notify is enabled, we let the notification happens
        let userAgent = this.context["cloudtrail"]["userAgent"];
        console.log("USER AGENT --->");
        console.log(userAgent);
        if ( userAgent.toUpperCase().indexOf('TERRAFORM') != -1 ) {
            return false;
        }
        return true;
    }
 }
 
 module.exports = Rules;