use IO, HDFS;

/************* C U R L ****************/
extern type qio_file_functions_t;
extern type curl_handle;
extern const glob_struct:qio_file_functions_t;
extern const ptr_glob_struct:qio_file_functions_ptr_t;
extern proc chpl_curl_set_opt(fl:qio_file_ptr_t, opt:c_int, arg...):syserr;
extern proc chpl_curl_perform(fl:qio_file_ptr_t):syserr;
extern proc chpl_curl_stream_file(fl_curl:qio_file_ptr_t, fl_local:qio_file_ptr_t):syserr;
extern proc chpl_curl_stream_string(fl_curl:qio_file_ptr_t, ref str:c_string):syserr;
// End Curl


// deprecated, this will be fixed in the fs-detection commit
enum ffst {
  h = 1,
  l = 2,
  curl = 3,
  none = 0,
}

// string = hdfs://<host>:<port>/<path>
proc open(path:string, mode:iomode, fs:ffst, hints:iohints=IOHINT_NONE, style:iostyle = defaultIOStyle()):file {
  if fs == ffst.curl {
    var err:syserr = ENOERR;
    var local_style = style;
    var ret:file;
    ret.home = here;
    err = qio_file_open_access_usr(ret._file_internal, path, _modestring(mode), hints, local_style, c_nil, ptr_glob_struct);
    if err then ioerror(err, "Unable to connect to Curl", path);
    return ret;
  } else return open(path, mode, hints, style);
}

proc file.setopt(opt:c_int, arg):bool {
  var err:syserr = ENOERR;

  on this.home {
    err = chpl_curl_set_opt(this._file_internal, opt, arg);
  }

  if err then ioerror(err, "in file.setopt(opt:c_int, arg)");
  return true;
}

proc file.perform():bool {
  var err:syserr = ENOERR;
  on this.home {
    err = chpl_curl_perform(this._file_internal);
  }
  if err then ioerror(err, "in file.peform()");
  return true;
}

// this = curl file
proc file.get(fl_local:file) {
  var err:syserr = ENOERR;
  on this.home {
    err = chpl_curl_stream_file(this._file_internal, fl_local._file_internal);
  }
  if err then ioerror(err, "in file.peform()");
}

// this = curl file
proc file.get(ref str:string) {
  var err:syserr = ENOERR;
  on this.home {
    var tmpstr:c_string;
    err = chpl_curl_stream_string(this._file_internal, tmpstr);
    str = toString(tmpstr);
  }
  if err then ioerror(err, "in file.peform()");
}

// These correspond to the CURLOPT_<name> for libcurl
enum chapcurl {
  FILE = 0x2711,
  URL = 0x2712,
  PORT = 0x3,
  PROXY = 0x2714,
  USERPWD = 0x2715,
  PROXYUSERPWD = 0x2716,
  RANGE = 0x2717,
  INFILE = 0x2719,
  ERRORBUFFER = 0x271a,
  WRITEFUNCTION = 0x4e2b,
  READFUNCTION = 0x4e2c,
  TIMEOUT = 0xd,
  INFILESIZE = 0xe,
  POSTFIELDS = 0x271f,
  REFERER = 0x2720,
  FTPPORT = 0x2721,
  USERAGENT = 0x2722,
  LOW_SPEED_LIMIT = 0x13,
  LOW_SPEED_TIME = 0x14,
  RESUME_FROM = 0x15,
  COOKIE = 0x2726,
  HTTPHEADER = 0x2727,
  HTTPPOST = 0x2728,
  SSLCERT = 0x2729,
  KEYPASSWD = 0x272a,
  CRLF = 0x1b,
  QUOTE = 0x272c,
  WRITEHEADER = 0x272d,
  COOKIEFILE = 0x272f,
  SSLVERSION = 0x20,
  TIMECONDITION = 0x21,
  TIMEVALUE = 0x22,
  CUSTOMREQUEST = 0x2734,
  STDERR = 0x2735,
  POSTQUOTE = 0x2737,
  WRITEINFO = 0x2738,
  VERBOSE = 0x29,
  HEADER = 0x2a,
  NOPROGRESS = 0x2b,
  NOBODY = 0x2c,
  FAILONERROR = 0x2d,
  UPLOAD = 0x2e,
  POST = 0x2f,
  DIRLISTONLY = 0x30,
  APPEND = 0x32,
  NETRC = 0x33,
  FOLLOWLOCATION = 0x34,
  TRANSFERTEXT = 0x35,
  PUT = 0x36,
  PROGRESSFUNCTION = 0x4e58,
  PROGRESSDATA = 0x2749,
  AUTOREFERER = 0x3a,
  PROXYPORT = 0x3b,
  POSTFIELDSIZE = 0x3c,
  HTTPPROXYTUNNEL = 0x3d,
  INTERFACE = 0x274e,
  KRBLEVEL = 0x274f,
  SSL_VERIFYPEER = 0x40,
  CAINFO = 0x2751,
  MAXREDIRS = 0x44,
  FILETIME = 0x45,
  TELNETOPTIONS = 0x2756,
  MAXCONNECTS = 0x47,
  CLOSEPOLICY = 0x48,
  FRESH_CONNECT = 0x4a,
  FORBID_REUSE = 0x4b,
  RANDOM_FILE = 0x275c,
  EGDSOCKET = 0x275d,
  CONNECTTIMEOUT = 0x4e,
  HEADERFUNCTION = 0x4e6f,
  HTTPGET = 0x50,
  SSL_VERIFYHOST = 0x51,
  COOKIEJAR = 0x2762,
  SSL_CIPHER_LIST = 0x2763,
  HTTP_VERSION = 0x54,
  FTP_USE_EPSV = 0x55,
  SSLCERTTYPE = 0x2766,
  SSLKEY = 0x2767,
  SSLKEYTYPE = 0x2768,
  SSLENGINE = 0x2769,
  SSLENGINE_DEFAULT = 0x5a,
  DNS_USE_GLOBAL_CACHE = 0x5b,
  DNS_CACHE_TIMEOUT = 0x5c,
  PREQUOTE = 0x276d,
  DEBUGFUNCTION = 0x4e7e,
  DEBUGDATA = 0x276f,
  COOKIESESSION = 0x60,
  CAPATH = 0x2771,
  BUFFERSIZE = 0x62,
  NOSIGNAL = 0x63,
  SHARE = 0x2774,
  PROXYTYPE = 0x65,
  ENCODING = 0x2776,
  PRIVATE = 0x2777,
  HTTP200ALIASES = 0x2778,
  UNRESTRICTED_AUTH = 0x69,
  FTP_USE_EPRT = 0x6a,
  HTTPAUTH = 0x6b,
  SSL_CTX_FUNCTION = 0x4e8c,
  SSL_CTX_DATA = 0x277d,
  FTP_CREATE_MISSING_DIRS = 0x6e,
  PROXYAUTH = 0x6f,
  FTP_RESPONSE_TIMEOUT = 0x70,
  IPRESOLVE = 0x71,
  MAXFILESIZE = 0x72,
  INFILESIZE_LARGE = 0x75a3,
  RESUME_FROM_LARGE = 0x75a4,
  MAXFILESIZE_LARGE = 0x75a5,
  NETRC_FILE = 0x2786,
  USE_SSL = 0x77,
  POSTFIELDSIZE_LARGE = 0x75a8,
  TCP_NODELAY = 0x79,
  FTPSSLAUTH = 0x81,
  IOCTLFUNCTION = 0x4ea2,
  IOCTLDATA = 0x2793,
  FTP_ACCOUNT = 0x2796,
  COOKIELIST = 0x2797,
  IGNORE_CONTENT_LENGTH = 0x88,
  FTP_SKIP_PASV_IP = 0x89,
  FTP_FILEMETHOD = 0x8a,
  LOCALPORT = 0x8b,
  LOCALPORTRANGE = 0x8c,
  CONNECT_ONLY = 0x8d,
  CONV_FROM_NETWORK_FUNCTION = 0x4eae,
  CONV_TO_NETWORK_FUNCTION = 0x4eaf,
  CONV_FROM_UTF8_FUNCTION = 0x4eb0,
  MAX_SEND_SPEED_LARGE = 0x75c1,
  MAX_RECV_SPEED_LARGE = 0x75c2,
  FTP_ALTERNATIVE_TO_USER = 0x27a3,
  SOCKOPTFUNCTION = 0x4eb4,
  SOCKOPTDATA = 0x27a5,
  SSL_SESSIONID_CACHE = 0x96,
  SSH_AUTH_TYPES = 0x97,
  SSH_PUBLIC_KEYFILE = 0x27a8,
  SSH_PRIVATE_KEYFILE = 0x27a9,
  FTP_SSL_CCC = 0x9a,
  TIMEOUT_MS = 0x9b,
  CONNECTTIMEOUT_MS = 0x9c,
  HTTP_TRANSFER_DECODING = 0x9d,
  HTTP_CONTENT_DECODING = 0x9e,
  NEW_FILE_PERMS = 0x9f,
  NEW_DIRECTORY_PERMS = 0xa0,
  POSTREDIR = 0xa1,
  SSH_HOST_PUBLIC_KEY_MD5 = 0x27b2,
  OPENSOCKETFUNCTION = 0x4ec3,
  OPENSOCKETDATA = 0x27b4,
  COPYPOSTFIELDS = 0x27b5,
  PROXY_TRANSFER_MODE = 0xa6,
  SEEKFUNCTION = 0x4ec7,
  SEEKDATA = 0x27b8,
  CRLFILE = 0x27b9,
  ISSUERCERT = 0x27ba,
  ADDRESS_SCOPE = 0xab,
  CERTINFO = 0xac,
  USERNAME = 0x27bd,
  PASSWORD = 0x27be,
  PROXYUSERNAME = 0x27bf,
  PROXYPASSWORD = 0x27c0,
  NOPROXY = 0x27c1,
  TFTP_BLKSIZE = 0xb2,
  SOCKS5_GSSAPI_SERVICE = 0x27c3,
  SOCKS5_GSSAPI_NEC = 0xb4,
  PROTOCOLS = 0xb5,
  REDIR_PROTOCOLS = 0xb6,
  LASTENTRY = 0x27ea,
}
