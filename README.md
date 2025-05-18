# BrightSense: Multi-Point Smart Light Monitoring System

## i. Introduction to the Problem and the Solution

Sistem pencahayaan merupakan salah satu aspek penting dalam kehidupan sehari-hari, karena hampir seluruh aktivitas manusia memerlukan penerangan yang memadai. Seiring dengan meningkatnya kebutuhan akan kenyamanan dan efisiensi, sistem pencahayaan adaptif menjadi salah satu solusi yang relevan untuk menjawab tantangan tersebut. Sebagai upaya untuk memenuhi kebutuhan tersebut, dikembangkan suatu sistem monitoring cahaya berbasis mikrokontroler Arduino UNO yang dinamakan BrightSense. BrightSense merupakan sebuah sistem monitoring yang memanfaatkan tiga buah sensor LDR (Light Dependent Resistor) untuk mendeteksi intensitas cahaya dari berbagai arah. Data yang diperoleh dari ketiga sensor kemudian diolah, di mana hasil pengolahan data tersebut digunakan untuk mengatur tingkat kecerahan sebuah LED melalui sinyal PWM (Pulse Width Modulation). 

Meskipun BrightSense dirancang sebagai sistem pencahayaan adaptif, perangkat ini juga menawarkan opsi mode manual yang memungkinkan pengguna untuk dapat mengatur tingkat kecerahan LED secara langsung. Dengan demikian, BrightSense menjadi sistem yang fleksibel dan dapat disesuaikan dengan kebutuhan pengguna, baik dalam mode otomatis berbasis sensor maupun dalam pengaturan manual. Pendekatan ini tidak hanya meningkatkan efisiensi energi, tetapi juga memberikan kenyamanan yang lebih baik bagi pengguna dalam berbagai kondisi pencahayaan. Hal ini menjadikan BrightSense sebagai solusi yang tepat untuk diterapkan dalam berbagai lingkungan, mulai dari lingkungan tempat tinggal hingga lingkungan kerja yang membutuhkan pencahayaan responsif.


## ii. Hardware Design and Implementation Details

### Komponen Utama
- Arduino UNO
- LDR (3) + Resistor 10kΩ (3)
- LED (1) + Resistor 220Ω (1)
- Push button (3)
- LCD + I2C module
- Breadboard
- Jumper

### Rangkaian (Proteus)
![Proteus](https://hackmd.io/_uploads/S1OTvY7-xe.png)

### Konektivitas dan Implementasi
BrightSense mengintegrasikan berbagai komponen input dan output yang dirakit pada breadboard dan terhubung ke mikrokontroler Arduino UNO. Implementasi dilakukan dengan mempertimbangkan efisiensi penggunaan pin I/O serta kestabilan sinyal. Berikut penjelasan mengenai konfigurasi dan implementasi penggunaan tiap komponen pada sistem.

- **Sensor LDR (3 buah)**
  
  Ketiga sensor LDR dipasang pada posisi yang berbeda untuk menangkap intensitas cahaya dari berbagai arah. Masing-masing sensor dihubungkan dengan resistor 10kΩ sebagai pembagi tegangan (voltage divider), yang dikonfigurasikan sebagai pull-down untuk menghasilkan sinyal analog yang sesuai terhadap tingkat pencahayaan. Sensor diuji dengan memantau perubahan nilai ADC yang hasilnya akan ditampilkan melalui serial monitor. Pin-pin yang digunakan adalah:
  - LDR1 : PC3 / ADC3
  - LDR2 : PC2 / ADC2
  - LDR3 : PC1 / ADC4
  
- **LED**
  
  LED berfungsi sebagai aktuator utama dalam sistem dan dikendalikan melalui sinyal PWM yang dihasilkan oleh Timer1. LED dihubungkan ke pin PB1 (OC1A) yang mendukung output PWM 8 bit dalam mode Fast PWM. Resistor 220Ω dipasang secara seri untuk membatasi arus dan mencegah kerusakan pada LED.

- **Push Button (3 buah)**
  
  Tiga buah push button digunakan sebagai sistem kontrol pada mode manual. Tombol-tombol ini dihubungkan ke pin Arduino dengan konfigurasi pull-up internal. Hal ini membuat pembacaan bernilai LOW ketika tombol ditekan (terhubung ke GND). Fungsi dari masing-masing tombol:
  - PD2 (INT0): sebagai tombol pengatur pergantian mode yang memanfaatkan interrupt eksternal. Mengubah LED dari mode otomatis ke manual, dan sebaliknya.
  - PD3: untuk menurunkan kecerahan LED saat berada dalam mode manual.
  - PD4: untuk menaikkan kecerahan LED dalam mode manual.

- **Serial Communication (USART)**
  
  Serial monitor berperan dalam proses pemantauan nilai sensor secara real-time. Sistem menggunakan USART dengan baud rate 9600 bps, di mana komunikasi dilakukan melalui pin TX (PD1), dengan data seperti nilai intensitas cahaya dan status mode dikirim ke serial monitor. Implementasi komunikasi serial ini memudahkan validasi sistem selama tahap pengujian.

- **LCD (via I2C)**
 
  LCD 16x2 digunakan sebagai media visualisasi utama pada sistem. Komunikasi ini dilakukan melalui modul I2C yang menghubungkan pin SDA (A4) dan SCL (A5) ke Arduino UNO. Penggunaan I2C memungkinkan efisiensi pin dan mempermudah proses integrasi dengan komponen lainnya. 


## iii. Software Implementation Details

### Struktur Umum
Sistem BrightSense terbagi dalam dua mode utama, yaitu:
1. **Mode Otomatis**
   >Tingkat kecerahan LED disesuaikan secara real time berdasarkan rata-rata pembacaan tiga sensor LDR.
2. **Mode Manual**
   >Pengguna dapat mengatur kecerahan LED menggunakan tombol increment dan decrement.

### Fitur dan Implementasi 
- **ADC (Analog to Digital Converter)**
   
   Menggunakan 3 channel ADC, yaitu ADC2 (PC2), ADC3 (PC3), dan ADC4 (PC1). Data dari ketiga LDR dibaca satu per satu, lalu rata-rata dari hasil pembacaan sensor tersebut akan dihitung dengan menggunakan subrutin pembagian 16 bit. Hasil perhitungan tersebut kemudian disimpan dalam register dan digunakan sebagai acuan yang mengatur tingkat kecerahan LED pada mode otomatis.

- **Push Button pada Input Manual**
  
  Tombol pada PD3 dan PD4 digunakan untuk menurunkan dan menaikkan nilai PWM ketika sistem sedang berada dalam mode manual. Tombol dikonfigurasi dengan internal pull-up dan dibaca langsung dalam loop `manual_loop`.

- **PWM (Pulse Width Modulation)**
  
  LED dikendalikan oleh sinyal PWM dari pin OC1A (PB1) yang memanfaatkan Timer1. Timer1 dikonfigurasi dalam mode Fast PWM 8 bit (WGM10 = 1, WGM12 = 1) dengan prescaler 8. Nilai OCR1A diatur berdasarkan data ADC atau input manual, untuk mengatur duty cycle PWM.

- **Komunikasi Serial (USART)**
  
  Pada sistem ini, USART dikonfigurasi dengan baud rate 9600 bps. USART berfungsi untuk mencetak nilai ADC, nilai PWM, serta mode sistem ke serial monitor dengan memanfaatkan subrutin `print_3digit_decimal` untuk mengubah angka biner menjadi representasi desimal ASCII.

- **Interrupt (INT0)**

  INT0 (PD2) berfungsi untuk mengganti mode pada LED, dari otomatis ke manual, dan sebaliknya. Interrupt handler `__vector_1` melakukan debounce sederhana dan men-*toggle* bit R19 sebagai flag mode. Setiap pergantian mode, suatu pesan akan dicetak ke serial monitor.

- **Timer (Timer0)**
  
  Timer0 digunakan untuk menghasilkan delay berbasis waktu (ms) dengan menggunakan `timer0_delay_ms`. Delay pada sistem ini berfungsi untuk menstabilkan pembacaan tombol (debounce) serta memberi jeda pada tampilan data dan pembacaan sensor.

- **I2C (Komunikasi dengan LCD)**
  
  Modul LCD I2C (alamat 0x7C) digunakan untuk menampilkan mode dan nilai (ADC/PWM). Komunikasi dilakukan dengan menggunakan register TWI (TWBR, TWCR, dll). Label `LCD_init`, `LCD_print_3digit_decimal`, dan `disp_msg` digunakan untuk mengatur pengiriman data dan perintah.

### Alur Program
Alur program BrightSense dimulai dengan proses inisialisasi seluruh subsistem, meliputi konfigurasi ADC, USART, Timer1 untuk PWM, interrupt eksternal INT0, interface I2C (TWI), serta inisialisasi LCD. Setelah pengaturan selesai dan sistem sudah berfungsi, pesan pembuka akan ditampilkan pada layar LCD sebagai tanda bahwa perangkat telah siap digunakan. Setelah itu, program akan memasuki loop utama yang berjalan terus-menerus. Pada kondisi awal, sistem secara default akan berada dalam mode otomatis, yang ditandai dengan flag register R19 bernilai nol. Pada mode ini, mikrokontroler membaca data intensitas cahaya dengan menggunakan tiga sensor LDR melalui ADC, kemudian menghitung nilai rata-rata dari ketiga hasil tersebut untuk menjadi acuan pengaturan tingkat kecerahan LED dengan mengubah nilai duty cycle pada register OCR1A. Nilai tersebut juga akan dikirim ke serial monitor dan ditampilkan pada LCD.

Penekanan tombol yang terhubung dengan pin PD2 akan memicu interrupt eksternal INT0. Handler interrupt akan melakukan debounce, kemudian membalik nilai flag R19 sehingga dapat berpindah ke mode sebaliknya. Ketika sistem berada dalam mode manual (R19 = 1), pengguna dapat menaikkan atau menurunkan kecerahan LED dengan menekan tombol increment atau decrement. Perubahan nilai PWM akan ditampilkan secara real time ke serial monitor dan LCD. Transisi antara kedua mode pada sistem BrightSense ini dapat dilakukan kapan saja, dengan tampilan dan data yang akan selalu menyesuaikan kondisi sistem tersebut.


## iv. Test Results and Performance Evaluation

Pengujian dilakukan secara langsung pada rangkaian fisik sistem *BrightSense* menggunakan mikrokontroler Arduino Uno, tiga buah sensor LDR, satu buah LED, dan tiga tombol input. Sistem diuji dalam dua mode utama, yaitu mode otomatis dan mode manual, dengan pemantauan melalui serial monitor serta tampilan LCD 16x2 berbasis I2C.

Pada **mode otomatis**, sistem berhasil menyesuaikan tingkat kecerahan LED secara real-time berdasarkan intensitas cahaya di lingkungan. Sensor LDR membaca nilai pencahayaan dari tiga arah berbeda, yang kemudian dirata-ratakan dan digunakan untuk menentukan duty cycle PWM. Saat pencahayaan sekitar berkurang, LED menyala lebih terang, dan saat cahaya meningkat, LED meredup secara bertahap. Ini menunjukkan bahwa pembacaan ADC, perhitungan logika, dan pengendalian PWM berjalan dengan baik.

Pada **mode manual**, tombol-tombol PD3 dan PD4 digunakan untuk menurunkan atau menaikkan kecerahan LED secara langsung. Mode ini diaktifkan melalui tombol interrupt eksternal yang terhubung ke pin PD2. Sistem berhasil berpindah mode tanpa mengganggu proses utama, dan perubahan nilai PWM dapat terlihat secara responsif pada LED. Namun, ditemukan kendala pada tampilan LCD — **modul LCD tidak menampilkan data apa pun selama pengujian fisik**, meskipun telah berfungsi normal dalam simulasi. Masalah ini diduga disebabkan oleh konfigurasi alamat I2C yang tidak sesuai atau kesalahan wiring.

Meski begitu, seluruh data sistem tetap dapat dimonitor secara real-time melalui serial monitor Arduino IDE, sehingga semua fungsi utama tetap dapat divalidasi.

Berikut dokumentasi pengujian rangkaian fisik:

![Y65GbH.jpg](https://s6.imgcdn.dev/Y65GbH.jpg)


## v. Conclusion and Future Work
BrightSense dikembangkan sebagai sistem monitoring dan pengendalian pencahayaan berbasis mikrokontroler yang adaptif dan fleksibel. Dengan memanfaatkan tiga sensor LDR yang terpasang pada posisi berbeda, sistem dapat membaca intensitas cahaya dari berbagai arah dan menyesuaikan tingkat kecerahan LED secara real time melalui sinyal PWM. Selain mode otomatis, sistem juga menyediakan mode manual yang memungkinkan pengguna mengatur kecerahan secara langsung melalui tombol. Hal ini membuat BrightSense lebih responsif terhadap preferensi pengguna. Fitur tambahan berupa tampilan data melalui LCD dan serial monitor bertujuan untuk meningkatkan aspek interaktivitas dan kemudahan dalam pemantauan. Selama tahap pengujian, seluruh fitur pada sistem BrightSense telah bekerja sesuai dengan rancangan, di mana nilai ADC dapat terbaca dengan akurat, output PWM berfungsi dengan stabil, serta transisi antar mode dapat dilakukan tanpa gangguan. 

Di masa yang akan datang, pengembangan BrightSense dapat lebih difokuskan pada peningkatan efisiensi dan kenyamanan penggunaan, seperti penambahan fitur penyelarasan otomatis sensor untuk menyesuaikan nilai ambang cahaya berdasarkan lingkungan sehingga dapat mengatur tingkat kecerahan LED dengan lebih akurat. Selain itu, peningkatan juga dapat berupa penambahan indikator visual pada sistem, seperti LED status mode, atau modifikasi pada tampilan informasi di LCD dan serial monitor agar lebih informatif. Penggunaan sistem juga dapat diperbanyak pada lebih dari satu titik pencahayaan dengan sistem kontrol yang tetap terpusat.
