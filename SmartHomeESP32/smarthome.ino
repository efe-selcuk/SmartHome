#include <WiFi.h>
#include <DHT.h>
#include <IRremote.hpp>  // IRremote kütüphanesi
#include "IRCodes.h"  // Özel IR kodları header dosyası

// DHT11 tanımlamaları
#define DHTPIN 4       // DHT11 veri pini
#define DHTTYPE DHT11  // DHT11 sensörü
DHT dht(DHTPIN, DHTTYPE);

// IR LED tanımlaması (TSAL6400)
#define IR_SEND_PIN 5  // TSAL6400 IR LED için GPIO 5
// IR taşıyıcı frekansı (klima kumandaları için genellikle 38kHz kullanılır)
#define IR_FREQUENCY 38 // kHz

// Wi-Fi bilgileri
const char* ssid = "GEF Wi-Fi";
const char* password = "Gef2002haziran.";

// 5 LED'in GPIO pinleri
const int ledPins[] = {2, 15, 16, 17, 18};  // Her odanın LED GPIO'ları (Oda 1 -> GPIO 2, Oda 2 -> GPIO 15, vb.)
// Oda ışıklarının durumu
bool lightStatus[] = {false, false, false, false, false}; // LED'lerin açık/kapalı durumu

// Klima kontrol durumu
bool acStatus = false; // Klima durumu (açık/kapalı)
int acTemp = 22;       // Varsayılan sıcaklık
String acMode = "cool"; // Varsayılan mod (cool, heat, fan)
String acFanSpeed = "auto"; // Varsayılan fan hızı

// IR kontrollü LED ışık durumu
bool irLedStatus = false;

WiFiServer server(80);  // HTTP sunucusu için port 80

void setup() {
  Serial.begin(115200);
  delay(1000); // Seri bağlantının dengelenmesi için kısa bir gecikme
  
  Serial.println("\n\nSmartHome Sistemi Başlatılıyor...");
  Serial.println("LED Pin Yapılandırması:");

  // LED pinlerini çıkış olarak ayarla ve başlangıçta tümünü test et
  for (int i = 0; i < 5; i++) {
    pinMode(ledPins[i], OUTPUT);
    
    // Başlangıçta tüm LED'leri kapalı olarak ayarla
    digitalWrite(ledPins[i], LOW);
    lightStatus[i] = false;
    
    Serial.print("Oda ");
    Serial.print(i + 1);
    Serial.print(" LED -> GPIO ");
    Serial.println(ledPins[i]);
    
    // Her LED'i hızlıca yanıp söndürerek test et (doğru çalıştığını görmek için)
    digitalWrite(ledPins[i], HIGH);
    delay(300);
    digitalWrite(ledPins[i], LOW);
    delay(300);
  }

  // IR LED'i başlat
  // Alternatif 1: Üç parametreli versiyon (yeni IRremote sürümleri için)
  IrSender.begin(IR_SEND_PIN, true, LED_BUILTIN); // Pin, LED geri bildirim (true), geri bildirim pini
  
  // Alternatif 2: Tek parametreli versiyon (eski IRremote sürümleri için)
  // IrSender.begin(IR_SEND_PIN); // Sadece IR pin numarası
  
  Serial.println("IR LED (TSAL6400) başlatıldı - GPIO " + String(IR_SEND_PIN));
  Serial.println("IR frekansı: " + String(IR_FREQUENCY) + " kHz");
  
  // IR LED çalışma testi - açma/kapama sinyali
  Serial.println("IR LED test ediliyor...");
  // Test için basit IR sinyal gönder
  delay(1000);
  IrSender.sendNEC(0xFFFF, 0x01, 0);
  delay(500);
  // Ham veri olarak da test et
  Serial.println("IR LED ham veri test ediliyor...");
  IrSender.sendRaw(LEDKodlari::RAW_ACMA, sizeof(LEDKodlari::RAW_ACMA)/sizeof(LEDKodlari::RAW_ACMA[0]), IR_FREQUENCY);

  dht.begin();  // DHT sensörünü başlat
  Serial.println("DHT11 sensörü başlatıldı");

  // Wi-Fi'ye bağlan
  Serial.println("WiFi'ye bağlanıyor...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nWiFi bağlantısı başarılı!");
  Serial.print("IP Adresi: ");
  Serial.println(WiFi.localIP());

  // Kullanım talimatlarını göster
  Serial.println("\nKullanım:");
  Serial.println("1. Sıcaklık ve nem değerleri için: http://<IP_Adresi>/");
  Serial.println("2. Oda ışıklarını kontrol etmek için:");
  for (int i = 0; i < 5; i++) {
    Serial.print("   - Oda ");
    Serial.print(i + 1);
    Serial.print(" ışığını açmak için: http://<IP_Adresi>/room");
    Serial.print(i + 1);
    Serial.println("/light?status=on");
    
    Serial.print("   - Oda ");
    Serial.print(i + 1);
    Serial.print(" ışığını kapatmak için: http://<IP_Adresi>/room");
    Serial.print(i + 1);
    Serial.println("/light?status=off");
  }
  
  // Klima kontrolü için talimatlar
  Serial.println("3. Klimayı kontrol etmek için:");
  Serial.println("   - Klimayı açmak için: http://<IP_Adresi>/ac?status=on");
  Serial.println("   - Klimayı kapatmak için: http://<IP_Adresi>/ac?status=off");
  Serial.println("   - Klima sıcaklığını ayarlamak için: http://<IP_Adresi>/ac?temp=22");
  Serial.println("   - Klima fan hızını ayarlamak için: http://<IP_Adresi>/ac?fan=low");
  Serial.println("     (kullanılabilir fan hızları: low, medium, high, auto)");
  Serial.println("   - Klima modunu ayarlamak için: http://<IP_Adresi>/ac?mode=cool");
  Serial.println("     (kullanılabilir modlar: cool, heat, dry, fan, auto)");
  
  // IR kontrollü LED ışık kontrolü için talimatlar
  Serial.println("4. IR kontrollü LED ışığı kontrol etmek için:");
  Serial.println("   - IR LED ışığını açmak için: http://<IP_Adresi>/irled?status=on");
  Serial.println("   - IR LED ışığını kapatmak için: http://<IP_Adresi>/irled?status=off");
  Serial.println("   - IR LED rengini değiştirmek için: http://<IP_Adresi>/irled?color=red");
  Serial.println("     (kullanılabilir renkler: red, green, blue, white)");
  Serial.println("   - IR LED efekti için: http://<IP_Adresi>/irled?effect=flash");
  Serial.println("     (kullanılabilir efektler: flash, strobe, fade, smooth)");
  Serial.println("   - IR LED parlaklığını artırmak için: http://<IP_Adresi>/irled?brightness=up");
  Serial.println("   - IR LED parlaklığını azaltmak için: http://<IP_Adresi>/irled?brightness=down");

  // Kumanda kontrolü için talimatlar
  Serial.println("5. TV Kumandası kontrolü için:");
  Serial.println("   - Gücü aç/kapat için: http://<IP_Adresi>/remote?power=toggle");
  Serial.println("   - Ses kontrolü için:");
  Serial.println("     * Sesi arttır: http://<IP_Adresi>/remote?volume=up");
  Serial.println("     * Sesi azalt: http://<IP_Adresi>/remote?volume=down");
  Serial.println("     * Sessiz: http://<IP_Adresi>/remote?volume=mute");
  Serial.println("   - Kanal kontrolü için:");
  Serial.println("     * Kanal arttır: http://<IP_Adresi>/remote?channel=up");
  Serial.println("     * Kanal azalt: http://<IP_Adresi>/remote?channel=down");
  Serial.println("   - Yön tuşları için:");
  Serial.println("     * Yukarı: http://<IP_Adresi>/remote?direction=up");
  Serial.println("     * Aşağı: http://<IP_Adresi>/remote?direction=down");
  Serial.println("     * Sol: http://<IP_Adresi>/remote?direction=left");
  Serial.println("     * Sağ: http://<IP_Adresi>/remote?direction=right");
  Serial.println("     * OK: http://<IP_Adresi>/remote?button=ok");
  Serial.println("   - Sayısal tuşlar için: http://<IP_Adresi>/remote?button=X");
  Serial.println("     (X yerine 0-9 arası bir rakam girin)");

  server.begin();  // Sunucuyu başlat
  Serial.println("HTTP sunucusu başlatıldı");
}

// IR sinyal gönderme fonksiyonu - Hex kod için
void sendIRSignal(unsigned long code) {
  Serial.print("IR sinyal gönderiliyor (HEX): 0x");
  Serial.println(code, HEX);
  
  // Debug için tüm byte değerlerini göster
  Serial.print("Değer olarak: ");
  Serial.print((code >> 24) & 0xFF, HEX); Serial.print(" ");
  Serial.print((code >> 16) & 0xFF, HEX); Serial.print(" ");
  Serial.print((code >> 8) & 0xFF, HEX); Serial.print(" ");
  Serial.println(code & 0xFF, HEX);
  
  // NEC protokolü - Düzeltilmiş adres ve komut hesaplama
  uint16_t address = code & 0xFFFF;           // Alt 16 bit (adres)
  uint8_t command = (code >> 16) & 0xFF;      // Orta 8 bit (komut)
  
  Serial.print("NEC Protokolü - Adres: 0x");
  Serial.print(address, HEX);
  Serial.print(", Komut: 0x");
  Serial.println(command, HEX);
  
  // NEC protokolü gönderimi
  IrSender.sendNEC(address, command, 0);
  
  // Alternatif olarak raw data kullanımı
  if (code == LEDKodlari::ACMA) {
    Serial.println("LED AÇMA komutu - Ham veri kullanılıyor...");
    IrSender.sendRaw(LEDKodlari::RAW_ACMA, sizeof(LEDKodlari::RAW_ACMA)/sizeof(LEDKodlari::RAW_ACMA[0]), IR_FREQUENCY);
  }
  else if (code == LEDKodlari::KAPAMA) {
    Serial.println("LED KAPAMA komutu - Ham veri kullanılıyor...");
    IrSender.sendRaw(LEDKodlari::RAW_KAPAMA, sizeof(LEDKodlari::RAW_KAPAMA)/sizeof(LEDKodlari::RAW_KAPAMA[0]), IR_FREQUENCY);
  }
  
  Serial.println("HEX kod gönderildi!");
}

// Ham IR verilerini gönderme fonksiyonu (Raw IR Data)
void sendRawIRSignal(const uint16_t rawData[], int length) {
  Serial.println("Ham IR verisi gönderiliyor...");
  Serial.print("Veri uzunluğu: ");
  Serial.println(length);
  
  // Ham veriyi 38kHz frekansında gönder
  // Not: Boyut hesaplaması için örnek koddaki yapıyı kullanalım
  IrSender.sendRaw(rawData, length, IR_FREQUENCY);
  
  Serial.println("Ham IR verisi gönderildi!");
}

void handleRequest(WiFiClient client) {
  String request = client.readStringUntil('\r');
  client.flush();

  Serial.println("\nYeni İstek: " + request);

  // DHT11'den sıcaklık ve nem verilerini oku
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();

  if (isnan(temp) || isnan(hum)) {
    temp = 0.0;
    hum = 0.0;
    Serial.println("DHT sensör hatası!");
  }

  // LED kontrol isteklerini işle
  bool requestHandled = false;
  
  // Oda LED kontrolü
  for (int i = 0; i < 5; i++) {
    String endpointOn = "/room" + String(i + 1) + "/light?status=on";
    String endpointOff = "/room" + String(i + 1) + "/light?status=off";

    if (request.indexOf(endpointOn) != -1) {
      // İlgili LED'i aç
      Serial.print("Komut algılandı: Oda ");
      Serial.print(i + 1);
      Serial.print(" ışığını AÇ (GPIO ");
      Serial.print(ledPins[i]);
      Serial.println(")");
      
      digitalWrite(ledPins[i], HIGH);
      lightStatus[i] = true;
      
      // Tüm LED'lerin güncel durumunu yazdır
      printLedStatus();
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nOK");
      client.stop();
      requestHandled = true;
      break; // İşlemi tamamladık, döngüden çık
    } 
    else if (request.indexOf(endpointOff) != -1) {
      // İlgili LED'i kapat
      Serial.print("Komut algılandı: Oda ");
      Serial.print(i + 1);
      Serial.print(" ışığını KAPAT (GPIO ");
      Serial.print(ledPins[i]);
      Serial.println(")");
      
      digitalWrite(ledPins[i], LOW);
      lightStatus[i] = false;
      
      // Tüm LED'lerin güncel durumunu yazdır
      printLedStatus();
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nOK");
      client.stop();
      requestHandled = true;
      break; // İşlemi tamamladık, döngüden çık
    }
  }

  // Klima kontrol isteklerini işle
  if (!requestHandled && request.indexOf("/ac") != -1) {
    // Klima açma/kapama kontrolü
    if (request.indexOf("?status=on") != -1) {
      Serial.println("Klima açılıyor...");
      acStatus = true;
      
      // Ham veri (raw data) kullanarak klima açma komutu gönder
      sendRawIRSignal(KlimaKodlari::RAW_ACMA, 199);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"AC turned ON using raw IR data\"}");
      client.stop();
      requestHandled = true;
    }
    else if (request.indexOf("?status=off") != -1) {
      Serial.println("Klima kapatılıyor...");
      acStatus = false;
      
      // Ham veri (raw data) kullanarak klima kapama komutu gönder
      sendRawIRSignal(KlimaKodlari::RAW_KAPAMA, 199);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"AC turned OFF using raw IR data\"}");
      client.stop();
      requestHandled = true;
    }
    // Klima sıcaklığı ayarlama
    else if (request.indexOf("?temp=") != -1) {
      int tempIndex = request.indexOf("?temp=") + 6;
      String tempStr = request.substring(tempIndex, tempIndex + 2);
      int temp = tempStr.toInt();
      
      if (temp >= 17 && temp <= 30) {
        acTemp = temp;
        Serial.print("Klima sıcaklığı ayarlandı: ");
        Serial.println(temp);
        
        // Ham veri kullanarak sıcaklık değeri gönder
        switch (temp) {
          case 17:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_17, 199);
            break;
          case 18:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_18, 199);
            break;
          case 19:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_19, 199);
            break;
          case 20:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_20, 199);
            break;
          case 21:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_21, 199);
            break;
          case 22:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_22, 199);
            break;
          case 23:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_23, 199);
            break;
          case 24:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_24, 199);
            break;
          case 25:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_25, 199);
            break;
          case 26:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_26, 199);
            break;
          case 27:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_27, 199);
            break;
          case 28:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_28, 199);
            break;
          case 29:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_29, 199);
            break;
          case 30:
            sendRawIRSignal(KlimaKodlari::RAW_SICAKLIK_30, 199);
            break;
        }
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC temperature set to " + String(temp) + "\"}");
        client.stop();
        requestHandled = true;
      }
    }
    // Klima fan kontrol istekleri
    else if (request.indexOf("?fan=") != -1) {
      if (request.indexOf("?fan=low") != -1) {
        Serial.println("Klima fan hızı: Düşük");
        acFanSpeed = "low";
        
        // Ham veri kullanarak fan hızı gönder
        sendRawIRSignal(KlimaKodlari::RAW_DUSUK_FAN, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC fan speed set to LOW\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?fan=medium") != -1) {
        Serial.println("Klima fan hızı: Orta");
        acFanSpeed = "medium";
        
        // Ham veri kullanarak fan hızı gönder
        sendRawIRSignal(KlimaKodlari::RAW_ORTA_FAN, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC fan speed set to MEDIUM\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?fan=high") != -1) {
        Serial.println("Klima fan hızı: Yüksek");
        acFanSpeed = "high";
        
        // Ham veri kullanarak fan hızı gönder
        sendRawIRSignal(KlimaKodlari::RAW_YUKSEK_FAN, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC fan speed set to HIGH\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?fan=auto") != -1) {
        Serial.println("Klima fan hızı: Otomatik");
        acFanSpeed = "auto";
        
        // Ham veri kullanarak fan hızı gönder
        sendRawIRSignal(KlimaKodlari::RAW_OTOMATIK_FAN, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC fan speed set to AUTO\"}");
        client.stop();
        requestHandled = true;
      }
    }
    // Klima mod kontrol istekleri
    else if (request.indexOf("?mode=") != -1) {
      if (request.indexOf("?mode=cool") != -1) {
        Serial.println("Klima modu: Soğutma");
        acMode = "cool";
        
        // Ham veri kullanarak mod gönder
        sendRawIRSignal(KlimaKodlari::RAW_SOGUTMA, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC mode set to COOL\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?mode=heat") != -1) {
        Serial.println("Klima modu: Isıtma");
        acMode = "heat";
        
        // Ham veri kullanarak mod gönder
        sendRawIRSignal(KlimaKodlari::RAW_ISITMA, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC mode set to HEAT\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?mode=dry") != -1) {
        Serial.println("Klima modu: Nem Alma");
        acMode = "dry";
        
        // Ham veri kullanarak mod gönder
        sendRawIRSignal(KlimaKodlari::RAW_NEM_ALMA, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC mode set to DRY\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?mode=fan") != -1) {
        Serial.println("Klima modu: Fan");
        acMode = "fan";
        
        // Ham veri kullanarak mod gönder
        sendRawIRSignal(KlimaKodlari::RAW_FAN, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC mode set to FAN\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?mode=auto") != -1) {
        Serial.println("Klima modu: Otomatik");
        acMode = "auto";
        
        // Ham veri kullanarak mod gönder
        sendRawIRSignal(KlimaKodlari::RAW_OTOMATIK, 199);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"AC mode set to AUTO\"}");
        client.stop();
        requestHandled = true;
      }
    }
  }

  // IR kontrollü LED ışık kontrolü
  if (!requestHandled && request.indexOf("/irled") != -1) {
    // LED Açma/Kapama kontrolü
    if (request.indexOf("?status=on") != -1) {
      Serial.println("IR LED ışığı açılıyor...");
      irLedStatus = true;
      
      // Sadece ham veriyi kullan - daha güvenilir
      Serial.println("Ham veri kullanılıyor...");
      IrSender.sendRaw(LEDKodlari::RAW_ACMA, sizeof(LEDKodlari::RAW_ACMA)/sizeof(LEDKodlari::RAW_ACMA[0]), IR_FREQUENCY);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"IR LED turned ON successfully\"}");
      client.stop();
      requestHandled = true;
    }
    else if (request.indexOf("?status=off") != -1) {
      Serial.println("IR LED ışığı kapatılıyor...");
      irLedStatus = false;
      
      // Sadece ham veriyi kullan - daha güvenilir
      Serial.println("Ham veri kullanılıyor...");
      IrSender.sendRaw(LEDKodlari::RAW_KAPAMA, sizeof(LEDKodlari::RAW_KAPAMA)/sizeof(LEDKodlari::RAW_KAPAMA[0]), IR_FREQUENCY);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"IR LED turned OFF successfully\"}");
      client.stop();
      requestHandled = true;
    }
    // LED renk kontrolü
    else if (request.indexOf("?color=") != -1) {
      String colorStr = "";
      unsigned long colorCode = 0;
      const uint16_t* rawColorData = nullptr;
      int rawSize = 0;
      
      if (request.indexOf("?color=red") != -1) {
        colorStr = "red";
        colorCode = LEDKodlari::KIRMIZI;
        rawColorData = LEDKodlari::RAW_KIRMIZI;
        rawSize = sizeof(LEDKodlari::RAW_KIRMIZI)/sizeof(LEDKodlari::RAW_KIRMIZI[0]);
      }
      else if (request.indexOf("?color=green") != -1) {
        colorStr = "green";
        colorCode = LEDKodlari::YESIL;
        rawColorData = LEDKodlari::RAW_YESIL;
        rawSize = sizeof(LEDKodlari::RAW_YESIL)/sizeof(LEDKodlari::RAW_YESIL[0]);
      }
      else if (request.indexOf("?color=blue") != -1) {
        colorStr = "blue";
        colorCode = LEDKodlari::MAVI;
        rawColorData = LEDKodlari::RAW_MAVI;
        rawSize = sizeof(LEDKodlari::RAW_MAVI)/sizeof(LEDKodlari::RAW_MAVI[0]);
      }
      else if (request.indexOf("?color=white") != -1) {
        colorStr = "white";
        colorCode = LEDKodlari::BEYAZ;
        rawColorData = LEDKodlari::RAW_BEYAZ;
        rawSize = sizeof(LEDKodlari::RAW_BEYAZ)/sizeof(LEDKodlari::RAW_BEYAZ[0]);
      }
      
      if (colorStr != "") {
        Serial.print("IR LED rengi değiştiriliyor: ");
        Serial.println(colorStr);
        
        // Ham veriyi kullan
        Serial.println("Ham veri kullanılıyor...");
        IrSender.sendRaw(rawColorData, rawSize, IR_FREQUENCY);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"IR LED color set to " + colorStr + " successfully\"}");
        client.stop();
        requestHandled = true;
      }
    }
    // LED efekt kontrolü
    else if (request.indexOf("?effect=") != -1) {
      String effectStr = "";
      unsigned long effectCode = 0;
      const uint16_t* rawEffectData = nullptr;
      int rawSize = 0;
      
      if (request.indexOf("?effect=flash") != -1) {
        effectStr = "flash";
        effectCode = LEDKodlari::FLASH;
        rawEffectData = LEDKodlari::RAW_FLASH;
        rawSize = sizeof(LEDKodlari::RAW_FLASH)/sizeof(LEDKodlari::RAW_FLASH[0]);
      }
      else if (request.indexOf("?effect=strobe") != -1) {
        effectStr = "strobe";
        effectCode = LEDKodlari::STROBE;
        rawEffectData = LEDKodlari::RAW_STROBE;
        rawSize = sizeof(LEDKodlari::RAW_STROBE)/sizeof(LEDKodlari::RAW_STROBE[0]);
      }
      else if (request.indexOf("?effect=fade") != -1) {
        effectStr = "fade";
        effectCode = LEDKodlari::FADE;
        rawEffectData = LEDKodlari::RAW_FADE;
        rawSize = sizeof(LEDKodlari::RAW_FADE)/sizeof(LEDKodlari::RAW_FADE[0]);
      }
      else if (request.indexOf("?effect=smooth") != -1) {
        effectStr = "smooth";
        effectCode = LEDKodlari::SMOOTH;
        rawEffectData = LEDKodlari::RAW_SMOOTH;
        rawSize = sizeof(LEDKodlari::RAW_SMOOTH)/sizeof(LEDKodlari::RAW_SMOOTH[0]);
      }
      
      if (effectStr != "") {
        Serial.print("IR LED efekti değiştiriliyor: ");
        Serial.println(effectStr);
        
        // Ham veriyi kullan
        Serial.println("Ham veri kullanılıyor...");
        IrSender.sendRaw(rawEffectData, rawSize, IR_FREQUENCY);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"IR LED effect set to " + effectStr + " successfully\"}");
        client.stop();
        requestHandled = true;
      }
    }
    // LED parlaklık kontrolü
    else if (request.indexOf("?brightness=") != -1) {
      if (request.indexOf("?brightness=up") != -1) {
        Serial.println("IR LED parlaklığı artırılıyor...");
        
        // Ham veriyi kullan
        Serial.println("Ham veri kullanılıyor...");
        IrSender.sendRaw(LEDKodlari::RAW_PARLAKLIK_ARTTIR, 
                         sizeof(LEDKodlari::RAW_PARLAKLIK_ARTTIR)/sizeof(LEDKodlari::RAW_PARLAKLIK_ARTTIR[0]), 
                         IR_FREQUENCY);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"IR LED brightness increased successfully\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?brightness=down") != -1) {
        Serial.println("IR LED parlaklığı azaltılıyor...");
        
        // Ham veriyi kullan
        Serial.println("Ham veri kullanılıyor...");
        IrSender.sendRaw(LEDKodlari::RAW_PARLAKLIK_AZALT, 
                         sizeof(LEDKodlari::RAW_PARLAKLIK_AZALT)/sizeof(LEDKodlari::RAW_PARLAKLIK_AZALT[0]), 
                         IR_FREQUENCY);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"IR LED brightness decreased successfully\"}");
        client.stop();
        requestHandled = true;
      }
    }
  }

  // Kumanda kontrol istekleri
  if (!requestHandled && request.indexOf("/remote") != -1) {
    // Kumanda açma/kapama
    if (request.indexOf("?power=toggle") != -1) {
      Serial.println("Kumanda güç düğmesi gönderiliyor...");
      sendIRSignal(KumandaKodlari::ON_OFF);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"Remote power button signal sent\"}");
      client.stop();
      requestHandled = true;
    }
    // Ses kontrolü
    else if (request.indexOf("?volume=up") != -1) {
      Serial.println("Ses arttırma gönderiliyor...");
      sendIRSignal(KumandaKodlari::SES_ARTTIR);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"Volume up signal sent\"}");
      client.stop();
      requestHandled = true;
    }
    else if (request.indexOf("?volume=down") != -1) {
      Serial.println("Ses azaltma gönderiliyor...");
      sendIRSignal(KumandaKodlari::SES_AZALT);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"Volume down signal sent\"}");
      client.stop();
      requestHandled = true;
    }
    else if (request.indexOf("?volume=mute") != -1) {
      Serial.println("Ses kapatma gönderiliyor...");
      sendIRSignal(KumandaKodlari::MUTE);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"Mute signal sent\"}");
      client.stop();
      requestHandled = true;
    }
    // Kanal kontrolü
    else if (request.indexOf("?channel=up") != -1) {
      Serial.println("Kanal arttırma gönderiliyor...");
      sendIRSignal(KumandaKodlari::KANAL_ARTTIR);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"Channel up signal sent\"}");
      client.stop();
      requestHandled = true;
    }
    else if (request.indexOf("?channel=down") != -1) {
      Serial.println("Kanal azaltma gönderiliyor...");
      sendIRSignal(KumandaKodlari::KANAL_AZALT);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"Channel down signal sent\"}");
      client.stop();
      requestHandled = true;
    }
    // Sayısal tuşlar
    else if (request.indexOf("?button=") != -1) {
      int buttonIndex = request.indexOf("?button=") + 8;
      String buttonStr = request.substring(buttonIndex, buttonIndex + 1);
      int button = buttonStr.toInt();
      
      if (button >= 0 && button <= 9) {
        Serial.print("Sayısal tuş gönderiliyor: ");
        Serial.println(button);
        
        unsigned long buttonCode;
        switch (button) {
          case 0: buttonCode = KumandaKodlari::BUTTON_0; break;
          case 1: buttonCode = KumandaKodlari::BUTTON_1; break;
          case 2: buttonCode = KumandaKodlari::BUTTON_2; break;
          case 3: buttonCode = KumandaKodlari::BUTTON_3; break;
          case 4: buttonCode = KumandaKodlari::BUTTON_4; break;
          case 5: buttonCode = KumandaKodlari::BUTTON_5; break;
          case 6: buttonCode = KumandaKodlari::BUTTON_6; break;
          case 7: buttonCode = KumandaKodlari::BUTTON_7; break;
          case 8: buttonCode = KumandaKodlari::BUTTON_8; break;
          case 9: buttonCode = KumandaKodlari::BUTTON_9; break;
        }
        
        sendIRSignal(buttonCode);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"Button " + String(button) + " signal sent\"}");
        client.stop();
        requestHandled = true;
      }
    }
    // Yön tuşları
    else if (request.indexOf("?direction=") != -1) {
      if (request.indexOf("?direction=up") != -1) {
        Serial.println("Yukarı tuşu gönderiliyor...");
        sendIRSignal(KumandaKodlari::YUKARI);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"Up button signal sent\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?direction=down") != -1) {
        Serial.println("Aşağı tuşu gönderiliyor...");
        sendIRSignal(KumandaKodlari::ASAGI);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"Down button signal sent\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?direction=left") != -1) {
        Serial.println("Sol tuşu gönderiliyor...");
        sendIRSignal(KumandaKodlari::SOL);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"Left button signal sent\"}");
        client.stop();
        requestHandled = true;
      }
      else if (request.indexOf("?direction=right") != -1) {
        Serial.println("Sağ tuşu gönderiliyor...");
        sendIRSignal(KumandaKodlari::SAG);
        
        client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
        client.print("{\"status\":\"success\",\"message\":\"Right button signal sent\"}");
        client.stop();
        requestHandled = true;
      }
    }
    // OK tuşu
    else if (request.indexOf("?button=ok") != -1) {
      Serial.println("OK tuşu gönderiliyor...");
      sendIRSignal(KumandaKodlari::OK);
      
      client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
      client.print("{\"status\":\"success\",\"message\":\"OK button signal sent\"}");
      client.stop();
      requestHandled = true;
    }
  }

  if (requestHandled) {
    return; // İstek işlendiyse fonksiyondan çık
  }

  // Cihaz durumu sorgulaması
  if (request.indexOf("GET /status") != -1) {
    String jsonStatus = "{\"temperature\": " + String(temp) + 
                       ", \"humidity\": " + String(hum) + 
                       ", \"ac\": {\"status\": \"" + String(acStatus ? "on" : "off") + 
                       "\", \"temperature\": " + String(acTemp) + 
                       ", \"mode\": \"" + acMode + 
                       "\", \"fanSpeed\": \"" + acFanSpeed + "\"}, " +
                       "\"irLed\": \"" + String(irLedStatus ? "on" : "off") + "\", " +
                       "\"roomLights\": [";
    
    for (int i = 0; i < 5; i++) {
      jsonStatus += "\"" + String(lightStatus[i] ? "on" : "off") + "\"";
      if (i < 4) jsonStatus += ", ";
    }
    
    jsonStatus += "]}";
    
    Serial.println("Cihaz durumu istendi");
    client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
    client.print(jsonStatus);
    client.stop();
    return;
  }

  // Sıcaklık ve nem verisi sorgulaması
  if (request.indexOf("GET / ") != -1 || request.indexOf("GET /") != -1) {
    String jsonResponse = "{\"temperature\": " + String(temp) + ", \"humidity\": " + String(hum) + "}";
    
    Serial.println("Sıcaklık ve nem verileri istendi");
    Serial.print("Sıcaklık: ");
    Serial.print(temp);
    Serial.print("°C, Nem: %");
    Serial.println(hum);
    
    client.print("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n");
    client.print(jsonResponse);
    client.stop();
    return;
  }

  // Geçersiz istek
  Serial.println("Geçersiz istek, 404 döndürülüyor");
  client.print("HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\n404 - Not Found");
  client.stop();
}

// LED durumlarını konsola yazdırmak için yardımcı fonksiyon
void printLedStatus() {
  Serial.println("Oda ışıklarının güncel durumu:");
  for (int i = 0; i < 5; i++) {
    Serial.print("Oda ");
    Serial.print(i + 1);
    Serial.print(" (GPIO ");
    Serial.print(ledPins[i]);
    Serial.print("): ");
    Serial.println(lightStatus[i] ? "AÇIK" : "KAPALI");
  }
}

void loop() {
  WiFiClient client = server.available();
  
  if (client) {
    handleRequest(client);
  }
}