# Google Play Console және App Store Connect: толтыруға дайын мәтіндер

Сілтемелер:
- Құпиялылық саясаты: https://ust.kz/privacy
- Аккаунтты жою: https://ust.kz/account-delete
- Қолдау: https://ust.kz, ustaztilegi@gmail.com, +7 (771) 234-55-99

Идентификаторлар:
- Android: `kz.ust.ust_mobile_app`
- iOS: `kz.ust.ustMobileApp`
- Нұсқа: `2.4.0 (1)`. Әр жаңа жүктеуде `pubspec.yaml`-дағы `+1` бір санға өсуі керек.

---

## Дүкендегі мәтіндер (екі дүкенге ортақ)

**Атауы** (Play ≤30, Apple ≤30 таңба):
`ust.kz – Ustaz tilegi`

**Қысқа сипаттама** (Play ≤80):
`Мұғалімдерге арналған 400 000+ сабақ жоспары, ҚМЖ, ТЖБ, БЖБ және презентация`

**Apple subtitle** (≤30):
`Мұғалімге дайын материалдар`

**Apple keywords** (≤100, үтірмен, бос орынсыз):
`ҚМЖ,сабақ жоспары,ТЖБ,БЖБ,мұғалім,ұстаз,презентация,КСП,әдістеме,білім`

**Толық сипаттама** (Play ≤4000, Apple ≤4000):

```
ust.kz — «Ustaz tilegi» Республикалық ғылыми-әдістемелік орталығының мұғалімдерге арналған ресми қосымшасы.

400 000-нан астам дайын оқу-әдістемелік материал бір жерде:
• қысқа мерзімді жоспарлар (ҚМЖ, КСП);
• ТЖБ, БЖБ тапсырмалары;
• презентациялар, тәрбие сағаттары, ашық сабақтар;
• барлық пәндер мен сыныптар бойынша.

Мүмкіндіктер:
• Жылдам іздеу — тақырып, пән немесе сынып бойынша.
• Сүзгілер — пән, бағыт, сынып.
• Материалды жүктемей тұрып алдын ала қарау.
• Ұнаған материалдарды сақтау және жүктелгендер тізімі.
• ust.kz сайтымен ортақ аккаунт: сайттағы тарифіңіз бен материалдарыңыз қосымшада да қолжетімді.

Материалдарды жүктеу үшін тариф қажет: 1 күндік, айлық немесе жылдық.

Сұрақтарыңыз болса: ustaztilegi@gmail.com немесе WhatsApp +7 (771) 234-55-99.
```

**Санат:** Education (Білім беру).

---

## Google Play Console

### App content → Privacy policy
https://ust.kz/privacy

### App content → App access
«All or some functionality is restricted» таңдаңыз да, тест аккаунт беріңіз:
- Username: `+7 (___) ___-__-__` (тест аккаунттың телефоны)
- Password: `____`
- Нұсқаулық: «Кабинет қойындысы → Кіру. Аккаунтта белсенді тариф бар,
  материалды ашып "Жүктеу" басуға болады.»

Тест аккаунтта **белсенді тариф болсын**. Оны тексерушіге арналып ашылған
бөлек аккаунт етіңіз: тексеруші оны жойып жіберуі мүмкін.

### App content → Ads
**No**, қосымшада жарнама жоқ.

### App content → Content rating
- Санат: Reference, News, or Educational.
- Зорлық, қорқыныш, жыныстық контент, есірткі, құмар ойын: **жоқ**.
- Пайдаланушылар бір-бірімен сөйлесе ме: **жоқ**.
- Пайдаланушы контент жариялай ма: **жоқ** (материалдарды сайт жариялайды).
- Сатып алу бар ма: **иә** (тариф).

### App content → Target audience and content
- Жас: **18 және одан жоғары**.
- Балаларға арналған ба: **жоқ**.

### App content → Data safety
- Деректер жинала ма: **Иә**.
- Шифрланып беріле ме: **Иә** (HTTPS).
- Пайдаланушы жоюды сұрай ала ма: **Иә**, сілтемесі https://ust.kz/account-delete.

| Деректер түрі | Жинала ма | Бөлісе ме | Міндетті ме | Мақсаты |
|---|---|---|---|---|
| Personal info → Name | Иә | Жоқ | Иә | App functionality, Account management |
| Personal info → Phone number | Иә | Жоқ | Иә | App functionality, Account management |
| Personal info → User IDs | Иә | Жоқ | Иә | Account management |
| Photos and videos → Photos | Иә | Жоқ | Жоқ (профиль суреті) | App functionality |
| Financial info → Purchase history | Иә | Жоқ | Иә | App functionality |
| App activity → Other actions (жүктеу, сақтау, бағалау) | Иә | Жоқ | Иә | App functionality |
| App activity → App interactions | Жоқ | | | |
| Location, Contacts, Messages, Audio, Health | Жоқ | | | |
| Device or other IDs | Жоқ | | | |

Kaspi арқылы төлемде карта деректерін біз алмаймыз, сондықтан
«Financial info → Payment info» белгіленбейді.

### App content → Financial features
Жоқ.

### Store listing → Графика
- **App icon:** 512×512. `assets/app_icon.png` (1024) файлын 512-ге кішірейтіңіз.
- **Feature graphic:** 1024×500, файлы `docs/store/feature_graphic.png`.
- **Phone screenshots:** 2–8 дана, файлдары `docs/store/screenshots/`.

### Testing → Closed testing
1. Track жасау, `app-release.aab` жүктеу.
2. Тестерлер тізімі: кемінде 12 Gmail.
3. Тестерлер opt-in сілтемесі арқылы қосылып, қосымшаны **14 күн қатарынан**
   орнатулы ұстайды.
4. 14 күннен кейін Dashboard → «Apply for production».

Release файлы:

```
flutter build appbundle --release
build/app/outputs/bundle/release/app-release.aab
```

Қол қою кілті: `android/upload-keystore.jks` (git-ке кірмейді).
Құпия сөзі `android/key.properties` ішінде.

---

## App Store Connect

### App Information
- Name: `ust.kz – Ustaz tilegi`
- Subtitle: `Мұғалімге дайын материалдар`
- Category: Education
- Content Rights: қосымшада үшінші тараптың контенті бар. Материалдарды
  авторлар ust.kz-ке жариялайды, оларды көрсетуге құқық бар.
- Age Rating: анкетада бәріне «None» → **4+**.

### App Privacy
- Privacy Policy URL: https://ust.kz/privacy
- Data Collection: **Yes**. Төмендегі деректердің бәрі
  «Linked to the user: Yes», «Used for tracking: No».

| Санат | Түрі | Мақсаты |
|---|---|---|
| Contact Info | Name, Phone Number | App Functionality |
| User Content | Photos (профиль суреті) | App Functionality |
| Identifiers | User ID | App Functionality |
| Purchases | Purchase History | App Functionality |
| Usage Data | Product Interaction (жүктеу, сақтау) | App Functionality |

### App Review Information
- **Sign-in required: Yes.** Тест аккаунттың телефоны мен құпия сөзі
  (белсенді тарифімен).
- **Notes:** «Аккаунтты жою: Кабинет → Өңдеу → Кабинетті жою. Қолдау: ustaztilegi@gmail.com.»
- **Contact:** аты-жөні, телефон, email.

### Version
- Support URL: https://ust.kz
- Marketing URL: https://ust.kz
- Screenshots: iPhone 6.9" (1320×2868) немесе 6.7" (1290×2796).
  Оларды Mac-тағы iOS Simulator-дан түсіру керек. Android скриншоттары жарамайды.
- Build: Mac-та `flutter build ipa`, содан кейін Xcode → Organizer немесе Transporter
  арқылы жүктеу.

### Apple-ге керегі
- Apple Developer Program (жылына $99), ұйым атынан болса — D-U-N-S нөмірі.
- Mac, Xcode, Bundle ID: `kz.ust.ustMobileApp`.
- Export Compliance: `Info.plist`-те `ITSAppUsesNonExemptEncryption = false`
  қойылған, сұрақ шықпайды.
