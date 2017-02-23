# getOpt.tcl
A getopt implementation in tcl that compat with GNU getopt_long_only(3) or getopt(1) -a

# install
Copy the dir getOpt-$version to /usr/local/lib or other specified dir.

# how to use
https://github.com/tcler/getopt.tcl/blob/master/getOpt-3.0/example.tcl

```
$ ./example.tcl  --help -repo xyz --debugii -cc a@r.org  -h  --abcdefg  --kcov  --cc=ff@rh.com  -repo=ftp://a.b.c/love -listf=example.tcl rawarg
Usage: ./example.tcl [options]
*Options:
  *Options group description1:
    -f, --file, --listf <arg> 
                               #Specify a test list file
    --cc {arg}                 #Notify additional e-mail address on job completion

  *Options group description2:
    --kcov                     #insert kcov task for do the kernel test coverage check
    --kdump [arg]              #insert kdump task for get core dump file if panic happen

  *Options group description3:
    --debugi                   nil #no help found for this options
    --debugii                  nil #no help found for this options
    -h, -H, --help             nil #no help found for this options
    --repo {arg}               Configure repo at <URL> in the kickstart for installation
    --recipe                   Just generate recipeSet node, internal use for runtest -merge

Comments:
    *  [arg] means arg is optional, need use --opt=arg to specify an argument
       <arg> means arg is required, and -f a -f b will get the latest 'b'
       {arg} means arg is required, and -f a -f b will get a list 'a b'

    *  if arg is required, '--opt arg' is same as '--opt=arg'

    *  '-opt' will be treated as:
           '--opt'    if 'opt' is defined;
           '-o -p -t' if 'opt' is undefined;
           '-o -p=t'  if 'opt' is undefined and '-p' need an argument;

Opt(cc)      = a@r.org ff@rh.com
Opt(debugii) = 1
Opt(f)       = example.tcl
Opt(h)       = 2
Opt(kcov)    = 1
InvalidOpt(abcdefg) = unkown options
NotOptions: rawarg
ForwardOpt: --repo=xyz --repo=ftp://a.b.c/love

```

https://github.com/tcler/getopt.tcl/blob/master/getOpt-2.0/example.tcl
https://github.com/tcler/getopt.tcl/blob/master/getOpt-1.0/example.tcl
