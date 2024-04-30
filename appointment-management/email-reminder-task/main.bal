import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;

import wso2/choreo.sendemail as ChoreoEmail;

configurable string appointmentApiUrl = ?;

type Appointment record {
    string appointmentDate;
    string email;
    int id;
    string name;
    string phoneNumber;
    string 'service;
};

public function main() returns error? {
    io:println("Appintment URL: " + appointmentApiUrl);
    http:Client appointmentsApiEndpoint = check new (appointmentApiUrl);

    // Fetching the appointments
    Appointment[] appointments = check appointmentsApiEndpoint->/appointments(upcoming = "true");

    foreach Appointment appointment in appointments {
        // Sending an email to the patient
        check sendEmail(appointment);
    }
}

function sendEmail(Appointment appointment) returns error? {

    // Format the date as "April 8, 2024, at 5:30 AM"
    string formattedAppointmentDate = check getIstTimeString(appointment.appointmentDate);

    // Capitalize the service name
    string serviceName = convertAndCapitalize(appointment.'service);

    // Appending branding details to the content
    string finalContent = string `
Dear ${appointment.name},

This is a reminder that you have an appointment scheduled for ${serviceName} at ${formattedAppointmentDate}.

Thank you for choosing CareConnect for your medical needs. We are here to assist you at every step of your health journey.

Warm regards,
The CareConnect Team

---

CareConnect - Your Partner in Health

Website: https://www.careconnect.com
Support: support@careconnect.com
Phone: +1 (800) 123-4567

Follow us on:
- Facebook: https://www.facebook.com/CareConnect
- Twitter: https://twitter.com/CareConnect

Privacy Policy | Terms of Use | Unsubscribe

This message is intended only for the addressee and may contain confidential information. If you are not the intended recipient, you are hereby notified that any use, dissemination, copying, or storage of this message or its attachments is strictly prohibited.
`;

    ChoreoEmail:Client emailClient = check new ();
    string sendEmailResponse = check emailClient->sendEmail(appointment.email, "Upcoming Appointment Reminder", finalContent);
    log:printInfo("Email sent successfully to: " + appointment.email + " with response: " + sendEmailResponse);
}

function getIstTimeString(string utcTimeString) returns string|error {
    time:Utc utcTime = check time:utcFromString(utcTimeString);

    time:TimeZone zone = check new ("Asia/Colombo");
    time:Civil istTime = zone.utcToCivil(utcTime);

    string emailFormattedString = check time:civilToEmailString(istTime, time:PREFER_TIME_ABBREV);
    return emailFormattedString;
}

function convertAndCapitalize(string input) returns string {
    string:RegExp r = re `-`;
    // Split the input string by '-'
    string[] parts = r.split(input);

    // Capitalize the first letter of each part and join them with a space
    string result = "";
    foreach var word in parts {
        string capitalizedWord = word.substring(0, 1).toUpperAscii() + word.substring(1).toLowerAscii();
        if (result.length() > 0) {
            result = result + " " + capitalizedWord;
        } else {
            result = capitalizedWord;
        }
    }

    return result;
}
