#### wip

#### cypan 
**CLI tool to build debian packages of perl modules distribution. Has no non-core dependencies, using Metacpan API to create `control` file and to resove dependencies**



**Install**

To setupt env & download dependencies

using [Carton](https://metacpan.org/pod/Carton)

```
carton install
```

using 'cpanm' (to get it install App::cpanminus module or `curl -L cpanmin.us > cpanm && chmod +x cpanm` )

```
cpanm -Llocal -nq --installdeps .
```

using 'curl'
```
. set.env
load
```

**Usage**

use search tool `::` to find exact name of distribution

```
:: json

JSON :: JSONP :: JSONY :: JSON-T :: App-JSON-to :: App-SerializeUtils :: JSON-PP :: JSON-XS :: App-SerializeUtils :: JS-JSON :: JSON-ON :: JSON :: JSON-PP :: JSON-SL :: JSON-XS :: App-SerializeUtils :: App-PipeFilter :: App-PipeFilter :: Eve :: Geo-JSON
```

pick one and use ```cypan``` to make debian control file

```
cypan JSON-XS
 
JSON CONTROL
{"Name":"WWW-Pusher-0.0701","Depends":["Test::More","URI","Digest::SHA","Digest::MD5","JSON","Test::Deep","LWP","ExtUtils::MakeMaker"],"Description":"Interface to the Pusher WebSockets API","Version":"0.0701","Package":"libwww-pusher-0.0701-p5","Author":"RIZEN"}

DPKG CONTROL
Author: RIZEN
Package: libwww-pusher-0.0701-p5
Depends: Test::More URI Digest::SHA Digest::MD5 JSON Test::Deep LWP ExtUtils::MakeMaker
Version: 0.0701
Description: Interface to the Pusher WebSockets API
Name: WWW-Pusher-0.0701
```
