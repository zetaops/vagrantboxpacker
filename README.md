Ulakbus Gelistirme Ortami Makinesi
==========================

#### Ulakbus ile gelistirme icin gerekli araclari icermektedir. ####

- Ulakbus
- Zengine
- Pyoko
- Riak
- Zato

Vagrant makinesine ilk baglandiginizda, "vagrant" kullanicisi ile baglanmis olucaksiniz.

vagrant kullanicisinin sifresi : "vagrant" 'tir (tirnaklar olmadan).

Ulakbus, Zengine ve Pyoko kutuphaneleri, "ulakbus" kullanicisi altindadir.Ulakbus kullanicisina, asagidaki komut ile gecis yapiniz.

```bash
sudo su - ulakbus
```
Not: ulakbus kullanicisinin sudo hakki vardir.

Ulakbus kullanicisina giris yaptiginizda; sizi Ulakbus, Zengine, Pyoko kutuphaneleri ve ulakbusenv, pyokoenv, zengineenv adlarinda 3 tanede python virtual environmentini goruceksiniz.
Gelistirmenizi bu python virtualenvlari uzerinden yapicaksiniz.

Ornek olarak ulakbusenv'ini kullanarak ulakbus ile gelistirme yapmak icin ulakbusenv aktiflestirmeniz gerek.Asagidaki komut ile virtual environmenti aktiflestirin.

```bash
source ~/ulakbusenv/bin/activate
```

Zengine ve Pyoko kutuphaneleri ile gelistirme yapmak icinde sirasiyla asagidaki komutlari kullanabilirsiniz.

```bash
source ~/zengineenv/bin/activate
source ~/pyokoenv/bin/activate
```

#### Riak ####
Riak jvm memory icin ayrilan bellek 256 MB'tir. Ihtiyaclariniza gore daha fazla arttirmak icin riak.conf , ayar dosyasini acin.

```bash
sudo vim /etc/riak/riak.conf
```
Asagidaki satiri;
```bash
search.solr.jvm_options = -d64 -Xms256m -Xmx256m -XX:+UseStringCache -XX:+UseCompressedOops
```
alttaki ile degistirin.Bu Riak jvm memory'i icin kullanilan bellegi 512 MB'ta yukseltecektir.

```bash
search.solr.jvm_options = -d64 -Xms512m -Xmx512m -XX:+UseStringCache -XX:+UseCompressedOops
```

#### Zato ####

Zato kullanimi icin, zato kullanicisina gecmeniz gerek.

```bash
sudo su - zato
```

- Zato Web Admin sifresi : ulakbus 'tur.

- Zato icin 1 zato server olusturulmustur.

- Gelistirme ortamina baglandiginizda, zato componentleri otomatik olarak baslatilmistir.
 - Zato kullanicisindayken zato componentlerini baslat, durdurmak veya yeniden baslatmak isterseniz, ulakbus klasoru icindeki zato-qs-restart.sh, zato-qs-start.sh, zato-qs-stop.sh scriptlerini kullaniniz.Ornek olarak yeniden baslatmak isterseniz,
   ```bash
   ./ulakbus/zato-qs-restart.sh
   ```
 - Root kullanicisi ile de yeniden baslatip, durdurup, baslatabilirsiniz.

   ```bash
  service zato status
  service zato start
  service zato stop
  service zato restart
   ```

 #### Ek Bilgiler ####

 Kendi bilgisayarinizdan ulakbus uygulamasina, zato web admini ve riak httpye baglanmak icin asagidaki satirlari Vagrantfile 'a ekleyiniz.

 ```bash
 #ulakbus app
 config.vm.network "forwarded_port", guest: 9001, host: 9001

 # zato web admin
 config.vm.network "forwarded_port", guest: 8183, host: 8183

 # riak http
 config.vm.network "forwarded_port", guest: 8098, host: 8098

 ```

 Sync folderlarinizi ornek olarak asgidaki gibi ayarlayabilirsiniz.

 ```bash

 # ulakbus
 config.vm.synced_folder "~/dev/zetaops/ulakbus", "/app/ulakbus", owner: "ulakbus", group: "ulakbus"

 # zengine
 config.vm.synced_folder "~/dev/zetaops/zengine", "/app/zengine", owner: "ulakbus", group: "ulakbus"

 # ulakbus-pyoko
 config.vm.synced_folder "~/dev/zetaops/pyoko", "/app/pyoko", owner: "ulakbus", group: "ulakbus"

 # ulakbus-ui
 config.vm.synced_folder "~/dev/zetaops/ulakbus-ui", "/app/ulakbus-ui", owner: "ulakbus", group: "ulakbus"

 ```
