# Summary
A getopt implementation in tcl that compat with GNU getopt_long_only(3) or getopt(1) -a

# Why I write a new one
I was planning to re-write a tool that use GNU style options, 
but default tcl lib cmdline can not support --options format,
and others that I found were not good enough for me.

features in my getopt.tcl:
1. generate usage/help info from option list.
2. support GNU style option and more flexible: -a --along --b -c carg -d=darg -ooptionalarg -- --notoption
2. not just support a short and a long option, you can define a *List* {h help Help ? 帮助}
3. hide attribute of option object， used to hide some option in usage/help info
4. option group
4. forward option

note: I've wrote a golang implementation https://github.com/tcler/getopt.go ; welcome to try

# Example code
see here: https://github.com/tcler/getopt.tcl/blob/master/getOpt-3.0/example.tcl

# Install
Copy the dir getOpt-$version to /usr/local/lib or other specified dir.

# Test
```
$ git clone https://github.com/tcler/getopt.tcl
$ cd getopt.tcl/getOpt-3.0
$ ./example.tcl  --help -repo xyz --debugii -cc a@r.org  -h  --abcdefg  --kcov  --cc=ff@rh.com  -repo=ftp://a.b.c/love -listf=example.tcl rawarg -oa=b -- -a -b
Usage: ./example.tcl [options]
*Options:
  *Options group description1:
    -f, --file, --listf <arg>
                               #Specify a test list file
    --cc {arg}                 #Notify additional e-mail address on job completion

  *Options group description2:
    --kcov                     #insert kcov task for do the kernel test coverage check
    --kdump [arg]              #insert kdump task for get core dump file if panic happen
    -o [arg]                   mount options

  *Options group description3:
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
Opt(o)       = a=b
InvalidOpt(abcdefg) = unkown options
NotOptions: rawarg -a -b
ForwardOpt: -repo=xyz -repo=ftp://a.b.c/love

```
