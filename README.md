**Install**

- to setupt env & download dependencies
- 
```
. load
load
```

- or instal [Carton](https://metacpan.org/pod/Carton) and use cpanfile

```carton install```


**Usage**

- use search tool ```::``` to find exact name of distribution

```:: json```

```# list results```
```JSON :: JSONP :: JSONY :: JSON-T :: App-JSON-to :: App-SerializeUtils :: JSON-PP :: JSON-XS :: App-SerializeUtils :: JS-JSON :: JSON-ON :: JSON :: JSON-PP :: JSON-SL :: JSON-XS :: App-SerializeUtils :: App-PipeFilter :: App-PipeFilter :: Eve :: Geo-JSON ::
```

- pick one and use ```cypan``` to make debian control file

```cypan JSON-XS```

**creates json+debian files**
 ```
 __________________________________________________________________________
 JSON CONTROL
 --------------------------------------------------------------------------
 {"Name":"WWW-Pusher-0.0701","Depends":["Test::More","URI","Digest::SHA","Digest::MD5","JSON","Test::Deep","LWP","ExtUtils::MakeMaker"],"Description":"Interface to the Pusher WebSockets API","Version":"0.0701","Package":"libwww-pusher-0.0701-p5","Author":"RIZEN"}
 -------------------------------------------------------------------------

 __________________________________________________________________________
 DPKG CONTROL
 --------------------------------------------------------------------------
Author: RIZEN
Package: libwww-pusher-0.0701-p5
Depends: Test::More URI Digest::SHA Digest::MD5 JSON Test::Deep LWP ExtUtils::MakeMaker
Version: 0.0701
Description: Interface to the Pusher WebSockets API
Name: WWW-Pusher-0.0701
 -------------------------------------------------------------------------
 ```
