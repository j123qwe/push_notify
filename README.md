Push Notifications
==================

## apns.sh

#### Requirements

* Bundled certificates for VoLTE & VoWiFi, named **volte.pem** & **vowifi.pem** respectively.
* A properly configured **.variables** file defining the respective Bundle ID/Toptic for VoLTE & VoWiFi.

#### Notes

* Token can be Base64 or HEX.
* Examples are **9XaWP5hwQ2nMwTEVvTuvTG9bum7t/PiphrOjdqfwot8=** for Base64 and **F576963F98704369CCC13115BC5BA44C6F5BBA6EEDFCF8A986B3A376A7F0A2DF** for HEX.

#### Usage

```
./apns <TOKEN> <VoLTE|VoWiFi>
```
