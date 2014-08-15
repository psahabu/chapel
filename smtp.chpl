config const url      = "smtp://smtp.gmail.com:587";

config const from     = "<tztest3@gmail.com>";
config const to       = "<timzakian@gmail.com>";
config const cc       = "<tzakian@indiana.edu>";

config const username = "user";
config const password = "xxxx";

config const subject  = "Testing Curl in Chapel (SMTP)";
config const message  = "Hello! This is a message sent via Chapel!\r\n";


var handle = open(url=url, mode=iomode.cw);

var recipients:slist;
recipients.append(to);
recipients.append(cc);

var arr = "To: " + to + "\r\n" +
          "From: " + from + "\r\n" +
          "Cc: " + cc + "\r\n" +
          "Subject: " + subject + "\r\n" + "\r\n" + message;


handle.setopt((curlopt_username       , username),
              (curlopt_password       , password),
              (curlopt_mail_from      , from),
              (curlopt_use_ssl        , 3),
              (curlopt_ssl_verifypeer , false),
              (curlopt_ssl_verifyhost , false),
              (curlopt_mail_rcpt      , recipients.list),
              (curlopt_verbose        , true));

var writer = handle.writer();

writer.write(arr);

writer.close();
recipients.free();
handle.close();

