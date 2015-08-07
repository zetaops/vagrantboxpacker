Online Build
============

Create User
https://atlas.hashicorp.com/

Download Packer
https://packer.io/downloads.html

Type ``` vagrant login ``` on terminal and enter your atlas.hashicorp information to get access.

Now clone this repo

```
git clone https://github.com/zetaops/vagrantboxpacker.git
cd vagrantboxpacker
```
Change user name(mine is zetaops) in template.json with yours.
```
"push": {
     "name": "zetaops",
     "vcs": true
   },


```
After that login atlas.hashicorp website and press Builds.

Answer questions, generate tokens and verify tokens and paste them into your terminal.

Give a name your build and push.

```
packer push -name cemg/example2 template.json

```

###Important ###
At every box build, change your version number, which is at the bottom of ``` template.json ``` file.

Local Build
===========

Create User
https://atlas.hashicorp.com/

Download Packer
https://packer.io/downloads.html

Now clone this repo

```
git clone https://github.com/zetaops/vagrantboxpacker.git
cd vagrantboxpacker
```

Now build box

```
packer build template.json

```

After a long wait your box will be ready.

Now add it vagrant list and give a name to your box

```
vagrant box add created_box_name --name mybox

```

To see your box in list

```
vagrant list

```

Now

```

mkdir mybox
cd mybox
vagrant init
```

Change ```config.vm.box = "base"``` with ```config.vm.box = "mybox"``` in Vagrantfile and it's done.

```

vagrant up
vagrant ssh

```
