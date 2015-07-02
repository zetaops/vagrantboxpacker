Online Build
============

Create User
https://atlas.hashicorp.com/

Download Packer
https://packer.io/downloads.html

Now clone this repo

```
git clone https://github.com/dyrnade/vagrantboxpacker
cd vagrantboxpacker
```
Change user name(mine is cemg) in template.json with yours.
```
"push": {
     "name": "cemg",
     "vcs": true
   },


```
After that login atlas.hashicorp website and press Builds.

Answer questions, generate tokens and verify tokens.

Give a name your build and push.

```
packer push -name cemg/example2 template.json

```


Local Build
===========

Create User
https://atlas.hashicorp.com/

Download Packer
https://packer.io/downloads.html

Now clone this repo

```
git clone https://github.com/dyrnade/vagrantboxpacker
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

Change ```config.vm.box=""``` with mybox and it's done.

```

vagrant up
vagrant ssh

```
