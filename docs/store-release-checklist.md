# App Store және Google Play: дайындық

Тексерілген талаптар:
- Apple App Store Review Guidelines;
- App Store Connect-ке жіберу тәртібі;
- Google Play Developer Policy;
- Google Play-ге шығаруға дайындық.

## Қосымшада жасалғаны (2026-10-28)

| # | Талап | Не өзгертілді | Файл |
|---|---|---|---|
| 1 | Apple 2.3.8 / брендинг. Flutter-дің стандарт иконкасымен қабылдамайды | Ақ фондағы U логотипі бар иконка салынды: iOS, Android, Android adaptive | `assets/app_icon*.png`, `pubspec.yaml` (`flutter_launcher_icons`) |
| 2 | Apple 5.1.1 / Google User Data. Құпиялылық саясатына сілтеме қосымшаның ішінде болуы керек | Кабинеттің төменгі жағына «Құпиялылық саясаты» сілтемесі қосылды. Тарифтегі «Қолдану ережелерімен» жазуы енді басылады | `lib/core/config.dart`, `profile_screen.dart`, `subscription_screen.dart`, `detail_sheets.dart` |
| 3 | Саясат мәтіні | Қазақша жоба жазылды | `docs/privacy-policy.md` |
| 4 | Apple 2.1 (толық жұмыс істеу). Жұмыс істемейтін функция болмауы керек | «Хабарландырулар» ажыратқышы жасырылды (push әлі жоқ). «Жазылымды тоқтату» мен «Офлайн сақтау» бұрын жасырылған | `profile_screen.dart` |
| 5 | Apple 2.3 (дұрыс сипаттама) | Көмек бетіндегі «интернетсіз ашылады» деген шындыққа сай емес жауап түзетілді | `help_screen.dart` |
| 6 | Apple 5.1.1. Рұқсаттың себебі жазылуы керек, әйтпесе iOS-та құлайды | `NSPhotoLibraryUsageDescription` қосылды (профиль суреті) | `ios/Runner/Info.plist` |
| 7 | App Store Connect: экспортқа шифрлау | `ITSAppUsesNonExemptEncryption = false` (тек HTTPS) | `ios/Runner/Info.plist` |
| 8 | iOS-тағы атау | `CFBundleName` енді `ust.kz` | `ios/Runner/Info.plist` |
| 9 | Google Play: қауіпсіз байланыс | HTTP (cleartext) тек debug нұсқада, release-те тек HTTPS | `android/app/src/main/AndroidManifest.xml`, `.../debug/AndroidManifest.xml` |
| 10 | Google Play: Photo & Video Permissions саясаты | Плагин қосатын `READ_MEDIA_IMAGES/VIDEO/AUDIO` және `READ_EXTERNAL_STORAGE` рұқсаттары алынды. Release тек `INTERNET` сұрайды | `android/app/src/main/AndroidManifest.xml` |
| 11 | Google Play: release қолтаңбасы | Release `android/key.properties`-тегі кілтпен қол қойылады. Файл git-ке кірмейді | `android/app/build.gradle.kts` |
| 12 | Google Play: target API | `targetSdk 36`, `minSdk 24` (Flutter 3.47, талаптан жоғары) | тексерілді |
| 13 | Apple 5.1.1(v), Google: аккаунтты қосымша ішінде жою | Экраны дайын. Backend endpoint-і локальды жазылған, деплой керек | `delete_account_screen.dart`, `docs/backend-profile-prompt.md` |

Release жинағы тексерілді: `flutter build appbundle --release` сәтті өтті.

## Әлі жасау керек (код емес)

### Backend / сайт (`docs/backend-profile-prompt.md`)
- **Деплой.** `POST /api/mobile/account/delete` және `/mobile/profile/password`
  production-ға шығып, `route:cache` жасалуы керек. Әйтпесе тексеруші аккаунтты
  жоя алмайды, ал бұл бас тартудың ең жиі себебі.
- **`https://ust.kz/privacy` және `https://ust.kz/account-delete`.**
  Бұл сайттың фронтендіндегі беттер, промоты: `docs/frontend-site-prompt.md`.
  Саясатты жарияламас бұрын заңгер тексеруі керек.
  Аккаунтты жою бетінің сілтемесін Google Play-дегі Data safety формасы сұрайды.

### Android кілті (бір рет)
```
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
`android/key.properties`:
```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:\\Users\\...\\upload-keystore.jks
```
Кілт пен құпия сөзді жоғалтпаңыз. Онсыз қосымшаны жаңарту қиындайды.
Play App Signing қосылған болса, кілтті Google арқылы ауыстыруға болады.

### Google Play Console
- **Жабық тестілеу.** 2023 жылдың қарашасынан кейін ашылған жеке аккаунттарда
  production-ға шығар алдында кемінде **12 тестер 14 күн қатарынан** тестілеуі керек.
- **Анкеталар:**
  - Data safety: жиналатын деректер `privacy-policy.md`-нің 2-бөлімінде;
  - Content rating;
  - Target audience: 18+, мұғалімдер;
  - Ads: жоқ.
- **Тексерушіге аккаунт.** App access бөліміне тест аккаунт (телефон + құпия сөз)
  беріңіз. Тест аккаунтта белсенді тариф болғаны дұрыс.

### App Store Connect
- **Құрылғы мен аккаунт.** Mac және Xcode керек: `flutter build ipa`.
  Apple Developer аккаунты және `kz.ust.ustMobileApp` bundle ID керек.
- **Анкеталар және сілтемелер:**
  - App Privacy (тамақ затбелгісі сияқты): `privacy-policy.md` бойынша толтыру;
  - Privacy Policy URL және Support URL.
- **Тексерушіге:** App Review Information бөліміне тест аккаунт.

## Ашық тәуекел: төлем

Тарифтер мен балансты толтыру **Kaspi** арқылы өтеді (иесінің шешімі бойынша
сол күйі қалдырылды).

- **Apple 3.1.1:** цифрлық контентке жазылым қосымшаның ішінде сатылса, тек
  In-App Purchase арқылы болуы керек.
- **Google Play Payments:** тек Google Play Billing арқылы болуы керек.

Қазіргі түрінде бас тарту ықтималдығы жоғары. Қабылданбаса, екі жол бар:
1. Дүкен нұсқасында сатып алуды жасыру. Жазылымы барлар бәрін қолдана береді,
   ал сатып алу тек сайтта болады, қосымшада оған сілтеме берілмейді.
2. Apple IAP және Google Play Billing қосу (backend-те чек тексеру керек).

## Ескерту

- **Хабарландыру (push):** әлі жоқ. Жасау үшін Firebase Cloud Messaging және
  backend-тен жіберу керек.
- **Офлайн режим:** толық емес. Файл телефонда сақталады, бірақ «Жүктелгендер»
  тізімі интернетсіз ашылмайды.
