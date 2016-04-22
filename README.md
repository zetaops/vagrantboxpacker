Ulakbüs Geliştirme Ortamı Makinesi
==========================

### Sanal Makinede Bulunan Uygulamalar ###

Lütfen [bağlantıdaki](http://www.ulakbus.org/wiki/development_environment_setup.html) belgeyi inceleyiniz.

### Sanal Makine Kullanımı Nasıl? ###

Lütfen [bağlantıdaki](http://www.ulakbus.org/wiki/development_environment_setup.html) belgeyi inceleyiniz.

### Sanal Makine Nasıl Güncellenir? ###

  ### Kullanıcılar İçin Güncelleme ###

 Lütfen [bağlantıdaki](http://www.ulakbus.org/wiki/development_environment_setup.html) belgeyi inceleyiniz.

  ### Geliştiriciler İçin Güncelleme ###

  İşlemlere başlamadan önce [buradaki](https://github.com/zetaops/ulakbus-development-box) adresten dosyaları klonlayınız.


  - ### Uygulamaların Güncellenmesi ve Yüklenmesi ###

  Yeni güncellemede eklemek ya da çıkarmak istediğiniz uygulamaları "scripts" klasörü altındaki "dep.sh" dosyasının içerisine yazınız. Versiyon güncellenirken bu değişiklikler göz önüne alınacaktır. Virtualenv içine kurulacak olan paketler, ilgili uygulamanın git deposundaki requirements.txt dosyasının içinden okunurlar, kurmaya çalışmayınız.

  - ### Versiyon Numarası Güncelleme ###

   Klonlanan klasörün içerisinde bulunan template.json dosyasında "post-processors" bölümü altındaki "version" satırını değiştiriniz.

  ```bash
   "version": "0.2.8"
  ```

  - ### Box'un Atlas Hashicorp'a Yüklenmesi ###

  **Bu işlemin yapılabilmesi için versiyon numarası bir önceki versiyon numarasıyla farklı olmalıdır.**

  Gereken uygulamalar: Packer ([bu adresten](https://www.packer.io/downloads.html) indirebilirsiniz.)

 Atlas Hashicorp'ta box'ı güncellemek icin [bu adresten](https://atlas.hashicorp.com/settings/tokens) "generate token" ile token alınız. Konsolda "export ATLAS_TOKEN=TOKEN" komutuyla size verilen token ile doğrulamayı yapınız. Örnek olarak:

    ```bash
     export ATLAS_TOKEN=lA1ckHHg.atlasv1.gThadajbankdI49eark1LPHknQ
    ```

    Doğrulamayı yaptıktan sonra konsoldan "vagrant login" yazarak Atlas kullanıcı adı ve şifrenizi giriniz.

    ```bash
     vagrant login
    ```
    Ardından "packer push" komutu ile güncel boxınızı Atlas Hashicorp'a yükleyebilirsiniz.

    ```bash
      packer push -name zetaops/ulakbus template.json
    ```
